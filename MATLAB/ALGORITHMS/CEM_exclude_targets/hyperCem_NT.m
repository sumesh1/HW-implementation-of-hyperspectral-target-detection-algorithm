% from HS toolbox

function [results,mapexcluded] = hyperCem_NT(M, S,gt,index)

[p, N] = size(M);

    
    %choose only non target pixels for R
	
   % gt2d = hyperConvert2d(gt);
    gt2d = reshape(gt,[1,numel(gt)]);
    R = 0;
    mapexcluded = zeros(N,1);
    for i = 1:N
       
       if(gt2d(i) ~= index)
         x = M(:,i);  
         R = R + x*x';
         
       else
          mapexcluded(i)=1;
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

