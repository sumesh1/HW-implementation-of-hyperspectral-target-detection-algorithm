
[m, n] = size(M);

num_bands = m;
beta = 2^30;

R_inv_init = (beta) * eye(num_bands, num_bands);

% [R_new]=ShermanMorrison(R_inv_init,M(:,1));
% [R_new_fp]=ShermanMorrison_fp(R_inv_init,M(:,1));

%floating
A = R_inv_init;
u = M(:, 1);

TRx = A * u;
TRxxR = TRx * TRx';
Td = u' * TRx;
Tdiv = 1 / (Td + 1);
TT = TRxxR .* Tdiv;
TAnew = A - TT;


%fp
cnt1 = 0;
cnt2 = 0;
cnt3 = 0;
cnt4 = 0;
cnt5 = 0;
outsize = 32;
insize = 16;

[p, k] = size(A);
add_frac = ceil(log2(p));

typef = numerictype('Signed', true, 'WordLength', 32, ...
    'FractionLength', 30);



a = sfi(1, 2, 0);

Rx = A * u;
Rx = floor(Rx./2^(insize - 1));

if (Rx(:) > 2^31 - 1)
    Rx(Rx > 2^31-1) = 2^31 - 1;
    cnt1 = cnt1 + 1;
elseif (Rx(:) < -2^31)
    Rx(Rx < -2^31) = -2^31;
    cnt1 = cnt1 + 1;
end

RxxR = Rx * Rx';
RxxR = floor(RxxR/2^(outsize - 1));

if (RxxR(:) > 2^31 - 1)
    RxxR(RxxR > 2^31-1) = 2^31 - 1;
    cnt2 = cnt2 + 1;
elseif (RxxR(:) < -2^31)
    RxxR(RxxR < -2^31) = -2^31;
    cnt2 = cnt2 + 1;
end

d = u' * Rx;
d = floor(d/2^(insize - 1 + add_frac));

if (d > 2^31 - 1)
    d = 2^31 - 1;
    cnt3 = cnt3 + 1;
elseif (d < -2^31)
    d = -2^31;
    cnt3 = cnt3 + 1;
end

d2 = sfi(d, outsize, 0);
d2 = d2 + 1;
div2 = divide(typef, a, d2);
div = 1 / (d + 1);

T = floor(RxxR*double(div)*2^(31 - 7));

if (T(:) > 2^31 - 1)
    T(T > 2^31-1) = 2^31 - 1;
    cnt5 = cnt5 + 1;
elseif (T(:) < -2^31)
    T(T < -2^31) = -2^31;
    cnt5 = cnt5 + 1;
end

Anew = A - T;


for i = 2:100
    cnt1 = 0;
    cnt2 = 0;
    cnt3 = 0;
    cnt4 = 0;
    cnt5 = 0;
    
    A = TAnew;
    u = M(:, i);
    TRx = A * u;
    TRxxR = TRx * TRx';
    Td = u' * TRx;
    Tdiv = 1 / (Td + 1);
    TT = TRxxR .* Tdiv;
    TAnew = A - TT;
    
    %fp
    A = Anew;
    Rx = A * u;
    Rx = floor(Rx./2^(insize - 1));
    
    if (Rx(:) > 2^31 - 1)
        Rx(Rx > 2^31-1) = 2^31 - 1;
        cnt1 = cnt1 + 1;
    elseif (Rx(:) < -2^31)
        Rx(Rx < -2^31) = -2^31;
        cnt1 = cnt1 + 1;
    end
    
    RxxR = Rx * Rx';
    RxxR = floor(RxxR);
    
    if (RxxR(:) > 2^31 - 1)
        RxxR(RxxR > 2^31-1) = 2^31 - 1;
        cnt2 = cnt2 + 1;
    elseif (RxxR(:) < -2^31)
        RxxR(RxxR < -2^31) = -2^31;
        cnt2 = cnt2 + 1;
    end
    
    d = u' * Rx;
    d = floor(d/2^(insize - 1 + add_frac));
    
    if (d > 2^31 - 1)
        d = 2^31 - 1;
        cnt3 = cnt3 + 1;
    elseif (d < -2^31)
        d = -2^31;
        cnt3 = cnt3 + 1;
    end
    
    d2 = sfi(d, outsize, 0);
    d2 = d2 + 1;
    div2 = divide(typef, a, d2);
    div = 1 / (d + 1);
    
    
    T = floor(RxxR*double(div)/2^(7));
    
    if (T(:) > 2^31 - 1)
        T(T > 2^31-1) = 2^31 - 1;
        cnt5 = cnt5 + 1;
    elseif (T(:) < -2^31)
        T(T < -2^31) = -2^31;
        cnt5 = cnt5 + 1;
    end
    
    Anew = A - T;
    
    
    %[R_new]=ShermanMorrison(R_new,M(:,i));
    %[R_new_fp]=ShermanMorrison_fp(R_new_fp,M(:,i));
    %log2(div/Tdiv)
    %err = abs(Anew-TAnew) ./ abs(TAnew);
   % merr = vpa(100*mean(err(:)))
end


%true

%R_true = hyperCorr(sc1);
%R_true = sc1*sc1';
%R_true = inv(R_true);

err = abs(Anew-TAnew) ./ abs(TAnew);
merr = vpa(100*mean(err(:)))
