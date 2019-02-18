R_init= 1000000*eye(224,224);

%x=25000:10:25150;
x=M(:,1)';

Rn=ShermanMorrison_fp(R_init,x',x',0);


%x=25160:10:25310;
x=M(:,2)';

Rn2=ShermanMorrison_fp(Rn,x',x',0);

%x=25320:10:25470;
x=M(:,3)';

Rn3=ShermanMorrison_fp(Rn2,x',x',0);


%x=25480:10:25630;
x=M(:,4)';

Rn4=ShermanMorrison_fp(Rn3,x',x',0);