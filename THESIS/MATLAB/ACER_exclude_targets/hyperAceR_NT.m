% created by: Dordije Boskovic

function [results,mapexcluded] = hyperAceR_NT(M,S,gt,index)

%% INFO
% HYPERACER Performs the adaptive cosine/coherent estimator algorithm 
% using correlation matrix formed of non-target pixels
% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
%   gt - groundtruth
%   index - corresponding gt number to S
% Outputs
%   results - vector of detector output (N x 1)
%   mapexcluded - map of excluded pixels from R

%% ALG
	[p, N] = size(M);

    %choose only non target pixels for R
    gt2d = reshape(gt',[1,numel(gt)]);
    R = 0;
    mapexcluded = zeros(1,N);
    
    %create matrix R
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
	
    %calculate AceR
	for k=1:N
		
		x = M(:,k);
		results(k) = (tmp2*x)^2 / (tmp*(x.'*G*x));
		
	end

end
