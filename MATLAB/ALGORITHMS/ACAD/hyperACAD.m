function [d_acad,R,anomaly_map,threshold_check_values] = hyperACAD(M,tresh)


t_an = 0;

beta = 100;

[p,N]= size(M);

anomalies_detected = zeros(p,N/2);

adts = zeros(p,p);

n_acad = N / beta;

u_k = 0;

d_acad = zeros(N,1);

h= waitbar(0,'start...');

R = 0;
t=0;


threshold_check_values= zeros(N,1);

location_of_anomalies = zeros(N/2,1);

 % x = M(:,1);
 % R = M(:,1:t)*M(:,1:t)'/N;
 % G = pinv(R); 
 % d_acad(1) = x'*G*x;
 
 R = M(:,1)*M(:,1)';
 G = pinv(R); 
 
 
    for j = 1:N
          
        
        x = M(:,j);
        d_acad(j) = (x'*G*x)*(j);  
                
        if(j > floor(n_acad)) 
            u_k = mean(d_acad((j-floor(n_acad)):(j-1)));         
        end
        
        threshold_check_values(j) = d_acad(j)-u_k;
      
        if (((d_acad(j)-u_k) > tresh) && (j > n_acad))
           
            anomalies_detected(:,t_an+1) = x;
            location_of_anomalies (t_an+1) = j;
            adts = adts + x*x';
            t_an = t_an + 1;
          
        elseif (j>1)
            
            R = R + x*x';
            G = pinv(R);   
            
        end
        
       
    
    
        waitbar(j/N,h,'updated');
    end
    
    anomaly_map = zeros(1,N);
    
    for i = 1:N/2
       
        if (anomalies_detected(1,i) ~= 0)
            pixel_pos_anomaly = location_of_anomalies(i);
            anomaly_map(pixel_pos_anomaly) = 1;
        
        end
    end
          
        


 end

