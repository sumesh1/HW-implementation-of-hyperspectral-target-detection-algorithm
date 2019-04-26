#define	DEBUG 1

#define ACER  0
#define ASMF  1
#define ASMF2 2
#define CEMA  3
#define ALG ACER

//image size
#define N_bands 16
#define N_pixels (512*217)

#define threshold 0.99

//change these together
#define byte_in 2   	   //input byte size
#define byte_out 8		   //output byte size
typedef s16 datatype;
typedef s64 outputtype;


#define image_file_name "spca.bin"
#define results_file_name "results.bin"
#define target_file_name "tpca.bin"

#define corr_percent 100  //correlation subsampling





