% created by: Dordije Boskovic

function [Anew] = ShermanMorrison_fp(A, u, v, neg)

%A-previously inverted matrix
%Correction uv^T correction

if (nargin <= 2)
    v = u;
    neg = 0;
end

outsize = 32;
insize = 16;

[p, k] = size(A);
add_frac = ceil(log2(p));

T = numerictype('Signed', true, 'WordLength', 32, ...
    'FractionLength', 30);



a = sfi(1, 2, 0);

%number of oveflows
cnt1 = 0;
cnt2 = 0;
cnt3 = 0;
cnt4 = 0;
cnt5 = 0;

if (neg)
    Anew = A - (A * u * v' * A) ./ (-1 + v' * A * u);
else
    
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
    div2 = divide(T, a, d2);
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
    
end

end