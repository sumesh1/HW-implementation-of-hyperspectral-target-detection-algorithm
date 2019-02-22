% created by: Dordije Boskovic

function [results,mapexcluded] = hyperAceR_RTAM05(M, S)

    th = 0.5;

	[p, N] = size(M);
    t = round(N/1000);
    
    results = zeros(1, N);
	
    res_mean = 0;
    mapexcluded = zeros(N,1);
    
    beta = 10000;
	G = beta*eye(p,p);
  
    for k = 1:N

      x = M(:,k);

        %calculate detection statistic
        tmp2 = S.'*G;
        tmp = (tmp2*S);
        results(k) = (tmp2*x)^2 / (tmp*(x.'*G*x));

         if(k > t) 
            res_mean = 0;
            count = 0;
            for p = (k-t) : (k-1)
                if(mapexcluded(p) ~= 1) 
                 res_mean = res_mean + results(p);   
                 count = count + 1;
                end
                res_mean = res_mean / count;
            end
        end


        if(results(k) - res_mean >= th)
            mapexcluded (k) = 1;
           
            if(k < t && k ~= 1)
                  G = G - ((G*x)*(x'*G))./(1+x'*G*x); 
            end 

        else
              G = G - ((G*x)*(x'*G))./(1+x'*G*x);
        end	
        
    end
    
      for k = 1:t

        x = M(:,k);

        %calculate detection statistic
        tmp2 = S.'*G;
        tmp = (tmp2*S);
        results(k) = (tmp2*x)^2 / (tmp*(x.'*G*x));

        %update matrix
        %G = G - ((G*x)*(x'*G))./(1+x'*G*x);

    end

end





