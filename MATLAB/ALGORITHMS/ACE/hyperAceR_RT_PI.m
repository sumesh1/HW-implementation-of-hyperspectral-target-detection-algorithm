% created by: Dordije Boskovic

function [results] = hyperAceR_RT_PI(M, S)
% HYPERACE Performs the adaptive cosin/coherent estimator algorithm
% DOES NOT EXCLUDE DETECTED PIXELS FROM UPDATED CORRELATION MATRIX
% REAL TIME ALGORITHM IN HW
%
% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
% Outputs
%   results - vector of detector output (N x 1)


	[p, N] = size(M);

	results = zeros(1, N);
	
    R = M(:,1)*M(:,1)';
	G = pinv(R);
    
	for k = 1:N
		
        x = M(:,k);
        tmp = (S.'*G*S);
		results(k) = (S.'*G*x)^2 / (tmp*(x.'*G*x));
        
        if(k~=1)
            R = R + x*x'; %update correlation matrix, no normalization
            G = pinv(R);  %pseudoinverse for first few pixels, later it is same as inverse
        end
		
			
	end

end







