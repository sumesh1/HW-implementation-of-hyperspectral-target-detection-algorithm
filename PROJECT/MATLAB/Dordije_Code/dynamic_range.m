sc=gt_data_set.salinas.cube;
[h,w,d] = size(sc);
M=hyperConvert2d(sc);

signatures=gt_data_set.salinas.signatures;

hscope1 = NumericTypeScope;
 step(hscope1,M);
 
R=hyperCorr(M);
G=inv(R);
hscopeR = NumericTypeScope;
 step(hscopeR,R);

hscopeG = NumericTypeScope;
 step(hscopeG,G);
 
 
  q=20;
 M_2d_pca = hyperConvert2d(sc);
 M_2d_pca = M_2d_pca';
 [coeff,~,~,~,explained,~] = pca(M_2d_pca);
            
V = coeff(:,1:q);
M_pct = transpose(M_2d_pca*V);
M_new_pca = hyperConvert3d(M_pct,h,w,q);

hscope2 = NumericTypeScope;
 step(hscope2,M_pct);
 
 Rpca=hyperCorr(M_pct);
Gpca=inv(Rpca);
hscopeRpca = NumericTypeScope;
 step(hscopeRpca,Rpca);

hscopeGpca = NumericTypeScope;
 step(hscopeGpca,Gpca);
 
 
 

% res=hyperAceR(M,target);
% 
% res2d=reshape(res,[h,w]);
% 
% im=hyperConvert2Colormap(res2d,hot);