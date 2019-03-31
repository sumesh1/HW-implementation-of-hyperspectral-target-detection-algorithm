% created by: Dordije Boskovic

function [results,overflows,G] = hyperAceR_RT_SM_FP(M, S,pixbw,brambw,outbw,beta)
%% Description:
% HYPERACER RT SM FP Performs the adaptive cosine/coherent estimator algorithm with correlation MATRIX
% and sherman morrison updating
% THIS FUNCTION IS USED FOR FIXED POINT ERROR ESTIMATION

%% inputs and outputs:
%  results - output detection statistics
%  overflows - any overflows happening
%  G - final matrix 
%  M - hyperspectral cube
%  S - target signature
%  pixbw, brambw, outbw - bit widths for fixed point implementation
%  beta-initial matrix diagonal values

if (nargin < 3)
    pixbw  = 16;
    brambw = 32;
    outbw  = 32;
    beta = 2^(brambw-2);
end

[p, N] = size(M);

if (pixbw == 16)
    M = int16(M);
    M = double(M);
elseif(pixbw == 32)
    M = int32(M);
    M = double(M);  
end

%accumulator added bit width
add_frac = ceil(log2(p));

%initial inverse
R_inv_init = beta*eye(p,p);

cnt1=0;
cnt2=0;
cnt3=0;  
cnt4=0;
cnt5=0;	
results = zeros(1, N);

for k = 1:N

      
    x = M(:,k);
    u = x;

    if(k==1)
        A = R_inv_init;
    else
        A = Anew;
    end

    Rx = A * u;
    Rx = floor(Rx./2^(pixbw + add_frac- 1)); 

    if (any(Rx(:) > 2^(outbw-1) - 1))
        Rx(Rx > 2^(outbw-1)-1) = 2^(outbw-1) - 1;
        cnt1 = cnt1 + 1;
    elseif (any(Rx(:) < -2^(outbw-1)))
        Rx(Rx < -2^(outbw-1)) = -2^(outbw-1);
        cnt1 = cnt1 + 1;
    end

    RxxR = Rx * Rx';
    RxxR = floor(RxxR/2^(outbw - 1));

    if (any(RxxR(:) > 2^(outbw-1) - 1))
        RxxR(RxxR > 2^(outbw-1)-1) = 2^(outbw-1) - 1;
        cnt2 = cnt2 + 1;
    elseif (any(RxxR(:) < -2^(outbw-1)))
        RxxR(RxxR < -2^(outbw-1)) = -2^(outbw-1);
        cnt2 = cnt2 + 1;
    end


    d = u' * Rx;
    d = floor(d/2^(pixbw + add_frac - 1 ));

    if (d > 2^(outbw-1) - 1)
        d = 2^(outbw-1) - 1;
        cnt3 = cnt3 + 1;
    elseif (d < -2^(outbw-1))
        d = -2^(outbw-1);
        cnt3 = cnt3 + 1;
    end

   % d2 = sfi(d, outbw, 0);
   % d2 = d2 + 1;
   % div2 = divide(typef, a, d2);
    div = 1 / (d + 1);

    T = (RxxR*double(div)*2^(outbw -add_frac- 1));

    if (any(T(:) > 2^(outbw-1) - 1))
        T(T > 2^(outbw-1)-1) = 2^(outbw-1) - 1;
        cnt5 = cnt5 + 1;
    elseif (any(T(:) < -2^(outbw-1)))
        T(T < -2^(outbw-1)) = -2^(outbw-1);
        cnt5 = cnt5 + 1;
    end

    Anew = A - T;
    G = Anew;
   
    
    tmp = (S.'*G*S);
    results(k) = (S.'*G*x)^2 / (tmp*(x.'*G*x));

end

    overflows = [cnt1,cnt2,cnt3,cnt4,cnt5];
 
%% restream   
  tmp = (S.'*G*S);
  
for k = 1:N/2

    x = M(:,k);
   
    results(k) = (S.'*G*x)^2 / (tmp*(x.'*G*x));

end

end







