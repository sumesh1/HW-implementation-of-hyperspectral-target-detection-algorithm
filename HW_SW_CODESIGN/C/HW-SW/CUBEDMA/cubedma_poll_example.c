/*
 * Lars Henrik Bolstad 2018
 *
 * cubedma_poll_example.c: Polled CubeDMA example
 *
 * https://www.ntnu.no/wiki/display/NSSL/Cube+DMA
 *
 * This application configures and tests the CubeDMA core,
 * with unprocessed data (eg. connected through a FIFO).
 * PS7 UART (Zynq) is not initialized by this application,
 * since bootrom/bsp configures it to baud rate 115200.
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <xil_io.h> /* TODO: Remove debug traces */
#include <xil_cache.h>
#include "cubedma.h"
#include "platform.h"

typedef enum { TEST_SUCCESS, TEST_FAIL } test_result_t;
test_result_t cubedma_RunTests();
/*
int main()
{
    init_platform();

    printf("Running tests\n\r");

    if (cubedma_RunTests() == TEST_SUCCESS) {
    	printf("Test successfull!\n\r");
    }
    else {
    	printf("Test failed!\n\r");
    }

    printf("Execution done!\n\r");

    cleanup_platform();
    return 0;
}*/

#define COMPONENTS 0x2000
#define TIMEOUT 0xFFF

volatile u32 source[COMPONENTS] __attribute__ ((aligned (32)));
volatile u32 destin[COMPONENTS] __attribute__ ((aligned (32)));

void dbg_print(u32 addr, u32 n){
	for (u32 i = 0; i < n; i++) {
		u32 val = Xil_In32(addr+i*4);
		printf("0x%08lx: 0x%08lx\n\r", (u32)(addr)+i*4, val);
	}
}

test_result_t cubedma_RunTests(){
	printf("Transferring %lu components from 0x%08lx to 0x%08lx\n\r",
			(u32)COMPONENTS, (u32)&source, (u32)&destin);

	cubedma_init_t cubedma_parameters = {
		.address = {
			.source      = (u32)(source),
			.destination = (u32)(destin)
		},
		.cube = {
			.n_planes  = 1,
			.c_offset  = 0,
			.planewise = FALSE,
			.blocks    = {
				.enabled = FALSE,
				.dims = { 0, 0, 0 }
			},
			.dims = {
				.width = 1,
				.height = 1,
				.depth = 1,
				.size_row = COMPONENTS
			}
		},
		.interrupt_enable = {
			{FALSE, FALSE}, {FALSE, FALSE}
		}
	};

	/* Fill memory */
	for (u32 i = 0; i < COMPONENTS; i++) {
		source[i] = i;
		destin[i] = 0;
	}

	/* Make sure the destination system memory is reset/cleaned for a valid
	 * test result. Source memory is flushed by the driver itself.
	 */
	Xil_DCacheFlushRange((INTPTR)destin, COMPONENTS*sizeof(destin));

	cubedma_Init(cubedma_parameters);

	cubedma_StartTransfer(S2MM);

	cubedma_StartTransfer(MM2S);

	/* Wait for transfer to finish */
	volatile u32 time;
	cubedma_error_t err = ERR_TIMEOUT;
	for (time = 0; time < TIMEOUT; time++) {
		if (cubedma_TransferDone(MM2S)) {
			err = SUCCESS;
			break;
		}
	}
	if (err != SUCCESS) {
		printf("ERROR: MM2S transfer timed out!\n\r");
	}

	err = ERR_TIMEOUT;
	for (time = 0; time < TIMEOUT; time++) {
		if (cubedma_TransferDone(S2MM)) {
			err = SUCCESS;
			break;
		}
	}
	if (err != SUCCESS) {
		printf("ERROR: S2MM transfer timed out!\n\r");
	}

	/* Check matching data */
	u32 matches = 0;
	u32 misses = 0;
	for (u32 i = 0; i < COMPONENTS; i++){
		if (source[i] == destin[i]) {
			matches++;
		}
		else {
			if (++misses < 10) {
				printf("%8lx: %08lx %08lx\n\r", i*4, source[i], destin[i]);
			}
		}
	}
	if (matches != COMPONENTS) {
		fprintf(stderr, "ERROR: Only %f%% of the data matches\n\r", \
				(double)matches*100/COMPONENTS);
		return TEST_FAIL;
	}
	else {
		printf("Transfer success!\n\r");
	}

	/* TODO: Handle interrupt error */

	return TEST_SUCCESS;
}
