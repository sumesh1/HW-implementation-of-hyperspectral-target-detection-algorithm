% created by: Dordije Boskovic

function [results] = hyperAceR_tst(M, G, S)
% HYPERACER Performs the adaptive cosin/coherent estimator algorithm with correlation MATRIX!

% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
% Outputs
%   results - vector of detector output (N x 1)

	[p, N] = size(M);

	results = zeros(1, N);
	
    tmp2 = (S.'*G);
	tmp = (S.'*G*S);
	
	for k=1:N
		
		x = M(:,k);
		results(k) = (tmp2*x)^2 / (tmp*(x.'*G*x));
		
	end

end
