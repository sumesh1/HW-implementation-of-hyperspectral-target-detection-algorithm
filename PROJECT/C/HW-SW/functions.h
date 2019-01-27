#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xsdps.h"
#include "ff.h"
#include "det_parameters.h"
#include "xaxidma.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "xdebug.h"
#include "xtmrctr.h"

#ifdef XPAR_INTC_0_DEVICE_ID
 #include "xintc.h"
#else
 #include "xscugic.h"
#endif

/*
 * Device hardware build related constants.
 */

#define DMA_DEV_ID		XPAR_AXIDMA_0_DEVICE_ID

#ifdef XPAR_AXI_7SDDR_0_S_AXI_BASEADDR
#define DDR_BASE_ADDR		XPAR_AXI_7SDDR_0_S_AXI_BASEADDR
#elif XPAR_MIG7SERIES_0_BASEADDR
#define DDR_BASE_ADDR	XPAR_MIG7SERIES_0_BASEADDR
#elif XPAR_MIG_0_BASEADDR
#define DDR_BASE_ADDR	XPAR_MIG_0_BASEADDR
#elif XPAR_PSU_DDR_0_S_AXI_BASEADDR
#define DDR_BASE_ADDR	XPAR_PSU_DDR_0_S_AXI_BASEADDR
#endif

#ifndef DDR_BASE_ADDR
#warning CHECK FOR THE VALID DDR ADDRESS IN XPARAMETERS.H, \
		DEFAULT SET TO 0x01000000
#define MEM_BASE_ADDR		0x01000000
#else
#define MEM_BASE_ADDR		(DDR_BASE_ADDR + 0x1000000)
#endif

#ifdef XPAR_INTC_0_DEVICE_ID
#define RX_INTR_ID		XPAR_INTC_0_AXIDMA_0_S2MM_INTROUT_VEC_ID
#define TX_INTR_ID		XPAR_INTC_0_AXIDMA_0_MM2S_INTROUT_VEC_ID
#else
#define RX_INTR_ID		XPAR_FABRIC_AXIDMA_0_S2MM_INTROUT_VEC_ID
#define TX_INTR_ID		XPAR_FABRIC_AXIDMA_0_MM2S_INTROUT_VEC_ID
#endif

#define TX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00100000)
#define RX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00300000)
#define RX_BUFFER_HIGH		(MEM_BASE_ADDR + 0x004FFFFF)

#ifdef XPAR_INTC_0_DEVICE_ID
#define INTC_DEVICE_ID          XPAR_INTC_0_DEVICE_ID
#else
#define INTC_DEVICE_ID          XPAR_SCUGIC_SINGLE_DEVICE_ID
#endif

#ifdef XPAR_INTC_0_DEVICE_ID
 #define INTC		XIntc
 #define INTC_HANDLER	XIntc_InterruptHandler
#else
 #define INTC		XScuGic
 #define INTC_HANDLER	XScuGic_InterruptHandler
#endif


/* Timeout loop counter for reset
 */
#define RESET_TIMEOUT_COUNTER	10000





extern FIL fil;		/* File object */
extern FATFS fatfs;
extern char HyperMatrixFile[32];
extern char ResultsFile[32];
extern char TargetFile[32];
extern char *SD_File;
extern u32 Platform;


extern datatype HyperData[N_pixels * N_bands] ; //__attribute__ ((aligned(32)));
//extern datatype HyperDataNoMean[N_pixels*N_bands]={};
extern double R [N_bands][N_bands] ;
extern  int P[N_bands];
extern double B[N_bands][N_bands] ;
extern double X[N_bands] ;
extern double Y[N_bands] ;
extern double sR[N_bands];
extern double xR[N_bands] ;
extern double result[N_pixels] ;
extern datatype target[N_bands];
extern s32 R32[N_bands][N_bands];
extern s32 sR32[N_bands];
extern volatile u32 *BRAM_BASE_ADDR;
extern s32 receiver [N_pixels];
extern XAxiDma AxiDma;		/* Instance of the XAxiDma */
extern INTC Intc;	/* Instance of the Interrupt Controller */
extern volatile int TxDone;
extern volatile int RxDone;
extern volatile int Error;
extern XTmrCtr TimerCounter;



int adaptive_cosine_estimator ();
int constrained_energy_minimization ();
int spectral_angle_mapper ();



#ifndef DEBUG
extern void xil_printf(const char *format, ...);
#endif

#ifdef XPAR_UARTNS550_0_BASEADDR
static void Uart550_Setup(void);
#endif

int ReceiveData(s32* array, int Length);
void TxIntrHandler(void *Callback);
void RxIntrHandler(void *Callback);
int main_DMA(datatype* array,s32* receiver, int MAX_PKT_LEN, int NUMBER_OF_TRANSFERS);
int setup_DMA(void);

int SetupIntrSystem(INTC * IntcInstancePtr,
			   XAxiDma * AxiDmaPtr, u16 TxIntrId, u16 RxIntrId);
void DisableIntrSystem(INTC * IntcInstancePtr,
					u16 TxIntrId, u16 RxIntrId);

int init_timer ( u16 DeviceId , u8 TmrCtrNumber );
u32 start_timer (u8 TmrCtrNumber );
u32 stop_timer (u8 TmrCtrNumber );

double scalarProduct (double*, datatype*, int);
double scalarProduct2 (datatype* a, datatype* b, int N);
int FfsSd(char*, datatype * );
int FfsSdWrite (char*, s32 *);
int read_data(char*, datatype * );
int write_data(char*, s32 *);
//void matrixMult(s16*,s16*,s16*);
//void removeMean(s16*,s32*,int,int);
void hyperCorr (datatype *, double (*)[], int, int, int);
int LUPdecompose(int, double (*)[], int *);
int LUPinverse(int size, int P[size], double LU[size][size], double [size][size], double [size], double [size]);
void arrayMatrixProduct(int, datatype *, double [][N_bands], double *);
void GaussJordan (int size, double R[size][size], double B[size][size]);
int ACE(double);
int CEM(double sRs);
double SAM (datatype *x, datatype *s, double target_product, int N);
