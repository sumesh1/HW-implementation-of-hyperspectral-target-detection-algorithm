function [M_new,A] = GreenMNF(M)

% Input   M: data set M is a hyperpsectral datacube.
% Output  M_new: 3D basis cube
%         A: Transformation matrix

[h,w,d] = size(M);
M = transpose(hyperConvert2d(M));
[m, n] = size(M);

% 1. Estimate the covariance of the noise.
dX = zeros(m-1,n);
for i=1:(m-1)
    dX(i,:) = M(i,:) - M(i+1,:);
end

% Take the eigenvector expansion of the covariance of dX
[U1,S1,V1] = svd(dX'*dX);

% Whiten the original data
wX = M*U1*inv(sqrt(S1));

% Compute the eigenvector expansion of the covariance of wX
[U2,S2,V2] = svd(wX'*wX);

% Define transformation matrix
A = U1*inv(sqrt(S1))*V2;

% Compute the Maximum noise fraction basis vectors
M_new = M*A;
A = A';
M_new = hyperConvert3d(M_new',h,w,d);