%Used to test all variants of Sherman-Morrison and target detection
%combinations

%% LOAD SCENE AND PREPARATION
if(exist('gt_data_set')~=1)
    load('images.mat');
    fprintf('loaded dataset \n');
end
    
scenes  = string(fieldnames(gt_data_set));
scene       = gt_data_set.(scenes(s));
scene_name  = scenes(s);
M			= scene.cube;
endmembers = scene.endmembers;
signatures = scene.signatures;
gt = scene.gt; 
target = signatures(em,:)';
algorithm = @(x,An,target) (x'*An*target)/(target'*An*target); %CEM
%algorithm = @(x,An,target) (target'*An*x)^2/((target'*An*target)*(x'*An*x)); %ACER

if(scene_name == "hymap")
   gt = scene.gt_fullsub; 
   x = 90;
   y = 458;
   sizecut = 90 - 1;
   
   M  = M(x:(x+sizecut),y:(y+sizecut),:);
   gt = gt(x:(x+sizecut),y:(y+sizecut));
   signatures=gt_data_set.hymap.signatures_corrected;
   target = signatures(em,:)';
end

M = hyperConvert2d(M);

num_bands  = size(M,1);
num_pixels = size(M,2);
res1=zeros(num_pixels,1);
res2=zeros(num_pixels,1);
res3=zeros(num_pixels,1);
res4=zeros(num_pixels,1);

%% global detectors
resCEM = hyperCem(M,target);
resAceR = hyperAceR(M,target);

%% SCALE VALUES TO FIXED POINT
t = max(M(:));
M = M./t;
target = target ./t;
M = sfi(M,16,15);
target = sfi(target,16,15);
M = double(M);
target=double(target);

beta = 10000;
R_inv_init = (beta) * eye(num_bands ,num_bands);
k = num_bands;

R_true = M*M' ; %not divided by num_pixels
G_true = inv(R_true);

%% CEM first
An1 = R_inv_init;
for i = 1:num_pixels
     x = M(:,i);
     res1(i) = algorithm(x,An1,target);   
     [An1]=ShermanMorrisonRTF(An1,x);     
end
%restream 1% of pixels
for i = 1:num_pixels/100
     x = M(:,i);
     res1(i) = algorithm(x,An1,target);   
end


%% SM first
An2         = R_inv_init;
for i = 1:num_pixels
     x = M(:,i);
     [An2]=ShermanMorrisonRTF(An2,x);     
     res2(i) = algorithm(x,An2,target);   
end

%% CEM first delayed
An3         = R_inv_init;
for i = 1:k
  x = M(:,i);    [An3]=ShermanMorrisonRTF(An3,x);
end

for i = 1:num_pixels
     x = M(:,i);
     res3(i) = algorithm(x,An3,target);
    
     if(i<num_pixels-k)
       x = M(:,i+k); 
     [An3]=ShermanMorrisonRTF(An3,x);
     end
     
end


%% SM first delayed
An4         = R_inv_init;
for i = 1:k
  x = M(:,i);    [An4]=ShermanMorrisonRTF(An4,x);
end

for i = 1:num_pixels
     if(i<num_pixels-k)
       x = M(:,i+k); 
      [An4]=ShermanMorrisonRTF(An4,x);
     end
    
     x = M(:,i);
     res4(i) = algorithm(x,An4,target); 
     
end

 [mcc,vis,auc]=getMCC(normalize(res1),gt',em)
 [mcc,vis,auc]=getMCC(normalize(res2),gt',em)
 [mcc,vis,auc]=getMCC(normalize(res3),gt',em)
 [mcc,vis,auc]=getMCC(normalize(res4),gt',em)
 [mcc,vis,auc]=getMCC(normalize(resCEM),gt',em)
 [mcc,vis,auc]=getMCC(normalize(resAceR),gt',em)
 disp('END')