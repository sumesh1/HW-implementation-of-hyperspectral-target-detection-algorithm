%% INFO
%deep pipelined implementation by Jie Lei - 
%A Deep Pipelined Implementation of Hyperspectral 
%Target Detection Algorithm on FPGA Using HLS

%% TESTING

[m, N] = size(M);
num_bands = m;

outsize = 64;
insize = 16;
matrices = 4;

beta = 2^60;
G_1 = (beta) * eye(num_bands, num_bands);
G_2 = (beta) * eye(num_bands, num_bands);
G_3 = (beta) * eye(num_bands, num_bands);
G_4 = (beta) * eye(num_bands, num_bands);


init_pix = 1;
istart = init_pix;
istop = istart + 120;


for i = istart : istop
    bn = mod(i,matrices);
    
    x = M(:,i);
    
    switch bn
        case 0
             G_1 = ShermanMorrison(G_1,x);
        case 1
             G_2 = ShermanMorrison(G_2,x);
        case 2
             G_3 = ShermanMorrison(G_3,x);
        case 3
             G_4 = ShermanMorrison(G_4,x);
    end

end
