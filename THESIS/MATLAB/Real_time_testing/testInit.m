clc; clear; close all;

%% load
% [file, path] = uigetfile();
% load([path file]);
load('matlab.mat')


%% parameters
% Number of compoents to be tested
Qs = 50:-5:5;

% Assuming the gt_data_set struct is used
%td_algs = ["hyperAce", "hyperAceR","hyperAceR_SBSSM", "hyperCem","hyperCem_SBSSM"];
%td_algs = [ "hyperCem","hyperCem_NT","hyperCem_RTA03","hyperAceR","hyperAceR_NT","hyperAceR_RTA01","hyperAceR_RTA03","hyperAceR_RTA05"];
td_algs = ["hyperCem","hyperCem_NT","hyperCem_SBSSM","hyperCem_RTAM01","hyperCem_RTAM03","hyperCem_RTAM05","hyperCem_RTAM07","hyperAceR","hyperAceR_NT","hyperAceR_RTSM","hyperAceR_SBSSM","hyperAceR_RTAM01","hyperAceR_RTAM03","hyperAceR_RTAM05","hyperAceR_RTAM07"];
%td_algs = [ "hyperCem","hyperCem_NT","hyperCem_SBSSM","hyperCem_RTAM01","hyperCem_RTAM03","hyperCem_RTAM05","hyperCem_RTAM07"];

scenes  = string(fieldnames(gt_data_set));

% Metric for classification performance
mcc = @(tp,tn,fp,fn) (tp*tn - fp*fn)/(sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn)));
f1  = @(tp,tn,fp,fn) (2*tp)/(2*tp+fp+fn);
metric = mcc;