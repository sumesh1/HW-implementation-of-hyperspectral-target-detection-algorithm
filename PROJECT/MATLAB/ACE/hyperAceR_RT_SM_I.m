% created by: Dordije Boskovic

function [results,G] = hyperAceR_RT_SM_I(M, S, beta)
% HYPERACE Performs the adaptive cosin/coherent estimator algorithm
% DOES NOT EXCLUDE DETECTED PIXELS FROM UPDATED CORRELATION MATRIX
% REAL TIME ALGORITHM IN HW using Sherman Morrison and initial
% pseudoinverse
%
% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
% Outputs
%   results - vector of detector output (N x 1)
%   G - final inverse correlation matrix

    if(nargin < 3)
        beta = 10000;
    end

    [p, N] = size(M);

	G = beta*eye(p,p);

	results = zeros(1, N);
	
	for k = 1:N
		
		x = M(:,k);
	
        %update matrix 
        G = G - (G*x*x'*G)./(1+x'*G*x);

        tmp = (S.'*G*S);
        results(k) = (S.'*G*x)^2 / (tmp*(x.'*G*x));
			
    end
    
        
%restream data
%     for k = 1:(N/100)
% 
%         x = M(:,k);
% 
%         %calculate detection statistic
%         tmp2 = S.'*G;
%         tmp = (tmp2*S);
%         results(k) = (tmp2*x)^2 / (tmp*(x.'*G*x));
%
%     end
    
  

end







