clc; clear; close all;
%% load
[file, path] = uigetfile();
load([path file]);

%% parameters
%assuming the gt_data_set struct is used
%td_algs = ["hyperAce","hyperAceR", "hyperAceR_RT","hyperAceR_RTSM"];
%td_algs = ["hyperAce", "hyperAceR","hyperAceR_RT","hyperAceR_RTSM","hyperAceR_SUB"];
td_algs = ["hyperAceR_SUBRAND"];

if string(file) == "hopavaagen_data.mat"
    gt_data_set.hopavaagen = hopavaagen;
    scenes = ["hopavaagen"];
    ids = [ 1 3 4;
            3 0 0;
            4 0 0];
else
   % scenes=["salinas"];
    scenes = ["pavia", "salinas","indian_pines"];%,"ksc"];
   
    %ids=[11 12 14];
    ids =  [1 4 5;...     % scene 1
        11 12 14;...   % scene 2
        1 7 9];     % scene 3
     %   2 5 7];     % scene 4
end

result_struct = struct;

q = 20;

%metric for performance
mcc = @(tp,tn,fp,fn) (tp*tn - fp*fn)/(sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn)));
f1  = @(tp,tn,fp,fn) (2*tp)/(2*tp+fp+fn);

metric = mcc;