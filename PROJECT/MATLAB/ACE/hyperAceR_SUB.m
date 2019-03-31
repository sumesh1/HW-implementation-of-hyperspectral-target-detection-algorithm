% created by: Dordije Boskovic

function [results] = hyperAceR_SUB(M, S, percent)
% HYPERACER Performs the adaptive cosine/coherent estimator algorithm 
% with correlation matrix using subset of rows/columns

% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
% Outputs
%   results - vector of detector output (N x 1)

if (nargin < 3)
   percent = 1;
end

	[p, N] = size(M);

	divisor = floor(percent*N/100);
	jump = floor(100/percent);
	
	R = (M(:,1:jump:end)*M(:,1:jump:end)')./divisor;
    G=inv(R);

	results = zeros(1, N);
	
	tmp1 = S.'*G;
	tmp = (tmp1*S);
	
	for k=1:N
		
		x = M(:,k);
		results(k) = (tmp1*x)^2 / (tmp*(x.'*G*x));
		
	end

end
