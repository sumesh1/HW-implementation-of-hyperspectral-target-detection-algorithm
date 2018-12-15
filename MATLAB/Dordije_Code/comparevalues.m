
values=[];

for i = 1 : length(res1)
    
    values=[values,M_pct(:,i)'*G*M_pct(:,i)];
    
end

values2=[];

for i = 1 : length(res2)
    
    values2=[values2,(sR*M_pct(:,i))^2];
    
end

normA = values - min(values);
normA = normA ./ max(normA);
normB = res1' - min(res1');
normB = normB ./ max(normB);



 simul=res1'/8;

 err=(abs(simul-values))./abs(values);
         err=100*mean(err)
         
  MSE =  mean(((simul-values)./values).^2) 
  RMSRE=sqrt(MSE)
  RRMSE= 100* sqrt(mean((simul-values).^2) )/mean(values)
  
  MAE = mean(abs(simul-values))
  100*MAE/mean(values)

   % rmse=100*sqrt(mean(((values-simul)./mean(values)).^2))
  
    normA = values2 - min(values2);
normA = normA ./ max(normA);
normB = res2' - min(res2');
normB = normB ./ max(normB);
    
 simul2=res2'/8;
 
 err2=mean(abs(simul2-values2)./values2)
  
 
 RRMSE2= 100* sqrt(mean((simul2-values2).^2) )/mean(values2)
      MSE2 =  mean(((simul2-values2)./values2).^2) 
  RMSRE2=sqrt(MSE2)
    
    
    
    
% 
% z=(values-min(values))/(max(values)-min(values))
% zs=(simul-min(simul))/(max(simul)-min(simul))
% 
% 
% values=values/mean(values);
% simul=simul/mean(simul);
% values2=values2/mean(values2);
% simul2=simul2/mean(simul2);
% 
% 
% 
%     
%    err=100*abs(values-simul)./values;
%    mean(err)
%    errz=100*abs(z-zs)./z;
%    mean(errz)
%     
%    err2=100*abs(values2-simul2)./values2;
%    mean(err2)
% 
% 
% 
% 
% tx=simul./values;
% tx2=simul2./values2;