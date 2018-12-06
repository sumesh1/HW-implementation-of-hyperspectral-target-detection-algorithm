#include "functions.h"
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
#include "det_parameters.h"

/*****************************************************************************/

int main()
{

	init_platform();

	//TIMER
	XTime tStart, tEnd;

	int detected = 0;


	printf("Started...\n");
	//Start timer
	XTime_GetTime(&tStart);

	//IMPORT HYPERSPECTRAL CUBE TO DDR
	read_data(HyperMatrixFile, HyperData);

	//IMPORT HYPERSPECTRAL Target TO DDR
	read_data(TargetFile, target);

#ifdef ALG1
	detected = adaptive_cosine_estimator();
#endif

#ifdef ALG2
	detected = constrained_energy_minimization();
#endif

#ifdef ALG3
	detected = spectral_angle_mapper();
#endif

	write_data(ResultsFile, result);

	//Stop timer
	XTime_GetTime(&tEnd);

	//from system timer
	printf("t=%15.5lf sec\n", (long double)((tEnd - tStart) * 2) / (long double)XPAR_PS7_CORTEXA9_0_CPU_CLK_FREQ_HZ);
	printf("Output took %llu clock cycles.\n", 2 * (tEnd - tStart));
	printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND / 1000000));
	printf("We had %d detected target pixels which is %f percent. \n",
	       detected, 100 * (double)detected / (double)N_pixels);


	cleanup_platform();
	return 0;
}


