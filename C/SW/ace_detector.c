#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xtime_l.h"
#include "xil_io.h"
#include "xsdps.h"		/* SD device driver */
#include "xil_cache.h"
#include "xplatform_info.h"
#include "ff.h"
#include "math.h"

#define N_bands 20
#define N_pixels (512*217)
#define threshold 0.6


typedef s32 datatype;

//FUNCTIONS
double scalarProduct (double*, datatype*, int);
int FfsSd(char*,datatype * );
int FfsSdWrite (char*,double *);
int read_data(char*,datatype * );
int write_data(char*,double *);
//void matrixMult(s16*,s16*,s16*);
//void removeMean(s16*,s32*,int,int);
void hyperCorr (datatype *, double (*)[], int, int,int);
int LUPdecompose(int , double (*)[], int *);
int LUPinverse(int size, int P[size], double LU[size][size],double [size][size],double [size],double [size]);
void arrayMatrixProduct(int , datatype *, double [][N_bands], double *);
void GaussJordan (int size, double R[size][size],double B[size][size]);
int ACE(double);

//GLOBAL STATIC VARIABLES
static FIL fil;		/* File object */
static FATFS fatfs;
static char HyperMatrixFile[32] = "pcaimage.bin";
static char ResultsFile[32] = "ace1.bin";
static char TargetFile[32] = "tgt.bin";
static char *SD_File;
static u32 Platform;
static datatype HyperData[N_pixels*N_bands] ;//__attribute__ ((aligned(32)));
//s32 HyperDataNoMean[N_pixels*N_bands]={};
static double R [N_bands][N_bands]={};
static  int P[N_bands];
static double B[N_bands][N_bands]={};
static double X[N_bands]={};
static double Y[N_bands]={};
static double sR[N_bands]={};
static double xR[N_bands]={};
static double result[N_pixels]={};
static  datatype target[N_bands]={};

/*****************************************************************************/

int main()
{

	//TIMER
	XTime tStart, tEnd;

	//int i;
    //double value;
    int detected=0;

    init_platform();

    //Start timer
    XTime_GetTime(&tStart);

    //IMPORT HYPERSPECTRAL CUBE TO DDR
    read_data(HyperMatrixFile,HyperData);

    //IMPORT HYPERSPECTRAL Target TO DDR
    read_data(TargetFile,target);

    //DATA DEMEANING
    /* printf("Started demeaning! \n");
    removeMean(HyperData, HyperDataNoMean, N_bands, N_pixels);
	*/

    //Calculate Correlation Matrix R
    printf("Started calculating R...\n");

    hyperCorr (HyperData, R,  N_bands, N_pixels,100);


    printf("%f %f %f \n", R[0][0],R[0][1],R[0][2]);
    //Calculate LU decomposition
    if(LUPdecompose(N_bands, R, P) < 0) return -1;
    printf("The LUP decomposition of 'R' is successful.\n");

    //Calculate LU inversion
    if(LUPinverse(N_bands, P, R,B,X,Y) < 0) return -1;
    printf("Matrix inversion successful.\n");

    //LU Decomposition or GaussJordan
    //GaussJordan(N_bands,R, B);
    // R=	B;

    //Prepare s'*R^-1
    arrayMatrixProduct(N_bands,target,R,sR);

    //Prepare sR*s
    double sRs= scalarProduct(sR,target,N_bands);
    //double temp1,temp2;
    printf("Start calculating ACE...\n");

    //CALCULATE ACE for all pixels
    detected=ACE(sRs);

    write_data(ResultsFile, result);

    //Stop timer
    XTime_GetTime(&tEnd);

      printf("t=%15.5lf sec\n",(long double)((tEnd-tStart) *2)/(long double)XPAR_PS7_CORTEXA9_0_CPU_CLK_FREQ_HZ);
      printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
      printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));
      printf("We had %d detected target pixels which is %f percent. \n",
    		   detected,100*(double)detected/(double)N_pixels);

       cleanup_platform();
    return 0;
}

/*****************************************************************************/

int ACE(double sRs)
{
	double temp1,temp2,value;
	int detected=0;
	 for(int i=0;i<N_pixels;i++)
	    {

		   temp1= scalarProduct(sR,HyperData+i*N_bands,N_bands);
		   temp1*=temp1;

		   arrayMatrixProduct(N_bands,HyperData+i*N_bands,R,xR);
		   temp2= scalarProduct(xR,HyperData+i*N_bands,N_bands);
		   temp2*=sRs;

		   //detection statistic
		   value=temp1/temp2;
		   result[i]=value;

	        if(value>threshold)
	        		detected=detected+1;
	        /*		printf("target detected\n");

	        else
	        	printf("not a target \n");*/
	    }

	 return detected;
}


