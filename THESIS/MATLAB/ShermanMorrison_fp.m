% created by: Dordije Boskovic

function [Anew]=ShermanMorrison_fp(A,u,v,neg)

%A-previously inverted matrix
%Correction uv^T correction

	if(neg)
		Anew = A - (A*u*v'*A)./(-1+v'*A*u);
    else
        
        Rx = floor(A*u/2^19);
        RxxR = floor(Rx*Rx'/2^31);
        
        d = (u'*Rx/2^19);
        div = 1/(d+1);
        
        T= RxxR * div;
        
        Anew = A - T;
    
    end
	
end