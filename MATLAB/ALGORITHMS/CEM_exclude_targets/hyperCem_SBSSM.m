% created by: Dordije Boskovic

function [results,G] = hyperCem_SBSSM(M, S)


	[p, N] = size(M);

    %take a subset of pixels, about 10*p	
	%num = 10*p;
    % or take a subset of pixels, about 0.1% of pixels	
	%num = round(0.1*N/100);
	
	results = zeros(1, N);

    %initialize matrix
    beta = 10000;
	G = beta*eye(p,p);
	
	for k = 1:N
		
		x = M(:,k);
        
        %calculate detection statistic
        tmp2 = S.'*G;
        tmp = (tmp2*S);
        results(k) = (tmp2*x) / (tmp);
		
        %update matrix
        G = G - ((G*x)*(x'*G))./(1+x'*G*x);

    end

    
%restream data
    for k = 1:(N/100)

        x = M(:,k);

        %calculate detection statistic
        tmp2 = S.'*G;
        tmp = (tmp2*S);
        results(k) = (tmp2*x) / (tmp);

        %update matrix
        %G = G - ((G*x)*(x'*G))./(1+x'*G*x);

    end

    
    
end




