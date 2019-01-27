% created by: Dordije Boskovic


function [results] = hyperAceR_M(M, S,dist)
% HYPERACE Performs the adaptive cosin/coherent estimator algorithm
% MOVING ACE, similar to Antonio Plaza implementation for CEM
%
% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
% Outputs
%   results - vector of detector output (N x 1)
%


	[p, N] = size(M);
	R_init = dist.*hyperCorr(M(:,1:dist));
	G_init = inv(R_init);

	results = zeros(1, N);
	tmp = (S.'*G_init*S);
	
	for k = 1:N
		
		if(k < dist/2+2)
		
			R = R_init;
			G = G_init;
			
		elseif(k < N-dist/2)
		
			%R=R+(M(:,k+dist/2-1)*M(:,k+dist/2-1)'-M(:,k-dist/2-1)*M(:,k-dist/2-1)')./dist;
			%G=inv(hyperCorr(M(:,(k-(dist/2)-1):(k+dist/2))));
			%G=inv(R);
			
			%updating matrix
			C = ShermanMorrison(G,M(:,k+dist/2-1),M(:,k+dist/2-1),0);
			G = ShermanMorrison(C,M(:,k-dist/2-1),M(:,k-dist/2-1),1);
			
			tmp = (S.'*G*S);
			
		end
		
		x = M(:,k);
		results(k) = (S.'*G*x)^2 / (tmp*(x.'*G*x));
		
	end
	
end