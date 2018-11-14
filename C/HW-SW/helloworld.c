
/***************************** Include Files *********************************/

#include "xparameters.h"
#include "functions.h"

/************************** Variable Definitions *****************************/

unsigned int *pointer = XPAR_BRAMTEST133_V1_0_0_BASEADDR;
#define MAX_PKT_LEN (1500)
#define NUMBER_OF_TRANSFERS (1)
/* Device instance definitions
*/

/*****************************************************************************/
/**
*
* Main function*/
static u32 array [2000]={};
static u32 receiver [200]={};

int main(void)
{

	//Xil_DCacheDisable();
	int Status;
	//int MAX_PKT_LEN=255;
	//u32 array [MAX_PKT_LEN]={};
	//u32 *receiver=RX_BUFFER_BASE;

	xil_printf("UPLOAD MATRIX \n");
	for (int i = 0; i< 16*16; i++)
		{
			*(pointer) = 0x60000000;

		}
	for (int i = 0; i< 256; i++)
			{
			array[i] = (u32) i;

			}

	xil_printf("UPLOADED! \n");



	init_timer ( XPAR_AXI_TIMER_0_DEVICE_ID , 0 );
	u32 value1 = start_timer ( 0 );

	Status = setup_DMA();
	if (Status != XST_SUCCESS) {
				return XST_FAILURE;
			}

	for(int i = 0; i<1 ; i++)
	{
	Status = main_DMA(array +i*16*16, receiver+i*16, MAX_PKT_LEN, NUMBER_OF_TRANSFERS);
	if (Status != XST_SUCCESS) {
				return XST_FAILURE;
			}

	}
	ReceiveData (receiver,200);
	u32 value2 = stop_timer ( 0 );
		xil_printf ("\n Timer : %d\n", value2 - value1 );

	for(int i = 0 ; i<40; i++)
		xil_printf("%ld; ", receiver[i]);


}
