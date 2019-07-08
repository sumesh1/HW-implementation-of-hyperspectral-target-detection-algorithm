% created by: Dordije Boskovic

function [results] = hyperAceRTF(M, G ,sG,sGs)
% HYPERACER Performs the adaptive cosin/coherent estimator algorithm with correlation MATRIX!

% Usage
%   [results] = hyperAceR(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
% Outputs
%   results - vector of detector output (N x 1)

	[~, N] = size(M);


	results = zeros(1, N);
	
	
	for k=1:N
		
		x = M(:,k);
        
        t1 = prod1(sG,x);
        t2 = square1(t1);
        
        t3 = vmp1(x,G);
        t4 = prod3(t3,x);
        
        t5 = prod2(sGs,t4);
        
		results(k) = t2 / t5;    
		
	end

end

function [r] = prod1(a,b)
        r = a*b;
end

function [r] = prod3(a,b)
        r = a*b;
end

function [r] = square1(a)
        r = a*a;
end

function [r] = vmp1(a,b)
        r = a.'*b;
end

function [r] = prod2(a,b)
        r = a*b;
end
