#include "functions.h"
#include "det_parameters.h"
#include <stdio.h>
#include "xsdps.h"
#include "ff.h"
#include "xaxidma.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "xdebug.h"
#include "xtmrctr.h"

FIL fil;		/* File object */
FATFS fatfs;
char HyperMatrixFile[32] = image_file_name;
char ResultsFile[32] = results_file_name;
char TargetFile[32] = target_file_name;
char *SD_File;
u32 Platform;


datatype HyperData[N_pixels * N_bands] ; //__attribute__ ((aligned(32)));
//datatype HyperDataNoMean[N_pixels*N_bands]={};
double R [N_bands][N_bands] = {};
int P[N_bands];
double B[N_bands][N_bands] = {};
double X[N_bands] = {};
double Y[N_bands] = {};
double sR[N_bands] = {};
double xR[N_bands] = {};
double result[N_pixels] = {};
datatype target[N_bands] = {};
volatile u32 *BRAM_BASE_ADDR = XPAR_BRAM_WRAPPER_0_BASEADDR;
s32 R32[N_bands][N_bands] = {};
s32 sR32[N_bands] = {};
s32 receiver [N_pixels] = {};
XAxiDma AxiDma;		/* Instance of the XAxiDma */
INTC Intc;	/* Instance of the Interrupt Controller */
volatile int TxDone;
volatile int RxDone;
volatile int Error;
XTmrCtr TimerCounter;


/*****************************************************************************/

int adaptive_cosine_estimator (){

	int detected = 0;

	//Calculate Correlation Matrix R
#ifdef DEBUG
	printf("Started calculating R...\n");
#endif

	hyperCorr (HyperData, R,  N_bands, N_pixels, corr_percent);

#ifdef DEBUG
	printf("%f %f %f \n", R[0][0], R[0][1], R[0][2]);
#endif

	//Calculate LU decomposition
	if(LUPdecompose(N_bands, R, P) < 0) return -1;

#ifdef DEBUG
	printf("The LUP decomposition of 'R' is successful.\n");
#endif

	//Calculate LU inversion
	if(LUPinverse(N_bands, P, R, B, X, Y) < 0) return -1;

#ifdef DEBUG
	printf("Matrix inversion successful.\n");
#endif

	//LU Decomposition or GaussJordan
	//GaussJordan(N_bands,R, B);
	// R=	B;

	//Prepare s'*R^-1
	arrayMatrixProduct(N_bands, target, R, sR);

	//Prepare sR*s
	double sRs = scalarProduct(sR, target, N_bands);
	//double temp1,temp2;

#ifdef DEBUG
	printf("Start calculating ACE...\n");
#endif

	//CALCULATE ACE for all pixels
	detected = ACE(sRs);

	return detected;

}

/*****************************************************************************/

int constrained_energy_minimization (){

	int detected = 0;

	//Calculate Correlation Matrix R
#ifdef DEBUG
	printf("Started calculating R...\n");
#endif

	hyperCorr (HyperData, R,  N_bands, N_pixels, corr_percent);

#ifdef DEBUG
	printf("%f %f %f \n", R[0][0], R[0][1], R[0][2]);
#endif

	//Calculate LU decomposition
	if(LUPdecompose(N_bands, R, P) < 0) return -1;

#ifdef DEBUG
	printf("The LUP decomposition of 'R' is successful.\n");
#endif

	//Calculate LU inversion
	if(LUPinverse(N_bands, P, R, B, X, Y) < 0) return -1;

#ifdef DEBUG
	printf("Matrix inversion successful.\n");
#endif

	//LU Decomposition or GaussJordan
	//GaussJordan(N_bands,R, B);
	// R=	B;

	//Prepare s'*R^-1
	arrayMatrixProduct(N_bands, target, R, sR);

	//Prepare sR*s
	double sRs = scalarProduct(sR, target, N_bands);
	//double temp1,temp2;

#ifdef DEBUG
	printf("Start calculating CEM...\n");
#endif

	//CALCULATE ACE for all pixels
	detected = CEM(sRs);

	return detected;

}

