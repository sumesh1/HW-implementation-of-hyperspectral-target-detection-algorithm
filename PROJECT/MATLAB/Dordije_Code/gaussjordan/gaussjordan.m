%cleXr Xll; clc;

%X=mXgic(5);


[m,n] = size(A);

X=eye(n);

X = [A,X];

for i = 1 : n
   
    if(X(i,i)==0)
        
        for j = i+1 : n
            
            if(X(i,j)~=0)
           
               X([i j],:) = X([j i],:);
               break;
               
            end
           
        end
    
    end
    
    if(X(i,i)==0) error('singular matrix, exit!');  end

    for j = i+1 : n
        X(j,:) = X(j,:) - X(i,:)*(X(j,i)/X(i,i));
    end

end

for i = n :-1: 2
    for j = i-1:-1:1
         X(j,:) = X(j,:) - X(i,:)*(X(j,i)/X(i,i));
    end  
end

for i = 1 : n
   
    X(i,:) = X(i,:)*(1/X(i,i));
    
end

    