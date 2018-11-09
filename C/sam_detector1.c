#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include "ff.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xtime_l.h"
#include "xil_io.h"
#include "xsdps.h"		/* SD device driver */
#include "xil_cache.h"
#include "xplatform_info.h"

#define N_bands 191
#define N_pixels (1280*307)
#define threshold 0.99

//FUNCTIONS
double scalarProduct (s16*, s16*, int);
int FfsSd(char*,s16 * );
int FfsSdWrite (char*,double *);
int read_data(char*,s16 * );
int write_data(char*,double *);
double SAM (s16 *, s16 *, double ,int);

//GLOBAL VARIABLES
static FIL fil;		/* File object */
static FATFS fatfs;
static char HyperMatrixFile[32] = "image.bin";
static char ResultsFile[32] = "sam.bin";
static char TargetFile[32] = "target.bin";
static char *SD_File;
u32 Platform;
static s16 HyperData[N_pixels*N_bands] __attribute__ ((aligned(32)));
static double result[N_pixels]={};
static  s16 target[N_bands]={};



int main()
{
	//TIMER
	XTime tStart, tEnd;

	int i;
    double value;
    int detected=0;

    init_platform();

    XTime_GetTime(&tStart);

    //IMPORT HYPERSPECTRAL CUBE TO DDR
    read_data(HyperMatrixFile,HyperData);

    //IMPORT HYPERSPECTRAL Target TO DDR
    read_data(TargetFile,target);

    //prepare s'*s
    double target_product=scalarProduct(target,target,N_bands);

    //CALCULATE SPECTRAL ANGLE FOR ALL PIXELS
    for(i=0;i<N_pixels;i++)
    {
    	value=SAM(HyperData+i*N_bands,target,target_product,N_bands);
    	result[i]=value;

        if(value>threshold)
        	detected=detected+1;
        	/*printf("target detected\n");
        else
        	printf("not a target \n");*/
    }

    XTime_GetTime(&tEnd);

    write_data(ResultsFile, result);

       printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
       printf("Output took %.2f us.\n",
              1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));
       printf("We had %d detected target pixels which is %f percent. \n",
    		   detected,100*(double)detected/(double)N_pixels);

       cleanup_platform();
    return 0;
}
/*****************************************************************************/

// SCALAR PRODUCT OF TWO VECTORS a AND b WITH LENGTH N
double scalarProduct (s16* a, s16* b, int N)
{
    int i;
    double sum=0;
        for (i=0;i<N;i++)
        {
            sum=sum+(double)b[i]*a[i];
        }

        return sum;
}
/*****************************************************************************/

// SPECTRAL ANGLE MAPPER
double SAM (s16 *x, s16 *s, double target_product, int N)
{

   // double sx=(double)scalarProduct(s,x,N);
   //return (sx*sx)/((double)target_product*(double)scalarProduct(x,x,N));

	//NEW CODE DOWN, faster by 5%
	double xx=0,sx=0;
    int i;
    for (i=0;i<N;i++)
    {
    	sx=sx+x[i]*s[i];
    	xx=xx+x[i]*x[i];
    }
    return (sx*sx)/((double)(target_product)*(double)xx);
}

/*****************************************************************************/

int read_data(char *File_Name,s16 * OutputArray)
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

int FfsSd(char* File_Name, s16* OutputArray)
{
	FRESULT Res;
	UINT NumBytesRead;
	//UINT NumBytesWritten;
	//u32 BuffCnt;

	//FILE SIZE HAS TO BE NUMBER OF BYTES
	u32 FileSize = N_bands*N_pixels*2;
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
		FileSize = N_bands*N_pixels*2;
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

int FfsSdWrite (char * File_Name, double * OutputArray)
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
