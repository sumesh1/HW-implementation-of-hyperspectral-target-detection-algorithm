[m,n] = size(M);

t = n;
beta = 10000;

Rk = M(:,1:t) * M(:,1:t)';
Rk = Rk + (1/beta)*eye(m,m);
G = inv(Rk);

G2 = beta * eye(m,m);
G3 = beta * eye(m,m);

for i = 1:t
   
    G2 = ShermanMorrison(G2,M(:,i));
    
    u = M(:, i);
    TRx = G3 * u;
    TRxxR = TRx * TRx';
    Td = u' * TRx;
    Tdiv = 1 / (Td + 1);
    TT = TRxxR .* Tdiv;
    G3 = G3 - TT;
   
end



err = abs(G-G2)./abs(G);
mean(err(:)*100)

err = abs(G-G3)./abs(G);
mean(err(:)*100)

err = abs(G3-G2)./abs(G2);
mean(err(:)*100)