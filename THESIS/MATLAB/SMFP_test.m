
[m,n]=size(sc1);

num_bands = m;
beta = 10000;

R_inv_init = (beta) * eye(num_bands ,num_bands);

[R_new]=ShermanMorrison(R_inv_init,sc1(:,1),sc1(:,1),0);

for i = 2:400
    
    [R_new]=ShermanMorrison(R_new,sc1(:,i),sc1(:,i),0);

end


%true

%R_true = hyperCorr(sc1);
R_true = sc1*sc1';
R_true = inv(R_true);

err  = abs(R_new-R_true)./R_true;
merr = 100*mean(err(:))
 