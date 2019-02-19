
[m,n]=size(M);

num_bands = m;
beta = 10000;

R_inv_init = (beta) * eye(num_bands ,num_bands);

[R_new]=ShermanMorrison(R_inv_init,M(:,1),M(:,1),0);

for i = 2:350
    
    [R_new]=ShermanMorrison(R_new,M(:,i),M(:,i),0);

end


%true

%R_true = hyperCorr(sc1);
%R_true = sc1*sc1';
%R_true = inv(R_true);

%err  = abs(R_new-R_true)./R_true;
%merr = 100*mean(err(:))
 