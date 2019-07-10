%% initial parameters
clc;
%choose scene number
s = 2;
%choose number of bands
q = 20;


%% prepare dataset for SM testing
if(exist('gt_data_set')~=1)
    load('matlab.mat');
    fprintf('loaded dataset \n');
end
scenes  = string(fieldnames(gt_data_set));
scene       = gt_data_set.(scenes(s));
scene_name  = scenes(s);
M			= scene.cube;

% Do pca
[h,w,d] = size(M);
M_2d_pca = hyperConvert2d(M);
M_2d_pca = M_2d_pca';
[coeff,~,~,~,explained,~] = pca(M_2d_pca);
V = coeff(:,1:q);
M_pct = transpose(M_2d_pca*V);
%M_new = hyperConvert3d(M_pct,h,w,q);
M = M_pct;


clearvars -except M q gt_data_set
             