/*****************************************************************************/

int spectral_angle_mapper (){

	int detected = 0;
	double value;

#ifdef DEBUG
	printf("Start calculating SAM..\n");
#endif

	//prepare s'*s
	double target_product = scalarProduct2(target, target, N_bands);

	//CALCULATE SPECTRAL ANGLE FOR ALL PIXELS
	for(int i = 0; i < N_pixels; i++)
		{
			value = SAM(HyperData + i * N_bands, target, target_product, N_bands);
			result[i] = value;

#ifdef DEBUG
			if(value>threshold)
				detected=detected+1;
#endif
		}

	return detected;

}

/*****************************************************************************/

int ACE(double sRs)
{
	double temp1, temp2, value;
	int detected = 0;
	for(int i = 0; i < N_pixels; i++)
		{

			temp1 = scalarProduct(sR, HyperData + i * N_bands, N_bands);
			temp1 *= temp1;

			arrayMatrixProduct(N_bands, HyperData + i * N_bands, R, xR);
			temp2 = scalarProduct(xR, HyperData + i * N_bands, N_bands);
			temp2 *= sRs;

			//detection statistic
			value = temp1 / temp2;
			result[i] = value;
#ifdef DEBUG
			if(value>threshold)
				detected=detected+1;
#endif
		}

	return detected;
}




/*****************************************************************************/

int CEM(double sRs)
{
	double temp1, value;
	int detected = 0;
	for(int i = 0; i < N_pixels; i++)
		{

			temp1 = scalarProduct(sR, HyperData + i * N_bands, N_bands);

			//detection statistic
			value = temp1 / sRs;
			result[i] = value;

#ifdef DEBUG
			if(value>threshold)
				detected=detected+1;
#endif
		}

	return detected;
}

/*****************************************************************************/

double SAM (datatype *x, datatype *s, double target_product, int N)
{

	// double sx=(double)scalarProduct(s,x,N);
	//return (sx*sx)/((double)target_product*(double)scalarProduct(x,x,N));

	//NEW CODE DOWN, faster by 5%
	u64 xx = 0, sx = 0;
	int i;
	for (i = 0; i < N; i++)
		{
			sx = sx + x[i] * s[i];
			xx = xx + x[i] * x[i];
		}
	return (sx * sx) / ((double)(target_product) * (double)xx);
}

/*****************************************************************************/

//calculate correlation matrix RR
void hyperCorr (datatype *m, double (*R)[N_bands], int NB, int NP, int percent)
{
	int i, j, p, k = 0;
	int divisor = (int)(percent * NP / 100);
	int jump = (int)(100 / percent);

#ifdef DEBUG
	printf("The divisor is %d\n", divisor);
	printf("The jump is %d\n", jump);
#endif

	for(p = 0; p < NP; p = p + jump)
		{
			k = NB * p;
			for (i = 0; i < NB; i++)
				{
					for (j = 0; j < NB; j++)
						{
							R[i][j] = R[i][j] + ((double)m[k + i] * m[k + j] / divisor);
						}
				}
		}
}

/*****************************************************************************/

// SCALAR PRODUCT OF TWO VECTORS a AND b WITH LENGTH N
double scalarProduct (double* a, datatype* b, int N)
{
	int i;
	double sum = 0;
	for (i = 0; i < N; i++)
		{
			sum += (double)b[i] * a[i];
		}

	return sum;
}

/*****************************************************************************/

// SCALAR PRODUCT OF TWO VECTORS a AND b WITH LENGTH N
double scalarProduct2 (datatype* a, datatype* b, int N)
{
	int i;
	double sum = 0;
	for (i = 0; i < N; i++)
		{
			sum += (double)b[i] * a[i];
		}

	return sum;
}

/*****************************************************************************/

//Array-Matrix product; vector 1xp; matrix pxp => 1xp vector
void arrayMatrixProduct(int size, datatype *A, double R[][N_bands], double *result)
{
	int i, j;
	double sum;
	for (i = 0; i < size; i++)
		{
			sum = 0;
			for (j = 0; j < size; j++)
				{
					sum = sum + A[j] * R[i][j];
				}
			result[i] = sum;
		}

}

