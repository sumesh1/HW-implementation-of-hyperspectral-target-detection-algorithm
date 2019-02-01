function [result] = hyperRXR(M)
%HYPERRX RX anomaly detector
%   hyperRxDetector performs the RX anomaly detector
%
% Usage
%   [result] = hyperRxDetector(M)
% Inputs
%   M  - 2D data matrix (p x N)
% Outputs
%   result - Detector output (1 x N)
%   sigma - Covariance matrix (p x p)
%   sigmaInv - Inverse of covariance matrix (p x p)

% Remove the data mean
[p, N] = size(M);

% Compute covariance matrix
R = hyperCorr(M);
G = inv(R);

result = zeros(N, 1);

for i=1:N
    
    result(i) = M(:,i)'*G*M(:,i);
    
end

%result = abs(result);

return;