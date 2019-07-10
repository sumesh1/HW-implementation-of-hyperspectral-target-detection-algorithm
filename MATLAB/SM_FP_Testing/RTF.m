clc;
% prepare_dataset;
q =126; 
num_loops = 200;
s=6;

if(exist('gt_data_set')~=1)
    load('images.mat');
    fprintf('loaded dataset \n');
end
    
scenes  = string(fieldnames(gt_data_set));
scene       = gt_data_set.(scenes(s));
scene_name  = scenes(s);
M			= scene.cube;

if(scene_name == "hymap")
   gt = scene.gt_fullsub; 
   x = 90;
   y = 458;
   sizecut = 90 - 1;
   
   M  = M(x:(x+sizecut),y:(y+sizecut),:);
   gt = gt(x:(x+sizecut),y:(y+sizecut));
    signatures=gt_data_set.hymap.signatures_corrected;
    target1 = signatures(1,:)';
    target2 = signatures(2,:)';
    target3 = signatures(3,:)';
    target4 = signatures(4,:)';
end

M = hyperConvert2d(M);
t= max(M(:));
M = M./t;  %scaling
target1=target1/t;
target2=target2/t;
target3=target3/t;
target4=target4/t;

num_bands  = q;
num_pixels = size(M,2);

beta = 1000; 

fprintf('\n after treatment: \n');
fprintf('max value in cube: %f \n' ,max(M(:)));
fprintf('min value in cube: %f \n' ,min(M(:)));
fprintf('mean value in cube: %f \n',mean(M(:)));

R_inv_init = (beta) * eye(num_bands ,num_bands);

oldmerr = 0;
merr    = 0;

%hscope1 = NumericTypeScope;

%% True Value
R_true = M*M' + (1/beta)*eye(num_bands,num_bands); %not divided by num_pixels
G_true = inv(R_true);
    
%% Create matrix


  
results    = zeros(num_pixels,4);
results2   = zeros(num_pixels,4);
results3   = zeros(num_pixels,4);
results4   = zeros(num_pixels,4);
results_fp = zeros(num_pixels,1);
smerr      = zeros(num_pixels,1);
 
An_fp  = R_inv_init;
An     = R_inv_init;

delay = 1;
M = M(:,randperm(size(M,2)));
  
for i = 1: delay
    
     x=M(:,i);   
     [An]=ShermanMorrisonRTF2(An,x);
    
end

for i = 1: num_pixels

    x=M(:,i);   

    %% CEM

     %results(i)    = (x'*An*target)/(target'*An*target);
    % results_fp(i) = (x'*A*target)/(target'*A*target);

      [results(i,1),results2(i,1),results3(i,1),results4(i,1)] = hcemFP(x,An,target4);
      [results(i,2),results2(i,2),results3(i,2),results4(i,2)] = hcemFP(x,An,target2);
      [results(i,3),results2(i,3),results3(i,3),results4(i,3)] = hcemFP(x,An,target3);
      [results(i,4),results2(i,4),results3(i,4),results4(i,4)] = hcemFP(x,An,target1);
    %       [A]=ShermanMorrisonRTF_wrapper_fixpt(A,x);
    
    if( i < num_pixels-delay)
         x = M(:,i+delay); 
        [An]=ShermanMorrisonRTF(An,x);
    end
        
        %        
    %     
    %        
    %        oldmerr = merr;
    %    err = abs(double(A)-An) ./ abs(An);
    %    merr = vpa(100*mean(err(:)));
    %    smerr(i)=merr;
    %    fprintf("iteration %d, err = %f, diff = %f \n",i,merr,merr-oldmerr);

end
