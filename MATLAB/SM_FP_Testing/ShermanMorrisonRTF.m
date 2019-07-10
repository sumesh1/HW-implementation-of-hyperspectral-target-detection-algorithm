%used for fixed point designer

function [Anew] = ShermanMorrisonRTF(A,u)

%A-previously inverted matrix
%Correction uv^T correction


    TRx = A * u;
    TRxxR = TRx * TRx';
    Td = u' * TRx;
    Tdiv = 1 / (Td +1);
    TT = TRxxR .* Tdiv;
    Anew = A - TT;

end