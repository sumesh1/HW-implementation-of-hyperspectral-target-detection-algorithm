# Setting up the accelerator

## Files

* TopLevel_wrapper.vhd is the main file.
* script.tcl initializes Vivado project, creates block designs, one for simulation and one for synthesis with PS.

## Setting up generic values

### Default setting for 32 bit intermediate data:

```
PIXEL_DATA_WIDTH   		: positive := 16;
BRAM_DATA_WIDTH    		: positive := 32;
ST2IN_DATA_WIDTH   		: positive := 32;
ST3IN_DATA_WIDTH   		: positive := 32;
ST2IN_DATA_SLIDER  		: positive := 50;
ST2_ASMF2_DATA_SLIDER 	: positive := 72;
ST2_ASMF2SR_DATA_SLIDER	: positive := 46;
ST3IN_DATA1_SLIDER 		: positive := 50;
ST3IN_DATA2_SLIDER 		: positive := 62;
NUM_BANDS          		: positive := 16;
PACKET_SIZE        		: positive := 16;
OUT_DATA_WIDTH     		: positive := 32;
OUT_DATA1_SLIDER   		: positive := 62;
OUT_DATA2_SLIDER   		: positive := 31;
BRAM_ADDR_WIDTH    		: integer  := 4; 
BRAM_ROW_WIDTH     		: positive := 512;
```

Sliders are set to cut off:

* highest 32 bits (excluding MSB, two sign bits after multiplication);
* except for ST2_ASMF2_DATA_SLIDER and ST2_ASMF2SR_DATA_SLIDER

### Manual setup:

```
PIXEL_DATA_WIDTH   -> bit width of each component in pixel
BRAM_DATA_WIDTH    -> bit width of pre-processed data from PS
ST2IN_DATA_WIDTH   -> bit width of input data for stage 2
ST3IN_DATA_WIDTH   -> bit width of input data for stage 3

NUM_BANDS          -> number of bands in hyperspectral image
PACKET_SIZE        -> packet size of Master Output module
OUT_DATA_WIDTH     -> bit width of output data from core to divider

BRAM_ADDR_WIDTH    -> address bit width, equal to ceil(log2(NUM_BANDS)) 
BRAM_ROW_WIDTH     -> row bit width, equal to NUM_BANDS*BRAM_DATA_WIDTH
```

Sliders are used to change the position of truncation manually. 
Slider value is the desired MSB bit position where the cut starts.
Therefore the cut starts at SLIDER and stops at bit position SLIDER-OUT_WIDTH+1.

```
ST2IN_DATA_SLIDER  -> slider cutting output of stage 1 to fit as input of stage 2; Rx and sRx
ST3IN_DATA1_SLIDER -> slider cutting output of stage 2 to fit as input of stage 3; xRx
ST3IN_DATA2_SLIDER -> slider cutting output of stage 2 to fit as input of stage 3; (sRx)^2

OUT_DATA1_SLIDER   -> slider cutting output of stage 3 to fit as input of divider; xRx*sRs
OUT_DATA2_SLIDER   -> slider cutting output of stage 3 to fit as input of divider; (sRx)^2

ST2_ASMF2_DATA_SLIDER     -> slider cutting intermediate data only for ASMF-2;  (xRx)*(xRx)
ST2_ASMF2SR_DATA_SLIDER   -> slider cutting intermediate data only for ASMF-2;  (sRx)*(sRx)*(sRx)
```