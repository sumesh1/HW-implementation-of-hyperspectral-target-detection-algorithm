
A =  rand(10,10);

[n,~] = size(A);

X = eye(n,n);
I = eye(n,n);

for i = 1 : n
   
    v = I(:,i);
    u = A(:,i) - v;
    
    X = ShermanMorrison(X,u,v,0);
    
end

G = inv(A);


err = abs(G-X)./abs(G);
mean(err(:)*100)