% created by: Dordije Boskovic

function [results] = hyperAceR_FP(M, S)
% HYPERACER Performs the adaptive cosin/coherent estimator algorithm with correlation MATRIX!

% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
% Outputs
%   results - vector of detector output (N x 1)

outsize = 32;
insize = 16;
%T1 = numerictype(1,outsize,31);
[p, N] = size(M);

if (max(M(:)) > 2^15)
    M = M / 2;
end

M = floor(M);

add_frac = ceil(log2(p));
R = hyperCorr(M);
G = inv(R);

%start Fixed point conversion from here

%Gfp = sfi(G,32);
Gfp = floor(G*2^39);

sG = S' * G;
%sGfp = sfi(sG,32);
sGfp = floor(sG*2^39);

tmp = (S.' * G * S);
%tmpfp= sfi(tmp,32);
tmpfp = floor(tmp*2^28);

results = zeros(1, N);

%number of oveflows
cnt1 = 0; 
cnt2 = 0;  
cnt3 = 0;  
cnt4 = 0;  
cnt5 = 0;

%division type
T = numerictype('Signed', true, 'WordLength', 32, ...
    'FractionLength', 30);

a = sfi(1, 2, 0);

for k = 1:N
    
    x = M(:, k);
    
    t1 = x' * Gfp;
   % t1 = floor(t1./2^(insize-1+add_frac));
    t1 = floor(t1);
    if (t1(:) > 2^31 - 1)
        t1(t1>2^31-1)=2^31-1;
        cnt1 = cnt1 + 1;
    elseif (t1(:) < -2^31)
        t1(t1<-2^31)=-2^31;
        cnt1 = cnt1 + 1;
    end
    
    t2 = t1 * x;
    t2 = floor(t2./2^(insize-1+add_frac));
    if (t2 > 2^31 - 1)
        t2 = 2^31 - 1;
        cnt2 = cnt2 + 1;
    elseif (t2 < -2^31)
        t2 = -2^31;
        cnt2 = cnt2 + 1;
    end
    
    
    sGx = sGfp * x;
    sGx = floor(sGx./2^(insize-1+add_frac));
    if (sGx > 2^31 - 1)
        sGx = 2^31 - 1;
        cnt3 = cnt3 + 1;
    elseif (sGx < -2^31)
        sGx = -2^31;
        cnt3 = cnt3 + 1;
    end
    
    
    sGx2 = sGx * sGx;
    sGx2 = floor(sGx2./2^(outsize-1));
    if (sGx2 > 2^31 - 1)
        sGx2 = 2^31 - 1;
        cnt4 = cnt4 + 1;
    elseif (sGx2 < -2^31)
        sGx2 = -2^31;
        cnt4 = cnt4 + 1;
    end
    
    
    d2 = tmpfp * t2;
    d2 = floor(d2./2^(outsize-1));
    if (d2 > 2^31 - 1)
        d2 = 2^31 - 1;
        cnt5 = cnt5 + 1;
    elseif (d2 < -2^31)
        d2 = -2^31;
        cnt5 = cnt5 + 1;
    end
    
%     d2 = sfi(d2, 32, 0);
%     sGx2 = sfi(sGx2, 32, 0);
%     c = divide(T, a, d2);
%   
%     results(k) = double(sGx2*c);
      results(k) = sGx2/d2;
    
end

end
