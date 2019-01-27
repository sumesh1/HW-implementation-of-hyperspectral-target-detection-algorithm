#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xsdps.h"
#include "ff.h"
#include "det_parameters.h"

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

int adaptive_cosine_estimator ();
int constrained_energy_minimization ();
int spectral_angle_mapper ();

double scalarProduct (double*, datatype*, int);
double scalarProduct2 (datatype* a, datatype* b, int N);
int FfsSd(char*, datatype * );
int FfsSdWrite (char*, double *);
int read_data(char*, datatype * );
int write_data(char*, double *);
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
