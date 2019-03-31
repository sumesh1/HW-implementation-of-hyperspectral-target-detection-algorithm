%just a test
sc=gt_data_set.salinas.cube;
[h,w,d] = size(sc);
M=hyperConvert2d(sc);

signatures=gt_data_set.salinas.signatures;

target=signatures(11,:)';

res=hyperAceR(M,target);

res2d=reshape(res,[h,w]);

im=hyperConvert2Colormap(res2d,hot);



%PCA CALCULATION
 q=20;
 M_2d_pca = hyperConvert2d(sc);
 M_2d_pca = M_2d_pca';
 [coeff,~,~,~,explained,~] = pca(M_2d_pca);
            
V = coeff(:,1:q);
M_pct = transpose(M_2d_pca*V);
M_new_pca = hyperConvert3d(M_pct,h,w,q);

signaturespca = signatures*V;
targetpca=signaturespca(11,:)';

respca=hyperAceR(M_pct,targetpca);


respca2d=reshape(respca,[h,w]);

impca=hyperConvert2Colormap(respca2d,hot);

%MNF CALCULATION
 [Mg_mnf, Ag_mnf] = GreenMNF(sc);
            Ag_mnf_inv = inv(Ag_mnf);
            
            M_new_mnf = Mg_mnf(:,:,1:q);
            T = Ag_mnf_inv(:,1:q);
            
            signaturesmnf = signatures*transpose(pinv(T));
            
            
            targetmnf=signaturesmnf(11,:)';

resmnf=hyperAceR(hyperConvert2d(M_new_mnf),targetmnf);


resmnf2d=reshape(resmnf,[h,w]);

immnf=hyperConvert2Colormap(resmnf2d,hot);


%figure(1);
%hold on
subplot(1,3,1);
title('Full dim');
imshow(im);
subplot(1,3,2);
title('PCA 20');
imshow(impca);
subplot(1,3,3);
title('MNF 20');
imshow(immnf);

%subplot(1,3,[1 2 3]);
%hold on
%colormap(hot);
%colorbar('location','southoutside');


print(gcf,'foo.png','-dpng','-r300'); 

b1=resmnf2d;
gt=gt_data_set.salinas.gt;
  % Calculate Visibility            
            T_t_sum = 0; T_t_count = 0;
            T_b_sum = 0; T_b_count = 0;
            T_b_max  =0;
            T_t_min = 1;
            cnt1=0;
            cnt2=0;
            
            
            for j = 1:h
                for k = 1:w
                    if gt(j,k) == 11
                        T_t_sum     = T_t_sum + b1(j,k);
                        T_t_count   = T_t_count +1;
                     
                        if(b1(j,k)<0.5)
                            T_t_min = b1(j,k);
                            cnt1=cnt1+1;
                        end
                        
                        
                    else
                        T_b_sum     = T_b_sum + b1(j,k);
                        T_b_count   = T_b_count +1;
                        
                        if(b1(j,k)>T_b_max)
                            T_b_max = b1(j,k);
                             cnt2=cnt2+1;
                        end
                        
                    end
                end
            end
            T_t_avg = T_t_sum / T_t_count;
            T_b_avg = T_b_sum / T_b_count;
            
            T_max = max(b1(:)); T_min = min(b1(:));
            
            vis = norm(T_t_avg - T_b_avg)/(T_max - T_min);


            