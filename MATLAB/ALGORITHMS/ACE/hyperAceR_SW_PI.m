% created by: Dordije Boskovic


function [results] = hyperAceR_SW_PI(M, S,dist)
% HYPERACE Performs the adaptive cosin/coherent estimator algorithm
% MOVING ACE, similar to Antonio Plaza implementation for CEM
%
% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
%   dist -how many pixels to include in initial estimation
% Outputs
%   results - vector of detector output (N x 1)
%


	[p, N] = size(M);
    
    %start with pseudoinverse
	R_init = dist.*hyperCorr(M(:,1:dist));
	G_init = pinv(R_init);

	results = zeros(1, N);
    tmp2 = (S.'*G_init);
	tmp = (S.'*G_init*S);
	
	for k = 1:N
		
		if(k < dist/2+2)
		
			G = G_init;
			
		elseif(k < N-dist/2)
		
			%updating matrix
			C = ShermanMorrison(G,M(:,k+dist/2-1),M(:,k+dist/2-1),0);
			G = ShermanMorrison(C,M(:,k-dist/2-1),M(:,k-dist/2-1),1);
			
            tmp2 = (S.'*G);
			tmp = (S.'*G*S);
			
		end
		
		x = M(:,k);
		results(k) = (tmp2*x)^2 / (tmp*(x.'*G*x));
		
	end
	
end