/*****************************************************************************/

//Remove mean from matrix M, new matrix is R
void removeMean(datatype* M, s32* R, int NB, int NP)
{
	s32 mean[N_bands] = {};
	int i, j, k = 0;
	for (j = 0; j < NB; j++)
		{
			k = j;
			for (i = 0; i < NP; i++)
				{
					mean[j] = mean[j] + M[k];
					k = k + NB;
				}
			mean[j] = mean[j] / NB;
		}

#ifdef DEBUG
	printf("Done calculating means! \n");
#endif

	for (j = 0; j < NP; j++)
		{
			for (i = 0; i < NB; i++)
				{
					R[i + j * NB] = M[i + j * NB] - mean[i];
				}
		}


}

/*****************************************************************************/

int read_data(char *File_Name, datatype * OutputArray)
{
	int Status;

#ifdef DEBUG
	xil_printf("Downloading image from SD card \r\n");
#endif

	Status = FfsSd(File_Name, OutputArray);
	if (Status != XST_SUCCESS)
		{
			xil_printf("Download failed \r\n");
			return XST_FAILURE;
		}

#ifdef DEBUG
	xil_printf("Successfully downloaded image file \r\n");
#endif

	return XST_SUCCESS;

}

/*****************************************************************************/

int write_data(char *File_Name, s32 * OutputArray)
{
	int Status;

#ifdef DEBUG
	xil_printf("Writing results to SD card \r\n");
#endif

	Status = FfsSdWrite(File_Name, OutputArray);
	if (Status != XST_SUCCESS)
		{
			xil_printf("Writing failed \r\n");
			return XST_FAILURE;
		}

#ifdef DEBUG
	xil_printf("Successfully written results file \r\n");
#endif

	return XST_SUCCESS;

}

/*****************************************************************************/

int FfsSd(char* File_Name, datatype* OutputArray)
{
	FRESULT Res;
	UINT NumBytesRead;
	//UINT NumBytesWritten;
	//u32 BuffCnt;

	//FILE SIZE HAS TO BE NUMBER OF BYTES
	u32 FileSize = N_bands * N_pixels * byte_in;
	/*
	 * To test logical drive 0, Path should be "0:/"
	 * For logical drive 1, Path should be "1:/"
	 */
	TCHAR *Path = "0:/";

	Platform = XGetPlatform_Info();
	if (Platform == XPLAT_ZYNQ_ULTRA_MP)
		{
			/*
			 * Since 8MB in Emulation Platform taking long time, reduced
			 * file size to 8KB.
			 */
			FileSize = N_bands * N_pixels * byte_in;
		}

	// Register volume work area, initialize device

	Res = f_mount(&fatfs, Path, 0);

	if (Res != FR_OK)
		{
		xil_printf("cannot mount \n");
			return XST_FAILURE;
		}

	SD_File = (char *)File_Name;

	Res = f_open(&fil, SD_File,  FA_READ);
	if (Res)
		{
		xil_printf("cannot open file \n");
			return XST_FAILURE;
		}

	/*
	 * Pointer to beginning of file .
	 */

	Res = f_lseek(&fil, 0);
	if (Res)
		{
		xil_printf("no file by that name \n");
			return XST_FAILURE;
		}

	/*
	 * Read data from file.
	 */
	Res = f_read(&fil, (void*)OutputArray, FileSize,
	             &NumBytesRead);
	if (Res)
		{
			return XST_FAILURE;
		}

	/*
	 * Data verification
	 */
#ifdef DEBUG
	xil_printf("number bytes read: %d \n", NumBytesRead);
#endif
	/*
	 * Close file.
	 */
	Res = f_close(&fil);
	if (Res)
		{
			return XST_FAILURE;
		}

	return XST_SUCCESS;
}

/*****************************************************************************/

