%% Load the result_all.mat file
clc; %clear; close all;
%[file, path] = uigetfile({'*.mat'},'Select all_mcc.mat');
%load([path file]);

%% set parameters
cell_struct = {FULLDIM,PCA50,MNF50,PCA20,MNF20};

c = {"FULLDIM","PCA50","MNF50","PCA20","MNF20"};

TD_algs=["Ace", "AceR","AceR_RT","AceR_RTSM","AceR_SUB"];
%TD_algs = ["Cem", "Ace", "AceR" "mySam"];

scenes_cell = fieldnames(cell_struct{1});
scenes = string(zeros(1,length(scenes_cell)));
for i = 1:length(scenes)
    scenes(i) = string(scenes_cell(i));
end

consitituents_matrix = string(zeros(length(scenes),...
    length(fieldnames(cell_struct{1}.(scenes(1))))));

for i = 1:length(scenes)
    consitituents_matrix(i,:) = string(fieldnames(cell_struct{1}.(scenes(i))))';
end

plot_struct = struct;

%% plot - visibility
for s = 1:length(scenes)
    scores_sum_vis  = zeros(length(TD_algs),length(cell_struct));
    figure;
    for td = 1:length(TD_algs)
        for e = 1:size(consitituents_matrix,2)
            TD_alg = TD_algs(td);
            
            for m = 1:length(cell_struct) % m - methods
                scores_sum_vis(td,m) = scores_sum_vis(td,m)  + ...
                    cell_struct{m}.(scenes(s)).(consitituents_matrix(s,e)).(TD_alg).visibility;
            end    
        end
    end
    
    xticks([1 2 3 4 5]);
    hold on;
    plot((scores_sum_vis(1:end-1,:)')/size(consitituents_matrix,2),'--');
    plot((scores_sum_vis(end,:)')/size(consitituents_matrix,2),'--');
    set(gca,'xticklabel',c.');
    ylabel('Visibilty');
    
    plot(mean(scores_sum_vis)'/3, 'ko-');
  %  TD_algs(4) = "SAM";
    legend([upper(TD_algs) "mean"],'Interpreter', 'none');
    legend('Location','best');
  %  TD_algs(4) = "mySam";
    hold off;
    
    title(sprintf('%s - All endmembers - Visibility',scenes(s)), 'Interpreter', 'none');
    grid on;
    
    set(gcf, 'Position', [100, 100, 800, 500])
    
    saveas(gcf,sprintf("%s_VIS_SUMM.png", replace(scenes(s), ' ', '_')));
end
%% plot ML metric
metric = "MCC";

for s = 1:length(scenes)
    scores_sum_vis  = zeros(length(TD_algs),length(cell_struct));
    figure;
    for td = 1:length(TD_algs)
        for e = 1:size(consitituents_matrix,2)
            TD_alg = TD_algs(td);
            
            for m = 1:length(cell_struct) % m - methods
                scores_sum_vis(td,m) = scores_sum_vis(td,m)  + ...
                    cell_struct{m}.(scenes(s)).(consitituents_matrix(s,e)).(TD_alg).score;
            end  
        end
    end
    
    hold on;
    xticks([1 2 3 4 5]);
    plot((scores_sum_vis(1:end-1,:)')/size(consitituents_matrix,2),'--');
    plot((scores_sum_vis(end,:)')/size(consitituents_matrix,2),'--');
    set(gca,'xticklabel',c.');
    ylabel(sprintf('%s-score', metric));
    
    plot(mean(scores_sum_vis)'/3, 'ko-');
  %  TD_algs(4) = "SAM";
    legend([upper(TD_algs) "mean"],'Interpreter', 'none');
    legend('Location','best');
  %  TD_algs(4) = "mySam";
    
    hold off;
    
    title(sprintf('%s - All endmembers - %s',scenes(s), metric), 'Interpreter', 'none');
    grid on;
    
    set(gcf, 'Position', [100, 100, 800, 500])
    
    saveas(gcf,sprintf("%s_%s_SUMM.png", replace(scenes(s), ' ', '_'), metric));
end