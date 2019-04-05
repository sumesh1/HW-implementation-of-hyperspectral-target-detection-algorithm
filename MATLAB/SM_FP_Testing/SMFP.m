%% Initial data DATA
    clc;
   % prepare_dataset;
    
    M = -2^5 + 2*(2^5-1).*rand(50,50^2);
    q =50;
    num_loops = 50^2;
    
    num_bands  = q;
    num_pixels = size(M,2);
    
    beta = 10000; 
    word_length  = 64;
    pixw_length  = 16;
    pfrac_length = 10;
    wfrac_length = 42;
    acc_length = ceil(log2(num_bands));
    
    %make it fit to pixw bits with frac_length
   % divider = max(M(:))/31;
   % M    = M/divider;
    M_fp = sfi(M,pixw_length,pfrac_length);
    
    fprintf('\n after treatment: \n');
    fprintf('max value in cube: %f \n' ,max(M(:)));
    fprintf('min value in cube: %f \n' ,min(M(:)));
    fprintf('mean value in cube: %f \n',mean(M(:)));
    
    R_inv_init    = (beta) * eye(num_bands ,num_bands);
    R_inv_init_fp = sfi(R_inv_init, word_length, wfrac_length);
     
    T1 = numerictype(1,word_length,wfrac_length);
    T2 = numerictype(1,pixw_length,pfrac_length);
    
    oldmerr = 0;
    merr    = 0;
   
    %hscope1 = NumericTypeScope;
    
%% True Value
    R_true = M*M'; %not divided by num_pixels
    G_true = inv(R_true);
    
%% Create matrix
  
    M       = double(M_fp);
    Rn      = R_inv_init;
    Rn_fp   = R_inv_init_fp;
    
    Tk=[];
%% ITERATIONS
  for i = 1 :  num_loops      
%% FLOATING POINT  
    x = M(:,i); 
    
    Rx   = Rn * x; 
    RxxR = Rx * Rx'; 
    d    = x' * Rx;  
    div  = 1/(d+1);
    T    = RxxR .* div;
    Rn   = Rn - T;
    
    %% FIXED POINT
    
    x_fp    = M_fp(:,i); %one pixel
  
    Rx_fp   = Rn_fp * x_fp; 
    Rx_fp    = bitsliceget(Rx_fp,Rx_fp.WordLength -(Rx_fp.WordLength-Rx_fp.FractionLength - (word_length-wfrac_length)) ,...
               Rx_fp.WordLength -(Rx_fp.WordLength-Rx_fp.FractionLength - (word_length-wfrac_length)) - (word_length-1));
    Rx_fp    = reinterpretcast(Rx_fp, T1);
   
    RxxR_fp = Rx_fp * Rx_fp';
    if(i<=num_bands)
        RxxR_fp = bitsliceget(RxxR_fp,RxxR_fp.WordLength - 1 ,...
                RxxR_fp.WordLength - (word_length));     
        T4 = numerictype(1,word_length,21);                
        RxxR_fp = reinterpretcast(RxxR_fp, T4);     
    else
        RxxR_fp =  bitsliceget(RxxR_fp,RxxR_fp.WordLength -(RxxR_fp.WordLength-RxxR_fp.FractionLength - (word_length-wfrac_length)) ,...
                   RxxR_fp.WordLength -(RxxR_fp.WordLength-RxxR_fp.FractionLength - (word_length-wfrac_length)) - (word_length-1));    
        T4 = numerictype(1,word_length,wfrac_length);                
        RxxR_fp = reinterpretcast(RxxR_fp, T4);      
    end
     
     
     
    d_fp    = x_fp' * Rx_fp;
    if(i<=num_bands)
        d_fp = bitsliceget(d_fp,d_fp.WordLength - 1 ,...
                  d_fp.WordLength - (word_length));     
        T4 = numerictype(1,word_length,31);                
        d_fp = reinterpretcast(d_fp, T4);
    else
        d_fp = bitsliceget(d_fp,d_fp.WordLength -(d_fp.WordLength-d_fp.FractionLength - (word_length-wfrac_length)) ,...
                   d_fp.WordLength -(d_fp.WordLength-d_fp.FractionLength - (word_length-wfrac_length)) - (word_length-1));   
        T4 = numerictype(1,word_length,wfrac_length);                
        d_fp = reinterpretcast(d_fp, T4);
    end

    div_fp  = 1/(double(d_fp)+1);
    div_fp  = sfi(div_fp, word_length,word_length-1);
   
    T_fp    = RxxR_fp .* div_fp;
    Tk=[Tk,T_fp(1)];
    if(i<=num_bands)
         T_fp    = bitsliceget(T_fp,T_fp.WordLength -(T_fp.WordLength-T_fp.FractionLength - (word_length-wfrac_length)) ,...
             T_fp.WordLength -(T_fp.WordLength-T_fp.FractionLength - (word_length-wfrac_length)) - (word_length-1));
         T_fp    = reinterpretcast(T_fp, T1);
    else
         T_fp    = bitsliceget(T_fp,T_fp.WordLength -(T_fp.WordLength-T_fp.FractionLength - (word_length-wfrac_length)) ,...
             T_fp.WordLength -(T_fp.WordLength-T_fp.FractionLength - (word_length-wfrac_length)) - (word_length-1));
         T4 = numerictype(1,word_length,wfrac_length);      
         T_fp    = reinterpretcast(T_fp, T1);
    end
    

     
    Rn_fp   = Rn_fp - T_fp;
    Rn_fp   = bitsliceget(Rn_fp,Rn_fp.WordLength-1);
    Rn_fp   = reinterpretcast(Rn_fp, T1);

    if(i==33 |i==48 |i==50 |i==51 |i==55|i==65)
        disp('7');
    end
     if(i==1200)
        disp('7');
    end
    
   %% Estimate error 
    oldmerr = merr;
    err = abs(double(Rn_fp)-Rn) ./ abs(Rn);
    merr = vpa(100*mean(err(:)));
    
    fprintf("iteration %d, err = %f, diff = %f \n",i,merr,merr-oldmerr);
    
  end
%  
% %% Estimate error
% 
% err = abs(Rn-G_true)./G_true;
% err_mean = mean(abs(err(:)))*100
%       
% %% Estimate error
% 
% err = abs(double(Rn_fp)-G_true)./G_true;
% err_mean = mean(abs(err(:)))*100
% 
% %% Estimate error
% 
% err = abs(double(Rn_fp)-Rn);
% err_mean = mean(abs(err(:)))*100   
     