/*****************************************************************************/

// SCALAR PRODUCT OF TWO VECTORS a AND b WITH LENGTH N
double scalarProduct (double* a, datatype* b, int N)
{
    int i;
    double sum=0;
        for (i=0;i<N;i++)
        {
        	sum+=(double)b[i]*a[i];
        }

        return sum;
}

/*****************************************************************************/

double SAM (datatype *x, datatype *s, u64 target_product, int N)
{

   // double sx=(double)scalarProduct(s,x,N);
   //return (sx*sx)/((double)target_product*(double)scalarProduct(x,x,N));

	//NEW CODE DOWN, faster by 5%
	u64 xx=0,sx=0;
    int i;
    for (i=0;i<N;i++)
    {
    	sx=sx+x[i]*s[i];
    	xx=xx+x[i]*x[i];
    }
    return (sx*sx)/((double)(target_product)*(double)xx);
}

/*****************************************************************************/

//calculate correlation matrix RR
void hyperCorr (datatype *m, double (*R)[N_bands], int NB, int NP, int percent)
{
	int i,j,p,k=0;
	int divisor=(int)(percent*NP/100);
	int jump=(int)(100/percent);


	printf("The jump is %d\n",jump);

	for(p=0; p<NP; p=p+jump)
	{
		k=NB*p;
		for (i=0; i<NB; i++)
		{
			for (j=0; j<NB; j++)
			{
				R[i][j]=R[i][j]+((double)m[k+i]*m[k+j]/divisor);
			}
		}
	}
}

/*****************************************************************************/

//Array-Matrix product; vector 1xp; matrix pxp => 1xp vector
void arrayMatrixProduct(int size, datatype *A, double R[][N_bands], double *result)
{
	int i,j;
	double sum;
	for (i=0; i<size; i++)
	{
		sum=0;
		for (j=0; j<size; j++)
		{
			sum=sum+A[j]*R[i][j];
		}
		result[i]=sum;
	}

}

/*****************************************************************************/

//Remove mean from matrix M, new matrix is R
void removeMean(datatype* M,s32* R,int NB, int NP)
{
	s32 mean[N_bands]={};
	int i,j,k=0;
	for (j=0; j<NB;j++)
	{
		k=j;
		for (i=0; i<NP; i++)
		{
			mean[j]=mean[j]+M[k];
			k=k+NB;
		}
		mean[j]=mean[j]/NB;
	}

	printf("Done calculating means! \n");
	for (j=0; j<NP;j++)
	{
		for (i=0; i<NB; i++)
		{
			R[i+j*NB]=M[i+j*NB]-mean[i];
		}
	}


}

/*****************************************************************************/

int read_data(char *File_Name,datatype * OutputArray)
{
	int Status;

	xil_printf("Downloading image from SD card \r\n");

	Status = FfsSd(File_Name,OutputArray);
	if (Status != XST_SUCCESS) {
		xil_printf("Download failed \r\n");
		return XST_FAILURE;
	}

	xil_printf("Successfully downloaded image file \r\n");

	return XST_SUCCESS;

}

/*****************************************************************************/

