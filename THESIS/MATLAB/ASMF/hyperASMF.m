% by Dordije Boskovic

function [results] = hyperASMF(M, target,n)
%
% Usage
%   [results] = hyperASMF(M, target)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   target - target of interest (p x 1)
% Outputs
%   results - vector of detector output (N x 1)
%
% References
%  Adjusted Spectral Matched Filter for Target Detection in Hyperspectral
% imagery, Remote Sens. 2015

% Check dimensions
if ndims(M) ~= 2
    error('Input image must be p x N.');
end

[p,N] = size(M);

if ~isequal(size(target), [p,1])
    error('Input target must be p x 1.');
end

% ASMF has the weight n, by default =1

if nargin == 2 
    n = 1; 
end

% ASMF uses the correlation matrix, NOT the covariance matrix. Therefore,
% don't remove the mean from the data.

R = hyperCorr(M);
G = inv(R);

t1 = G*target;
t2 = target'*t1;

	for k = 1:N
		
		x = M(:,k);
        t3 = x'*t1;
		results(k) = (t3/t2) * (abs(t3/(x'*G*x)))^n ;
		
	end



