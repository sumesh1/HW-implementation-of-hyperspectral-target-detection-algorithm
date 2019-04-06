clc; clear; close all;

%% load
% [file, path] = uigetfile();
% load([path file]);
load('images.mat')


%% parameters - config
% Number of compoents to be tested
Qs = 50:-5:5;

% Number of cases to be tested/simulated
current_step = 0;
max_step = 2720; % approximately for all tests

% Assuming the gt_data_set struct is used
td_algs = ["hyperAce","hyperAceR","hyperASMF","hyperASMF2",...
    "hyperCem", "hyperSam"];
%td_algs = ["hyperSam", "hyperCem", "hyperAce","hyperAceR"];

scenes  = string(fieldnames(gt_data_set));
scenes = scenes([1:3,5,6]); %remove ksc scene

% Metric for classification performance
mcc = @(tp,tn,fp,fn) (tp*tn - fp*fn)/(sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn)));
f1  = @(tp,tn,fp,fn) (2*tp)/(2*tp+fp+fn);
metric = mcc;

%number of steps in P_FA vector
P_FA_STEP = 10000;

% Portion of data set used for training
training_portion = 1;

% Indicate if it is a debugging run of the simulation
fast_run = 1;
if fast_run
    P_FA_STEP = 1000;
    td_algs = td_algs([1,3,4,5]);
    scenes  = scenes(end);
    Qs = Qs(1:3);
    max_step = 48; %approximately for short test
end