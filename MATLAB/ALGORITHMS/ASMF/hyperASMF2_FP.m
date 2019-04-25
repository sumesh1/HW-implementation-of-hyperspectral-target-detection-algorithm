% created by: Dordije Boskovic

function [results,overflows] = hyperASMF2_FP(M,S,pixbw,brambw,outbw)
%% Description:
% HYPERACER Performs the adaptive cosin/coherent estimator algorithm with correlation MATRIX!
% THIS FUNCTION IS USED FOR FIXED POINT ERROR ESTIMATION

%% inputs and outputs:
%  results - output detection statistics
%  overflows - any overflows happening
%  M - hyperspectral cube
%  S - target signature
%  pixbw, brambw, outbw - bit widths for fixed point implementation

%% function

if (nargin < 3)
    pixbw  = 16;
    brambw = 32;
    outbw  = 32;
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

%correlation matrix
R = hyperCorr(M);

%inverted R
G = inv(R);

%% start Fixed point conversion from here, prepare

%convert G
max1 = max(G(:));
min1 = min(G(:));

p1 = abs(floor(2^(brambw-1)/max1));
p2 = abs(floor(2^(brambw-1)/min1));

if(p1>p2)
    p1 = p2;
end

p1 = floor(log2(p1));
shift = 2^p1;
fprintf("G shifted by %d \n",int32(p1));
Gfp = floor(G.*shift);


%convert vector sG
sG = S' * G;

max1 = max(sG(:));
min1 = min(sG(:));

p1 = abs(floor(2^(brambw-1)/max1));
p2 = abs(floor(2^(brambw-1)/min1));

if(p1>p2)
    p1 = p2;
end

p1 = floor(log2(p1));
shift = 2^p1;
fprintf("sG shifted by %d \n",int32(p1));
sGfp = floor(sG .* shift);


%convert value sGs
sGs = (S.' * G * S);

p1 = abs(floor(2^(brambw-1)/sGs));
p1 = floor(log2(p1));
shift = 2^p1;
fprintf("sGs shifted by %d \n",int32(p1));
sGsfp = floor(sGs .* shift);


%% start calculation 
results = zeros(1, N);

%number of oveflows
cnt1 = 0; 
cnt2 = 0;  
cnt3 = 0;  
cnt4 = 0;  
cnt5 = 0;

%division type
T = numerictype('Signed', true, 'WordLength', outbw, ...
    'FractionLength', outbw-2);

a = sfi(1, 2, 0);

for k = 1:N
    
    x = M(:, k);
    
    t1 = x' * Gfp;
    %truncation of t1 can be adjusted according to the scene
    %by default it is 2^(pixbw+add_frac-1).
    %it has most impact on the result
   % t1 = floor(t1./2^(pixbw+add_frac -1));  
   t1 = floor(t1./2^(pixbw -1));   
    if (any(t1(:) > 2^(outbw-1) - 1))
        t1(t1>2^(outbw-1)-1) = 2^(outbw-1)-1;
        cnt1 = cnt1 + 1;
    elseif (any(t1(:) < -2^(outbw-1)))
        t1(t1<-2^(outbw-1)) = -2^(outbw-1);
        cnt1 = cnt1 + 1;
    end
    
    t2 = ( t1 * x).^2;
  %  t2 = floor(t2./2^(outbw+add_frac+5-1));
  t2 = floor(t2./2^(outbw-1));
    if (t2 > 2^(outbw-1) - 1)
        t2 = 2^(outbw-1) - 1;
        cnt2 = cnt2 + 1;
    elseif (t2 < -2^(outbw-1))
        t2 = -2^(outbw-1);
        cnt2 = cnt2 + 1;
    end
    
    
    sGx = sGfp * x;
   % sGx = floor(sGx./2^(pixbw+add_frac-1));
   sGx = floor(sGx./2^(pixbw-1));
    if (sGx > 2^(outbw-1) - 1)
        sGx = 2^(outbw-1) - 1;
        cnt3 = cnt3 + 1;
    elseif (sGx < -2^(outbw-1))
        sGx = -2^(outbw-1);
        cnt3 = cnt3 + 1;
    end
    
    
    sGx2 = sGx * sGx;
    sGx2 = floor(sGx2./2^(outbw-1-5));
    if (sGx2 > 2^(outbw-1) - 1)
        sGx2 = 2^(outbw-1) - 1;
        cnt4 = cnt4 + 1;
    elseif (sGx2 < -2^(outbw-1))
        sGx2 = -2^(outbw-1);
        cnt4 = cnt4 + 1;
    end
    
    sGx3 = sGx * sGx2;
    sGx3 = floor(sGx3./2^(outbw-1));
    if (sGx3 > 2^(outbw-1) - 1)
        sGx3 = 2^(outbw-1) - 1;
        cnt4 = cnt4 + 1;
    elseif (sGx3 < -2^(outbw-1))
        sGx3 = -2^(outbw-1);
        cnt4 = cnt4 + 1;
    end
    
    
    d2 = sGsfp * t2;
    d2 = floor(d2./2^(outbw-1));
    if (d2 > 2^(outbw-1) - 1)
        d2 = 2^(outbw-1) - 1;
        cnt5 = cnt5 + 1;
    elseif (d2 < -2^(outbw-1))
        d2 = -2^(outbw-1);
        cnt5 = cnt5 + 1;
    end
    
    
%% intger division, slow
%     d2 = sfi(d2, outbw, 0);
%     sGx2 = sfi(sGx2, outbw, 0);
%     c = divide(T, a, d2);
% 
%     results(k) = double(sGx2*c);



%% not integer division, fast
    results(k) = sGx3/d2;
    
end

overflows = [cnt1,cnt2,cnt3,cnt4,cnt5];

end
