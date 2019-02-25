% created by: Dordije Boskovic

function [Anew] = ShermanMorrison(A,u)

        %d1 = (A*u*u'*A);
        %d2 = (1+u'*A*u);
		%Anew = A - d1./d2;
         
        Rx   = A * u; %2^19
        RxxR = Rx * Rx'; %2^31
        d    = u' * Rx;  %2^19
        div  = 1 / d;
        T    = RxxR .* div;
        Anew = A - T;
        
end