int write_data(char *File_Name, double * OutputArray)
{
	int Status;

	xil_printf("Writing results to SD card \r\n");

	Status = FfsSdWrite(File_Name, OutputArray);
	if (Status != XST_SUCCESS) {
		xil_printf("Writing failed \r\n");
		return XST_FAILURE;
	}

	xil_printf("Successfully written results file \r\n");

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
	u32 FileSize = N_bands*N_pixels*4;
	/*
	 * To test logical drive 0, Path should be "0:/"
	 * For logical drive 1, Path should be "1:/"
	 */
	TCHAR *Path = "0:/";

	Platform = XGetPlatform_Info();
	if (Platform == XPLAT_ZYNQ_ULTRA_MP) {
		/*
		 * Since 8MB in Emulation Platform taking long time, reduced
		 * file size to 8KB.
		 */
		FileSize = N_bands*N_pixels*4;
	}

	// Register volume work area, initialize device

	Res = f_mount(&fatfs, Path, 0);

	if (Res != FR_OK) {
		return XST_FAILURE;
	}

	SD_File = (char *)File_Name;

	Res = f_open(&fil, SD_File,  FA_READ);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Pointer to beginning of file .
	 */

	Res = f_lseek(&fil, 0);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Read data from file.
	 */
	Res = f_read(&fil, (void*)OutputArray, FileSize,
			&NumBytesRead);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Data verification
	 */

	xil_printf("number bytes read: %d \n", NumBytesRead);

	/*
	 * Close file.
	 */
	Res = f_close(&fil);
	if (Res) {
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/*****************************************************************************/

int FfsSdWrite (char * File_Name,double * OutputArray)
{
	FRESULT Res;
	UINT NumBytesWritten;
	u32 FileSize = (N_pixels*8);
	/*
	 * To test logical drive 0, Path should be "0:/"
	 * For logical drive 1, Path should be "1:/"
	 */
	TCHAR *Path = "0:/";

	Platform = XGetPlatform_Info();
	if (Platform == XPLAT_ZYNQ_ULTRA_MP) {
		/*
		 * Since 8MB in Emulation Platform taking long time, reduced
		 * file size to 8KB.
		 */
		FileSize = N_pixels*8;
	}

	/*
	 * Register volume work area, initialize device
	 */
	Res = f_mount(&fatfs, Path, 0);

	if (Res != FR_OK) {
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
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Pointer to beginning of file .
	 */
	Res = f_lseek(&fil, 0);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Write data to file.
	 */
	Res = f_write(&fil, (const void*)OutputArray, FileSize,
			&NumBytesWritten);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Close file.
	 */
	Res = f_close(&fil);
	if (Res) {
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/*****************************************************************************/

//Decomposition of matrix A into L, U, P, using partial pivoting decomposition.s
//Decomposed L, U is stored in A. Diagonal of L is not stored (it is all 1)
int LUPdecompose(int size, double A[size][size], int P[size])
   {
    int i, j, k, kd = 0, T;
    double p, t;

 /* Initializing permutation array */
    for(i=0; i<size; i++) P[i] = i;

    for(k=0; k<size-1; k++)
       {
        p = 0;
        for(i=k; i<size; i++)
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
        for(i=0; i<size; i++)
            {
             t = A[kd][i];
             A[kd][i] = A[k][i];
             A[k][i] = t;
            }

        for(i=k+1; i<size; i++) //Performing subtraction to decompose A as LU.
            {
             A[i][k] = A[i][k]/A[k][k];
             for(j=k+1; j<size; j++) A[i][j] -= A[i][k]*A[k][j];
            }
        }

//Now, A contains the L (without diagonal) and U.

    return 0;
   }


/*****************************************************************************/

/* This function calculates the inverse of the LUP decomposed matrix 'LU' and pivoting
 * information stored in 'P'. The inverse is returned through the matrix 'LU' itself.
 * 'B', X', and 'Y' are used as temporary spaces. */
int LUPinverse(int size, int P[size], double LU[size][size],double B[size][size], double X[size], double Y[size])
   {
    int i, j, n, m;
    double t;

  //Initializing X and Y.
    for(n=0; n<size; n++) X[n] = Y[n] = 0;

 /* Solving LUX = Pe, in order to calculate the inverse of 'A'. Here, 'e' is a column
  * vector of the identity matrix of size 'size-1'. Solving for all 'e'. */
    for(i=0; i<size; i++)
     {
    //Storing elements of the i-th column of the identity matrix in i-th row of 'B'.
      for(j = 0; j<size; j++) B[i][j] = 0;
      B[i][i] = 1;

   //Solving Ly = Pb.
     for(n=0; n<size; n++)
       {
        t = 0;
        for(m=0; m<=n-1; m++) t += LU[n][m]*Y[m];
        Y[n] = B[i][P[n]]-t;
       }

   //Solving Ux = y.
     for(n=size-1; n>=0; n--)
       {
        t = 0;
        for(m = n+1; m < size; m++) t += LU[n][m]*X[m];
        X[n] = (Y[n]-t)/LU[n][n];
       }//Now, X contains the solution.

      for(j = 0; j<size; j++) B[i][j] = X[j]; //Copying 'X' into the same row of 'B'.
     } //Now, 'B' the transpose of the inverse of 'A'.

 /* Copying transpose of 'B' into 'LU', which would the inverse of 'A'. */
    for(i=0; i<size; i++) for(j=0; j<size; j++) LU[i][j] = B[j][i];

    return 0;
   }

/*****************************************************************************/
void GaussJordan (int size, double R[size][size],double B[size][size])
{
	int i,j,k;
	double t;

	for (i=0; i<size; i++) 	B[i][i]=1;

	for (i=0; i<size;i++)
	{
		t=R[i][i];
		for(k=0;k<size;k++)
			{
			B[i][k]=B[i][k]/t;
			R[i][k]=R[i][k]/t;
			}

		for(j=0; j<size; j++)
		{
			if(i!=j)
			{
				t=R[j][i];
				for (k=0; k<size; k++)
					{
					B[j][k]= B[j][k]-B[i][k]*t;
					R[j][k]= R[j][k]-R[i][k]*t;
					}
			}

		}
	}

}
