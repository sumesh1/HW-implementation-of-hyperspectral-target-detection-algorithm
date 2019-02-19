%% Initial data DATA
    clear all; clc;
    num_bands = 5;
    beta = 10000; 

    R_inv_init    = (beta) * eye(num_bands ,num_bands);
    R_inv_init_fp = sfi(R_inv_init,32);

    %x    = M(:,1); %one pixel
    x = (250:10:290)';
    x_fp = sfi(x,16);
    
%% Update matrix - floating point once
    
  
    Rx   = R_inv_init * x; %2^19
    RxxR = Rx * Rx'; %2^31

    d    = x' * Rx;  %2^19
    div  = 1/(d+1);
    T    = RxxR .* div;

    Rn   = R_inv_init - T;
    
    
    
%% Update matrix - fixed point once
    
  
    Rx_fp   = R_inv_init_fp * x_fp; %2^19
    RxxR_fp = Rx_fp * Rx_fp'; %2^31

    d_fp    = x_fp'*Rx_fp;  %2^19
    div_fp  = 1/(d_fp+1);
   % a   = fi(div, 1, 39, 31);
    T_fp    = RxxR_fp .* div_fp;

    Rn_fp   = R_inv_init_fp - T_fp;
