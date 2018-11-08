% from HS toolbox

function [results] = hyperAce(M, S)
% HYPERACE Performs the adaptive cosin/coherent estimator algorithm
%   Performs the adaptive cosin/coherent estimator algorithm for target
% detection.
%
% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
% Outputs
%   results - vector of detector output (N x 1)
%
% References
%   X Jin, S Paswater, H Cline.  "A Comparative Study of Target Detection
% Algorithms for Hyperspectral Imagery."  SPIE Algorithms and Technologies
% for Multispectral, Hyperspectral, and Ultraspectral Imagery XV.  Vol
% 7334.  2009.


	[p, N] = size(M);
% Remove mean from data
	u = mean(M.').';
	M = M - repmat(u, 1, N);
	S = S - repmat(u, 1, size(S,2));

	R_hat = hyperCov(M);
	G = inv(R_hat);

	results = zeros(1, N);
	tmp = (S.'*G*S);
	
	for k=1:N
		x = M(:,k);
		results(k) = (S.'*G*x)^2 / (tmp*(x.'*G*x));
	end

end
