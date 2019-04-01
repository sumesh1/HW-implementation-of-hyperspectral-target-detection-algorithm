%% INITIAL 

[m, n] = size(M);

num_bands = m;
beta = 2^45;

R_inv_init = (beta) * eye(num_bands, num_bands);

init_pix = 1;
istart = init_pix;
istop = istart + 60;

outsize = 64;
insize = 16;

merr = 0;
oldmerr = 0;


%% FIXED POINT

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
    Rx = floor(Rx./2^(insize - 1)); 

    if (any(Rx(:) > 2^(outsize-1) - 1))
        Rx(Rx > 2^(outsize-1)-1) = 2^(outsize-1) - 1;
        cnt1 = cnt1 + 1;
    elseif (any(Rx(:) < -2^(outsize-1)))
        Rx(Rx < -2^(outsize-1)) = -2^(outsize-1);
        cnt1 = cnt1 + 1;
    end

    RxxR = Rx * Rx';
    RxxR = floor(RxxR./2^(outsize - 1));

    if (any(RxxR(:) > 2^(outsize-1) - 1))
        RxxR(RxxR > 2^(outsize-1)-1) = 2^(outsize-1) - 1;
        cnt2 = cnt2 + 1;
    elseif (any(RxxR(:) < -2^(outsize-1)))
        RxxR(RxxR < -2^(outsize-1)) = -2^(outsize-1);
        cnt2 = cnt2 + 1;
    end

    d = (u' * Rx)*2^(21+add_frac);
    %d = floor(d/2^(insize + add_frac - 1));

%     if (d > 2^(outsize-1) - 1)
%         d = 2^(outsize-1) - 1;
%         cnt3 = cnt3 + 1;
%     elseif (d < -2^(outsize-1))
%         d = -2^(outsize-1);
%         cnt3 = cnt3 + 1;
%     end

    div = 1 / (d + 1);  %have to scale 1 ??

    T = floor(RxxR*double(div)*2^(63+42));

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
        
    oldmerr = merr;
    err = abs(Anew-TAnew) ./ abs(TAnew);
    merr = vpa(100*mean(err(:)));
    
    fprintf("iteration %d, err = %f, diff = %f \n",i,merr,merr-oldmerr);
  

end

