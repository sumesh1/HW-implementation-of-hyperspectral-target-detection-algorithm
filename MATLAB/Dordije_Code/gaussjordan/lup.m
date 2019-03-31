function [A,p] = LUP(A)
    n = size(A,1);
    p = (1:n)';

    for k = 1:n-1
        [temp,pos] = max(abs(A(k:n,k)));
        row2swap = k-1+pos;
        A([row2swap, k],:) = A([k, row2swap],:);
        p([row2swap, k]) = p([k, row2swap]);

        for i = k+1:n 
            A(i,k) = A(i,k)/A(k,k);
           
            for j = k+1:n 
               A(i,j) = A(i,j) - A(i,k)*A(k,j);
            end
        end
    end
end