% created by: Dordije Boskovic

function [results,mapexcluded] = hyperAceR_NT(M,S,gt,index)
% HYPERACER Performs the adaptive cosin/coherent estimator algorithm with correlation MATRIX!

% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
% Outputs
%   results - vector of detector output (N x 1)

	[p, N] = size(M);

    
    %choose only non target pixels for R
	
    %gt2d = hyperConvert2d(gt);
    gt2d = reshape(gt',[1,numel(gt)]);
    R = 0;
    mapexcluded = zeros(1,N);
    
    for i = 1:N
       
       if(gt2d(i) ~= index)
         x = M(:,i);  
         R = R + x*x';
       else
            mapexcluded(i) = 1;
       end
        
    end
        
    R = R/N;
    
    G = inv(R);

	results = zeros(1, N);
	
    tmp2 = S.'*G;
	tmp = (tmp2*S);
	
    
	for k=1:N
		
		x = M(:,k);
		results(k) = (tmp2*x)^2 / (tmp*(x.'*G*x));
		
	end

end