int FfsSdWrite (char * File_Name, s32 * OutputArray)
{
	FRESULT Res;
	UINT NumBytesWritten;
	u32 FileSize = (N_pixels * byte_out);
	/*
	 * To test logical drive 0, Path should be "0:/"
	 * For logical drive 1, Path should be "1:/"
	 */
	TCHAR *Path = "0:/";

	Platform = XGetPlatform_Info();
	if (Platform == XPLAT_ZYNQ_ULTRA_MP)
		{
			/*
			 * Since 8MB in Emulation Platform taking long time, reduced
			 * file size to 8KB.
			 */
			FileSize = N_pixels * byte_out;
		}

	/*
	 * Register volume work area, initialize device
	 */
	Res = f_mount(&fatfs, Path, 0);

	if (Res != FR_OK)
		{
			return XST_FAILURE;
		}


	/*
	 * Open file with required permissions.
	 * Here - Creating new file with read/write permissions. .
	 * To open file with write permissions, file system should not
	 * be in Read Only mode.
	 */
	SD_File = (char *)File_Name;

	Res = f_open(&fil, SD_File, FA_CREATE_ALWAYS | FA_WRITE | FA_READ);
	if (Res)
		{
			return XST_FAILURE;
		}

	/*
	 * Pointer to beginning of file .
	 */
	Res = f_lseek(&fil, 0);
	if (Res)
		{
			return XST_FAILURE;
		}

	/*
	 * Write data to file.
	 */
	Res = f_write(&fil, (const void*)OutputArray, FileSize,
	              &NumBytesWritten);
	if (Res)
		{
			return XST_FAILURE;
		}

	/*
	 * Close file.
	 */
	Res = f_close(&fil);
	if (Res)
		{
			return XST_FAILURE;
		}

	return XST_SUCCESS;
}

/*****************************************************************************/
//inspired by http://chandraacads.blogspot.com/2015/12/c-program-for-matrix-inversion.html
//Decomposition of matrix A into L, U, P, using partial pivoting decomposition.s
//Decomposed L, U is stored in A. Diagonal of L is not stored (it is all 1)
int LUPdecompose(int size, double A[size][size], int P[size])
{
	int i, j, k, kd = 0, T;
	double p, t;

	/* Initializing permutation array */
	for(i = 0; i < size; i++) P[i] = i;

	for(k = 0; k < size - 1; k++)
		{
			p = 0;
			for(i = k; i < size; i++)
				{
					t = A[i][k];
					if(t < 0) t *= -1; //Abosolute value of 't'.
					if(t > p)
						{
							p = t;
							kd = i;
						}
				}

			if(p == 0)
				{
					printf("\nLUPdecompose(): ERROR: A singular matrix is supplied.\n"\
					       "\tAborted.\n");
					return -1;
				}

			/* Exchanging the rows according to the permutation determined above. */
			T = P[kd];
			P[kd] = P[k];
			P[k] = T;
			for(i = 0; i < size; i++)
				{
					t = A[kd][i];
					A[kd][i] = A[k][i];
					A[k][i] = t;
				}

			for(i = k + 1; i < size; i++) //Performing subtraction to decompose A as LU.
				{
					A[i][k] = A[i][k] / A[k][k];
					for(j = k + 1; j < size; j++) A[i][j] -= A[i][k] * A[k][j];
				}
		}

//Now, A contains the L (without diagonal) and U.

	return 0;
}


/*****************************************************************************/

/* This function calculates the inverse of the LUP decomposed matrix 'LU' and pivoting
 * information stored in 'P'. The inverse is returned through the matrix 'LU' itself.
 * 'B', X', and 'Y' are used as temporary spaces. */
