% created by: Dordije Boskovic

function [results,G] = hyperAceR_RT_SM_PI(M, S, num)
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
%   num -initial number of pixels for pseudoinverse
% Outputs
%   results - vector of detector output (N x 1)
%   G - final inverse correlation matrix


	[p, N] = size(M);

    if(nargin<3)  
         num = round(0.1*N/100);
    end

    results = zeros(1, N);

    R_init = M(:,1:num)*M(:,1:num)';
    G = pinv(R_init);

    for k = 1:N

        x = M(:,k);

        if( k> num)
            G = G - (G*x*x'*G)./(1+x'*G*x);
        end

            tmp = (S.'*G*S);
            results(k) = (S.'*G*x)^2 / (tmp*(x.'*G*x));

     end
    
  

end







