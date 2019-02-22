% from HS toolbox

function [results] = hyperCem_NT(M, S,gt,index)
% HYPERCEM Performs constrained energy minimization (CEM) algorithm
%   Performs the constrained energy minimization algorithm for target
% detection.
%
% Usage
%   [results] = hyperCem(M, target)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   target - target of interest (p x 1)
% Outputs
%   results - vector of detector output (N x 1)
%
% References
%   Qian Du, Hsuan Ren, and Chein-I Cheng. A Comparative Study of 
% Orthogonal Subspace Projection and Constrained Energy Minimization.  
% IEEE TGRS. Volume 41. Number 6. June 2003.


% CEM uses the correlation matrix, NOT the covariance

[p, N] = size(M);

    
    %choose only non target pixels for R
	
   % gt2d = hyperConvert2d(gt);
    gt2d = reshape(gt',[1,numel(gt)]);
    R = 0;
    
    for i = 1:N
       
       if(gt2d(i) ~= index)
         x = M(:,i);  
         R = R + x*x';
       end
        
    end
        
    R = R/N;
    
    G = inv(R);

	results = zeros(1, N);
	
    tmp2 = S.'*G;
	tmp = (tmp2*S);
	
    
	for k=1:N
		
		x = M(:,k);
		results(k) = (tmp2*x) / (tmp);
		
	end