int LUPinverse(int size, int P[size], double LU[size][size], double B[size][size], double X[size], double Y[size])
{
	int i, j, n, m;
	double t;

	//Initializing X and Y.
	for(n = 0; n < size; n++) X[n] = Y[n] = 0;

	/* Solving LUX = Pe, in order to calculate the inverse of 'A'. Here, 'e' is a column
	 * vector of the identity matrix of size 'size-1'. Solving for all 'e'. */
	for(i = 0; i < size; i++)
		{
			//Storing elements of the i-th column of the identity matrix in i-th row of 'B'.
			for(j = 0; j < size; j++) B[i][j] = 0;
			B[i][i] = 1;

			//Solving Ly = Pb.
			for(n = 0; n < size; n++)
				{
					t = 0;
					for(m = 0; m <= n - 1; m++) t += LU[n][m] * Y[m];
					Y[n] = B[i][P[n]] - t;
				}

			//Solving Ux = y.
			for(n = size - 1; n >= 0; n--)
				{
					t = 0;
					for(m = n + 1; m < size; m++) t += LU[n][m] * X[m];
					X[n] = (Y[n] - t) / LU[n][n];
				}//Now, X contains the solution.

			for(j = 0; j < size; j++) B[i][j] = X[j]; //Copying 'X' into the same row of 'B'.
		} //Now, 'B' the transpose of the inverse of 'A'.

	/* Copying transpose of 'B' into 'LU', which would the inverse of 'A'. */
	for(i = 0; i < size; i++) for(j = 0; j < size; j++) LU[i][j] = B[j][i];

	return 0;
}

/*****************************************************************************/
void GaussJordan (int size, double R[size][size], double B[size][size])
{
	int i, j, k;
	double t;

	for (i = 0; i < size; i++) 	B[i][i] = 1;

	for (i = 0; i < size; i++)
		{
			t = R[i][i];
			for(k = 0; k < size; k++)
				{
					B[i][k] = B[i][k] / t;
					R[i][k] = R[i][k] / t;
				}

			for(j = 0; j < size; j++)
				{
					if(i != j)
						{
							t = R[j][i];
							for (k = 0; k < size; k++)
								{
									B[j][k] = B[j][k] - B[i][k] * t;
									R[j][k] = R[j][k] - R[i][k] * t;
								}
						}

				}
		}

}

/*****************************************************************************/

int init_timer ( u16 DeviceId , u8 TmrCtrNumber ){
int Status ;
XTmrCtr * TmrCtrInstancePtr = & TimerCounter ;
/*
* Initialize the timer counter so that it 's ready to use ,
* specify the device ID that is generated in xparameters .h
*/
Status = XTmrCtr_Initialize ( TmrCtrInstancePtr , DeviceId );
if ( Status != XST_SUCCESS ) {
return XST_FAILURE ;
}
/*
* Perform a self - test to ensure that the hardware was built
* correctly , use the 1st timer in the device (0)
*/
Status = XTmrCtr_SelfTest ( TmrCtrInstancePtr , TmrCtrNumber );
if ( Status != XST_SUCCESS ) {
return XST_FAILURE ;
}
/*
* Enable the Autoreload mode of the timer counters .
*/
return XST_SUCCESS ;}


u32 start_timer (u8 TmrCtrNumber ){

	XTmrCtr * TmrCtrInstancePtr = & TimerCounter ;
	XTmrCtr_SetOptions ( TmrCtrInstancePtr , TmrCtrNumber , XTC_AUTO_RELOAD_OPTION );
	u32 val = XTmrCtr_GetValue ( TmrCtrInstancePtr , TmrCtrNumber );
	XTmrCtr_Start ( TmrCtrInstancePtr , TmrCtrNumber );
	return val ;
}


u32 stop_timer (u8 TmrCtrNumber ){

	XTmrCtr * TmrCtrInstancePtr = & TimerCounter ;
	u32 val = XTmrCtr_GetValue ( TmrCtrInstancePtr , TmrCtrNumber );
	XTmrCtr_SetOptions ( TmrCtrInstancePtr , TmrCtrNumber , 0);
	return val;

}


/******************************************************************************/
int ReceiveData(s32* array, int Length)
{

	Xil_DCacheInvalidateRange((UINTPTR)array, Length);

	return XST_SUCCESS;
}

