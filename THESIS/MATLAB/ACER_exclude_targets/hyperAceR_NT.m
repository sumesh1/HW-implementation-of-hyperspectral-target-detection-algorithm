% created by: Dordije Boskovic

function [results] = hyperAceR_NT(M,S,gt,value)
% HYPERACER Performs the adaptive cosin/coherent estimator algorithm with correlation MATRIX!

% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
% Outputs
%   results - vector of detector output (N x 1)

	[p, N] = size(M);

    
    %choose only non target pixels for R
	
    gt2d = hyperConvert2d(gt);
    
    R = 0;
    
    for i = 1:N
       
       if(gt2d(i) ~= value)
         x = M(:,i);  
         R = R + x*x';
       end
        
    end
        
    R = R/N;
    
    G=inv(R);

	results = zeros(1, N);
	
	tmp = (S.'*G*S);
	
	for k=1:N
		
		x = M(:,k);
		results(k) = (S.'*G*x)^2 / (tmp*(x.'*G*x));
		
	end

end
