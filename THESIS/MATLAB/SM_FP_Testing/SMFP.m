%% Initial data DATA
    clc;
    prepare_dataset;
    num_bands  = q;
    num_pixels = size(M,2);
    beta = 10000; 
    word_length = 35;
    pixw_length = 8;
    frac_length = 14;
    acc_length = ceil(log2(num_bands));
    
    num_loops = 2;
    
    R_inv_init    = (beta) * eye(num_bands ,num_bands);
    R_inv_init_fp = sfi(R_inv_init, word_length,frac_length);
    
    
    T1 = numerictype(1,word_length,frac_length);
    T2 = numerictype(1,pixw_length*2,pixw_length);
    
    x    = M(:,1); %one pixel
    x_fp = sfi(x,16,8);
    
    hscope1 = NumericTypeScope;
    
%% True Value
    R_true = M*M'; %not divided by num_pixels
    G_true = inv(R_true);
    
%% Update matrix - floating point once
   
    M_fp  = sfi(M,pixw_length*2,pixw_length);
    M=double(M_fp);
    Rn = R_inv_init;
    div_arr=zeros(1,num_pixels);
    Rx_arr=zeros(num_pixels*num_bands,1);
    
  for i = 1 :  num_loops
    x = M(:,i);     
    Rx   = Rn * x; %2^19
    %Rx_arr((i-1)*num_bands+1:i*num_bands)=Rx;
    
    RxxR = Rx * Rx'; %2^31

    d    = x' * Rx;  %2^19
    %div_arr(i)=d;
    div  = 1/(d+1);
    
    %div_arr=[div_arr,div];
   
    T    = RxxR .* div;

    Rn   = Rn - T;
   
  end
  %step(hscope1,div_arr);
%  
%% Estimate error

err = abs(Rn-G_true)./G_true;
err_mean = mean(abs(err(:)))*100
    
    
%% Update matrix - fixed point once
   
    %M_fp  = sfi(M,16,0);
    Rn_fp = R_inv_init_fp;
    
  for i = 1 :  num_loops
   x_fp    = M_fp(:,i); %one pixel
  
    Rx_fp   = Rn_fp * x_fp; %2^21
    Rx_fp   = bitsliceget(Rx_fp,Rx_fp.WordLength- pixw_length- acc_length,Rx_fp.WordLength- word_length - acc_length-pixw_length+1);
    Rx_fp   = reinterpretcast(Rx_fp, T1);
    
    T3      = numerictype(1, word_length, -((word_length-frac_length)*2-word_length-1));
    RxxR_fp = Rx_fp * Rx_fp'; %2^31
    RxxR_fp = bitsliceget(RxxR_fp,RxxR_fp.WordLength- 1,RxxR_fp.WordLength- word_length);
    RxxR_fp = reinterpretcast(RxxR_fp, T3);
     
    T3      = numerictype(1, word_length, 2);
    d_fp    = x_fp'*Rx_fp;  %2^19
    d_fp    = bitsliceget(d_fp,d_fp.WordLength- 1,d_fp.WordLength- word_length);
    d_fp    = reinterpretcast(d_fp, T3);
    
    div_fp  = 1/(double(d_fp)+1);
    div_fp  = sfi(div_fp, word_length,32);
   
%     T3      = numerictype(1, word_length, -5);
%     T_fp    = RxxR_fp .* div_fp;
%     T_fp    = bitsliceget(T_fp,T_fp.WordLength -3- 1,T_fp.WordLength- word_length-3);
%     T_fp    = reinterpretcast(T_fp, T3);

    T3      = numerictype(1, word_length, 3);
    T_fp    = RxxR_fp .* div_fp;
    T_fp    = bitsliceget(T_fp,T_fp.WordLength -3-8- 1,T_fp.WordLength- word_length-3-8);
    T_fp    = reinterpretcast(T_fp, T3);

     
    Rn_fp   = Rn_fp - T_fp;
    Rn_fp   = bitsliceget(Rn_fp,Rn_fp.WordLength-12,Rn_fp.WordLength- 11-word_length );
    Rn_fp   = reinterpretcast(Rn_fp, T1);
  end
  

    
  
%% Estimate error

err = abs(double(Rn_fp)-G_true)./G_true;
err_mean = mean(abs(err(:)))*100

%% Estimate error

err = abs(double(Rn_fp)-Rn);
err_mean = mean(abs(err(:)))*100   
     
