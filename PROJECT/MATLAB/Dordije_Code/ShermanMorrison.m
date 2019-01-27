% created by: Dordije Boskovic

function [Anew]=ShermanMorrison(A,u,v,neg)

%A-previously inverted matrix
%Correction uv^T correction

	if(neg)
		Anew = A - (A*u*v'*A)./(-1+v'*A*u);
	else
		Anew = A - (A*u*v'*A)./(1+v'*A*u);
	end
	
end