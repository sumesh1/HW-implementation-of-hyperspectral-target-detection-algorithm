% created by: Dordije Boskovic

function [results] = hyperAceR_FP(M, S)
% HYPERACER Performs the adaptive cosin/coherent estimator algorithm with correlation MATRIX!

% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
% Outputs
%   results - vector of detector output (N x 1)

	[p, N] = size(M);

	R = hyperCorr(M);
	G = inv(R);

 %start Fixed point conversion from here
 
    G = int32(G*2^16); 
    S = int32(S*2^16);
    G = double (G);
    S = double (S);
	results = zeros(1, N);
	
	tmp = (S.'*G*S);
	
	for k=1:N
		
		x = M(:,k);
		results(k) = (S.'*G*x)^2 / (tmp*(x.'*G*x));
		
	end

end