/******************************************************************************/
void TxIntrHandler(void *Callback)
{

	u32 IrqStatus;
	int TimeOut;
	XAxiDma *AxiDmaInst = (XAxiDma *)Callback;

	/* Read pending interrupts */
	IrqStatus = XAxiDma_IntrGetIrq(AxiDmaInst, XAXIDMA_DMA_TO_DEVICE);

	/* Acknowledge pending interrupts */


	XAxiDma_IntrAckIrq(AxiDmaInst, IrqStatus, XAXIDMA_DMA_TO_DEVICE);

	/*
	 * If no interrupt is asserted, we do not do anything
	 */
	if (!(IrqStatus & XAXIDMA_IRQ_ALL_MASK)) {

		return;
	}

	/*
	 * If error interrupt is asserted, raise error flag, reset the
	 * hardware to recover from the error, and return with no further
	 * processing.
	 */
	if ((IrqStatus & XAXIDMA_IRQ_ERROR_MASK)) {

		Error = 1;

		/*
		 * Reset should never fail for transmit channel
		 */
		XAxiDma_Reset(AxiDmaInst);

		TimeOut = RESET_TIMEOUT_COUNTER;

		while (TimeOut) {
			if (XAxiDma_ResetIsDone(AxiDmaInst)) {
				break;
			}

			TimeOut -= 1;
		}

		return;
	}

	/*
	 * If Completion interrupt is asserted, then set the TxDone flag
	 */
	if ((IrqStatus & XAXIDMA_IRQ_IOC_MASK)) {

		TxDone = 1;
	}
}

/*****************************************************************************/
/*
*
* This is the DMA RX interrupt handler function
*
* It gets the interrupt status from the hardware, acknowledges it, and if any
* error happens, it resets the hardware. Otherwise, if a completion interrupt
* is present, then it sets the RxDone flag.
*
* @param	Callback is a pointer to RX channel of the DMA engine.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void RxIntrHandler(void *Callback)
{
	u32 IrqStatus;
	int TimeOut;
	XAxiDma *AxiDmaInst = (XAxiDma *)Callback;

	/* Read pending interrupts */
	IrqStatus = XAxiDma_IntrGetIrq(AxiDmaInst, XAXIDMA_DEVICE_TO_DMA);

	/* Acknowledge pending interrupts */
	XAxiDma_IntrAckIrq(AxiDmaInst, IrqStatus, XAXIDMA_DEVICE_TO_DMA);

	/*
	 * If no interrupt is asserted, we do not do anything
	 */
	if (!(IrqStatus & XAXIDMA_IRQ_ALL_MASK)) {
		return;
	}

	/*
	 * If error interrupt is asserted, raise error flag, reset the
	 * hardware to recover from the error, and return with no further
	 * processing.
	 */
	if ((IrqStatus & XAXIDMA_IRQ_ERROR_MASK)) {

		Error = 1;

		/* Reset could fail and hang
		 * NEED a way to handle this or do not call it??
		 */
		XAxiDma_Reset(AxiDmaInst);

		TimeOut = RESET_TIMEOUT_COUNTER;

		while (TimeOut) {
			if(XAxiDma_ResetIsDone(AxiDmaInst)) {
				break;
			}

			TimeOut -= 1;
		}

		return;
	}

	/*
	 * If completion interrupt is asserted, then set RxDone flag
	 */
	if ((IrqStatus & XAXIDMA_IRQ_IOC_MASK)) {

		RxDone = 1;
	}
}

