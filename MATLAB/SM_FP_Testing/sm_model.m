
%% reset workspace
clear all;
clc;
close all force

%% RNG
rng('default');

%% Signal generation

vect_01 = 1000:1000:4000;
vect_02 = 33554432:100:(33554432+100*3);
mat_02 = 33554432*rand(4,4);
enable_sig= [1,1,1];
%% MATLAB Reference model

    % dot product
    
    y = dot(vect_01, vect_02);
    fprintf('Dot product is %d \n',y);
    
%% MATLAB Detailed model

%% SIMULINK

stoptime = length(vect_01)-1;
sim('sm_2018');

