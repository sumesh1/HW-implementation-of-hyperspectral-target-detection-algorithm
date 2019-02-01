% created by: Dordije Boskovic

function [results,mapexcluded] = hyperAceR_RTA01(M, S)
% HYPERACE Performs the adaptive cosin/coherent estimator algorithm
% EXCLUDES DETECTED PIXELS FROM UPDATED CORRELATION MATRIX
% REAL TIME ALGORITHM IN HW
%
% Usage
%   [results] = hyperAce(M, S)
% Inputs
%   M - 2d matrix of HSI data (p x N)
%   S - 2d matrix of target endmembers (p x q)
% Outputs
%   results - vector of detector output (N x 1)
 
    th = 0.1;

	[p, N] = size(M);
    t = round(N/100);
	results = zeros(1, N);
	
	R = M(:,1)*M(:,1)';
	G = pinv(R);
    res_mean = 0;
    mapexcluded = zeros(N,1);
    
    
	%h = waitbar(0,'start...');
    
	for k = 1:N
		
		x = M(:,k);
		tmp = (S.'*G*S);
	 
		results(k) = (S.'*G*x)^2 / (tmp*(x.'*G*x));
	  
         if(k > t) 
            res_mean = mean(results((k-t):(k-1)));         
         end
        
        
		if(results(k)-res_mean >= th)
		
            mapexcluded (k) = 1;
			if(k < t && k ~= 1)
				R = R + x*x';
				G = pinv(R); 
			end 
			
        else
                R = R + x*x';
                G= pinv(R);
        end	
        
        % waitbar(k/N,h,'updated');
	
    end

end