/*****************************************************************************/
/*
*
* This function setups the interrupt system so interrupts can occur for the
* DMA, it assumes INTC component exists in the hardware system.
*
* @param	IntcInstancePtr is a pointer to the instance of the INTC.
* @param	AxiDmaPtr is a pointer to the instance of the DMA engine
* @param	TxIntrId is the TX channel Interrupt ID.
* @param	RxIntrId is the RX channel Interrupt ID.
*
* @return
*		- XST_SUCCESS if successful,
*		- XST_FAILURE.if not succesful
*
* @note		None.
*
******************************************************************************/
int SetupIntrSystem(INTC * IntcInstancePtr,
			   XAxiDma * AxiDmaPtr, u16 TxIntrId, u16 RxIntrId)
{
	int Status;

#ifdef XPAR_INTC_0_DEVICE_ID

	/* Initialize the interrupt controller and connect the ISRs */
	Status = XIntc_Initialize(IntcInstancePtr, INTC_DEVICE_ID);
	if (Status != XST_SUCCESS) {

		xil_printf("Failed init intc\r\n");
		return XST_FAILURE;
	}

	Status = XIntc_Connect(IntcInstancePtr, TxIntrId,
			       (XInterruptHandler) TxIntrHandler, AxiDmaPtr);
	if (Status != XST_SUCCESS) {

		xil_printf("Failed tx connect intc\r\n");
		return XST_FAILURE;
	}

	Status = XIntc_Connect(IntcInstancePtr, RxIntrId,
			       (XInterruptHandler) RxIntrHandler, AxiDmaPtr);
	if (Status != XST_SUCCESS) {

		xil_printf("Failed rx connect intc\r\n");
		return XST_FAILURE;
	}

	/* Start the interrupt controller */
	Status = XIntc_Start(IntcInstancePtr, XIN_REAL_MODE);
	if (Status != XST_SUCCESS) {

		xil_printf("Failed to start intc\r\n");
		return XST_FAILURE;
	}

	XIntc_Enable(IntcInstancePtr, TxIntrId);
	XIntc_Enable(IntcInstancePtr, RxIntrId);

#else

	XScuGic_Config *IntcConfig;


	/*
	 * Initialize the interrupt controller driver so that it is ready to
	 * use.
	 */
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == IntcConfig) {
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig,
					IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	XScuGic_SetPriorityTriggerType(IntcInstancePtr, TxIntrId, 0xA0, 0x3);

	XScuGic_SetPriorityTriggerType(IntcInstancePtr, RxIntrId, 0xA0, 0x3);
	/*
	 * Connect the device driver handler that will be called when an
	 * interrupt for the device occurs, the handler defined above performs
	 * the specific interrupt processing for the device.
	 */
	Status = XScuGic_Connect(IntcInstancePtr, TxIntrId,
				(Xil_InterruptHandler)TxIntrHandler,
				AxiDmaPtr);
	if (Status != XST_SUCCESS) {
		return Status;
	}

	Status = XScuGic_Connect(IntcInstancePtr, RxIntrId,
				(Xil_InterruptHandler)RxIntrHandler,
				AxiDmaPtr);
	if (Status != XST_SUCCESS) {
		return Status;
	}

	XScuGic_Enable(IntcInstancePtr, TxIntrId);
	XScuGic_Enable(IntcInstancePtr, RxIntrId);


#endif

	/* Enable interrupts from the hardware */

	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			(Xil_ExceptionHandler)INTC_HANDLER,
			(void *)IntcInstancePtr);

	Xil_ExceptionEnable();

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function disables the interrupts for DMA engine.
*
* @param	IntcInstancePtr is the pointer to the INTC component instance
* @param	TxIntrId is interrupt ID associated w/ DMA TX channel
* @param	RxIntrId is interrupt ID associated w/ DMA RX channel
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void DisableIntrSystem(INTC * IntcInstancePtr,
					u16 TxIntrId, u16 RxIntrId)
{
#ifdef XPAR_INTC_0_DEVICE_ID
	/* Disconnect the interrupts for the DMA TX and RX channels */
	XIntc_Disconnect(IntcInstancePtr, TxIntrId);
	XIntc_Disconnect(IntcInstancePtr, RxIntrId);
#else
	XScuGic_Disconnect(IntcInstancePtr, TxIntrId);
	XScuGic_Disconnect(IntcInstancePtr, RxIntrId);
#endif
}

