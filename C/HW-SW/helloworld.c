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
#include "functions.h"
#include "det_parameters.h"


#define MAX_PKT_LEN (256*4 + 2*4)
#define NUMBER_OF_TRANSFERS (1)



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
    //HW timer
    init_timer ( XPAR_AXI_TIMER_0_DEVICE_ID , 0 );
    u32 value1 = start_timer ( 0 );

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


  //  for (int i=0;i<30; i++)
   // printf(" %ld \n", HyperData[i]);


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

    printf("inverted: \n");
    printf("%.15f %.15f %.15f \n", R[0][0],R[0][1],R[0][2]);

    //convert to FIXED POINT MULT WITH 2^40 for R^-1

    for(int i=0;i<N_bands; i++){
    	for(int j=0;j<N_bands;j++){
    		R32[i][j]= (s32)( R[i][j]*1099511627776);
    	}
    }
    printf("inverted fp: \n");
    printf("%ld %ld %ld \n", R32[0][0],R32[0][1],R32[0][2]);


    //Prepare s'*R^-1
    arrayMatrixProduct(N_bands,target,R,sR);

    //convert to FIXED POINT MULT WITH 2^32
    for(int j = 0;j < N_bands; j++){
        		sR32[j]	= (s32)( sR[j]*4294967296);
        	}
    printf("sR fp: \n");
    printf("%ld %ld %ld \n", sR32[0],sR32[1],sR32[2]);


    //Prepare sR*s
    double sRs = scalarProduct(sR,target,N_bands);
    //double temp1,temp2;

    printf("Start calculating ACE...\n");

 //HW ACCELERATOR

    xil_printf("UPLOAD MATRIX \n");

    for(int i = 0; i < N_bands; i++){
       	for(int j = 0; j< N_bands; j++){

       		*(BRAM_BASE_ADDR) = R32[i][j];
       	}
       }

    xil_printf("UPLOADED! \n");


    	xil_printf("UPLOAD ARRAY SR \n");
    	for (int i = 0; i< N_bands; i++)
    			{

    		*(BRAM_BASE_ADDR + 1) = sR32[i];

    			}
    	xil_printf("UPLOADED! \n");


    //DEBUG ------------------------------------------------------------------
/*
    	xil_printf("DEBUG  SR \n");
    	//enable debug
    	*(BRAM_BASE_ADDR + 3) = 1;
    	//selection initial 0
    	*(BRAM_BASE_ADDR + 2) = 0;

    	    	for (int i = 0; i< N_bands; i++)
    	    			{
    	    		*(BRAM_BASE_ADDR + 2) = i;
    	    		printf("sr3: %d; ", *(BRAM_BASE_ADDR + 3));
    	    		printf("sr2: %d; ", *(BRAM_BASE_ADDR + 2));
    	    		printf("MAT: %d; ", *(BRAM_BASE_ADDR));
    	    		printf("SR: %d; \n", *(BRAM_BASE_ADDR + 1));
    	    			}
    	    	xil_printf("END DEBUG \n");
*/




    	int Status;

    	Status = setup_DMA();
    	if (Status != XST_SUCCESS) {
    			xil_printf("FAILED SETTING UP DMA \n");
    					return XST_FAILURE;
    				}

    	//send packets
    	for(int i = 0; i<1; i++)
    	{

    	Status = main_DMA(HyperData +i*16*16, receiver+i*16, MAX_PKT_LEN, NUMBER_OF_TRANSFERS);
    	if (Status != XST_SUCCESS) {
    				return XST_FAILURE;
    			}

    	}

    	ReceiveData (receiver,N_pixels);


    	for(int i = 0 ; i<40; i++)
    		xil_printf("%ld; ", receiver[i]);





    //HW ACCELERATOR END


    write_data(ResultsFile, receiver);

    //Stop timer
    XTime_GetTime(&tEnd);
    //HW timer
    u32 value2 = stop_timer ( 0 );
    xil_printf ("\n Timer : %d\n", value2 - value1 );


      printf("t=%15.5lf sec\n",(long double)((tEnd-tStart) *2)/(long double)XPAR_PS7_CORTEXA9_0_CPU_CLK_FREQ_HZ);
      printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
      printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));
    //  printf("We had %d detected target pixels which is %f percent. \n",
    	//	   detected,100*(double)detected/(double)N_pixels);

       cleanup_platform();
    return 0;
}
