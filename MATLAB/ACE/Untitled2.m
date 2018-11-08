M=rand(50,50);
R=M*M';
G=inv(R);

x=M(:,1:25);
Rx=x*x';
Gx=pinv(Rx);
for i = 26 :size(M,1)
    x=M(:,i);
    Gx=ShermanMorrison(Gx,x,x,0);
  
end