clc;
prepare_dataset;
num_bands  = q;
num_pixels = size(M,2);
beta = 10000; 
n = 100;
R_inv_init    = (beta) * eye(num_bands ,num_bands);
R = R_inv_init;
M(M>2^15-1) = 2^15-1;
M(M<-2^15)  = -2^15; 

for i = 1:n
 x = M(:,i);
 [R]=ShermanMorrison(R,x);
end

 