int setup_DMA(void)
{
	int Status;
	XAxiDma_Config *Config;

	//xil_printf("\r\n--- Setting up DMA --- \r\n");

		Config = XAxiDma_LookupConfig(DMA_DEV_ID);
		if (!Config) {
			xil_printf("No config found for %d\r\n", DMA_DEV_ID);

			return XST_FAILURE;
		}

		/* Initialize DMA engine */
		Status = XAxiDma_CfgInitialize(&AxiDma, Config);

		if (Status != XST_SUCCESS) {
			xil_printf("Initialization failed %d\r\n", Status);
			return XST_FAILURE;
		}

		if(XAxiDma_HasSg(&AxiDma)){
			xil_printf("Device configured as SG mode \r\n");
			return XST_FAILURE;
		}

		/* Set up Interrupt system  */
		Status = SetupIntrSystem(&Intc, &AxiDma, TX_INTR_ID, RX_INTR_ID);
		if (Status != XST_SUCCESS) {

			xil_printf("Failed intr setup\r\n");
			return XST_FAILURE;
		}

		/* Disable all interrupts before setup */

		XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,
							XAXIDMA_DMA_TO_DEVICE);

		XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,
					XAXIDMA_DEVICE_TO_DMA);

		/* Enable all interrupts */
		XAxiDma_IntrEnable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,
								XAXIDMA_DMA_TO_DEVICE);


		XAxiDma_IntrEnable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,
								XAXIDMA_DEVICE_TO_DMA);

		return XST_SUCCESS;
}

int main_DMA(datatype * array, s32* receiver, int MAX_PKT_LEN, int NUMBER_OF_TRANSFERS)
{
	int Status;
	int Tries = NUMBER_OF_TRANSFERS;
	int Index;
	//u32 *TxBufferPtr;
	//u32 *RxBufferPtr;
	//u32 Value;

	//TxBufferPtr = (u32 *)TX_BUFFER_BASE;
	//RxBufferPtr = (u32 *)RX_BUFFER_BASE;

//	xil_printf("sending packet \n");
	/* Initialize flags before start transfer test  */
	TxDone = 0;
	RxDone = 0;
	Error = 0;

	//Value = TEST_START_VALUE;

	/*for(Index = 0; Index < MAX_PKT_LEN; Index ++) {
			TxBufferPtr[Index] = Value;

			Value = (Value + 1) ;
	}*/

	/* Flush the SrcBuffer before the DMA transfer, in case the Data Cache
	 * is enabled
	 */
	//Xil_DCacheFlushRange((UINTPTR)TxBufferPtr, MAX_PKT_LEN);
	Xil_DCacheFlushRange((UINTPTR)array, MAX_PKT_LEN);

	/* Send a packet */
	for(Index = 0; Index < Tries; Index ++) {

		Status = XAxiDma_SimpleTransfer(&AxiDma,(UINTPTR) receiver,
				MAX_PKT_LEN, XAXIDMA_DEVICE_TO_DMA);

		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		/*Status = XAxiDma_SimpleTransfer(&AxiDma,(UINTPTR) TxBufferPtr,
					MAX_PKT_LEN, XAXIDMA_DMA_TO_DEVICE);*/

		Status = XAxiDma_SimpleTransfer(&AxiDma,(UINTPTR) array,
							MAX_PKT_LEN, XAXIDMA_DMA_TO_DEVICE);

		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}


		/*
		 * Wait TX done and RX done
		 */
		while (!TxDone && !RxDone && !Error) {
				/* NOP */
		}

		if (Error) {
			xil_printf("Failed test transmit%s done, "
			"receive%s done\r\n", TxDone? "":" not",
							RxDone? "":" not");

			goto Done;

		}

		/*
		 * Test finished, check data
		 */
		/*Status = CheckData(MAX_PKT_LEN, 0xC);
		if (Status != XST_SUCCESS) {
			xil_printf("Data check failed\r\n");
			goto Done;
		}*/
	}


	//xil_printf("Successfully ran AXI DMA interrupt Example\r\n");


	/* Disable TX and RX Ring interrupts and return success */

	//DisableIntrSystem(&Intc, TX_INTR_ID, RX_INTR_ID);

Done:
	//xil_printf("--- Exiting main() --- \r\n");

	return XST_SUCCESS;
}


