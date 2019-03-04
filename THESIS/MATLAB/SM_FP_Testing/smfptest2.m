R_init= 2^30*eye(103,103);

x=M(:,1)';

Rn=ShermanMorrison(R_init,x',x',0);
Rnfp=ShermanMorrison_fp(R_init,x',x',0);


x=M(:,2)';

Rn2=ShermanMorrison(Rn,x',x',0);
Rnfp2=ShermanMorrison_fp(Rnfp,x',x',0);

x=M(:,3)';

Rn3=ShermanMorrison(Rn2,x',x',0);
Rnfp3=ShermanMorrison_fp(Rnfp2,x',x',0);

x=M(:,4)';

Rn4=ShermanMorrison(Rn3,x',x',0);
Rnfp4=ShermanMorrison_fp(Rnfp3,x',x',0);