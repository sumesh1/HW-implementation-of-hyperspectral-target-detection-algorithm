% created by: Dordije Boskovic

function [results,G] = hyperAceR_RTSM(M, S)
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

    %take a subset of pixels, about 10*p	
	%num = 10*p;
    % or take a subset of pixels, about 0.1% of pixels	
	num = round(0.1*N/100);
	
	results = zeros(1, N);

	R_init = M(:,1:num)*M(:,1:num)';
	G = pinv(R_init);
	
	for k = 1:N
		
		x = M(:,k);
	
        tmp2 = S.'*G;
        tmp = (tmp2*S);
        results(k) = (tmp2*x)^2 / (tmp*(x.'*G*x));
        
        if( k > num)
           G = G - ((G*x)*(x'*G))./(1+x'*G*x);
        end
        
	end

end







