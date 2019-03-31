
[m, n] = size(M);

num_bands = m;
beta = 2^60;


%R_inv_init = (beta) * eye(num_bands, num_bands);

init_pix =500*m;
R=hyperCorr(M(:,1:init_pix));
G=pinv(R);
R_inv_init = G * 2^61;

% [R_new]=ShermanMorrison(R_inv_init,M(:,1));
% [R_new_fp]=ShermanMorrison_fp(R_inv_init,M(:,1));


%% FIXED POINT

outsize = 64;
insize = 16;


%typef = numerictype('Signed', true, 'WordLength', outsize,'FractionLength', outsize-5);

% fixed point number 1 for reciprocal
%a = sfi(1, 2, 0);

merr=0;
oldmerr=0;

t=[];
t2=[];

istart = init_pix + 1;
istop = istart + 120;

for i = istart:istop
 
    cnt1 = 0;
    cnt2 = 0;
    cnt3 = 0;
    cnt4 = 0;
    cnt5 = 0;
   
  %floating point
    if(i==istart)
        A = R_inv_init;
    else
        A = TAnew;
    end
    
  
    u= M(:, i);
   
    
    
    TRx = A * u;
    TRxxR = TRx * TRx';
    Td = u' * TRx;
    Tdiv = 1 / (Td + 1);
    TT = TRxxR .* Tdiv;
    TAnew = A - TT;

    %fixed point
    if(i==istart)
        A = R_inv_init;
    else
        A = Anew;
    end
    [p, k] = size(A);
    add_frac = ceil(log2(p));
    
    Rx = A * u;
    Rx = floor(Rx./2^(insize- 1)); 

    if (any(Rx(:) > 2^(outsize-1) - 1))
        Rx(Rx > 2^(outsize-1)-1) = 2^(outsize-1) - 1;
        cnt1 = cnt1 + 1;
    elseif (any(Rx(:) < -2^(outsize-1)))
        Rx(Rx < -2^(outsize-1)) = -2^(outsize-1);
        cnt1 = cnt1 + 1;
    end

    RxxR = Rx * Rx';
    RxxR = floor(RxxR/2^(outsize - 1));

    if (any(RxxR(:) > 2^(outsize-1) - 1))
        RxxR(RxxR > 2^(outsize-1)-1) = 2^(outsize-1) - 1;
        cnt2 = cnt2 + 1;
    elseif (any(RxxR(:) < -2^(outsize-1)))
        RxxR(RxxR < -2^(outsize-1)) = -2^(outsize-1);
        cnt2 = cnt2 + 1;
    end


    d = u' * Rx;
    d = floor(d/2^(insize + add_frac - 1 ));

    if (d > 2^(outsize-1) - 1)
        d = 2^(outsize-1) - 1;
        cnt3 = cnt3 + 1;
    elseif (d < -2^(outsize-1))
        d = -2^(outsize-1);
        cnt3 = cnt3 + 1;
    end

    d2 = sfi(d, outsize, 0);
    %d2 = d2 + 1;
   % div2 = divide(typef, a, d2);
    div = 1 / (d + 1);

    T = floor(RxxR*double(div)*2^(outsize -add_frac- 1));

    if (any(T(:) > 2^(outsize-1) - 1))
        T(T > 2^(outsize-1)-1) = 2^(outsize-1) - 1;
        cnt5 = cnt5 + 1;
    elseif (any(T(:) < -2^(outsize-1)))
        T(T < -2^(outsize-1)) = -2^(outsize-1);
        cnt5 = cnt5 + 1;
    end

    Anew = A - T;
    
    %checking
    if(cnt1>0 |cnt2>0 |cnt3>0 |cnt4>0 |cnt5>0)
        fprintf("\n overflow \n");
    end
        
    %[R_new]=ShermanMorrison(R_new,M(:,i));
    %[R_new_fp]=ShermanMorrison_fp(R_new_fp,M(:,i));
    %log2(div/Tdiv)
    oldmerr = merr;
    err = abs(Anew-TAnew) ./ abs(TAnew);
    merr = vpa(100*mean(err(:)));
    
    fprintf("iteration %d, err = %f, diff = %f \n",i,merr,merr-oldmerr);
  
    t=[t,Rx(1)];
    t2=[t2,TRx(1)];
end
%figure
%plot(t(102:end-5));
%figure
%plot(t2(102:end-5))



%% ERROR ESTIMATION
%true

%R_true = hyperCorr(sc1);
%R_true = sc1*sc1';
%R_true = inv(R_true);

%err = abs(Anew-TAnew) ./ abs(TAnew);
%merr = vpa(100*mean(err(:)))
