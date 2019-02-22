%% Load the result_all.mat file
clc; %clear; close all;
%[file, path] = uigetfile({'*.mat'},'Select all_mcc.mat');
%load([path file]);
% 

%% set

cell_struct={results_PCA};
%TD_algs=["Cem","Cem_NT","AceR","AceR_NT","AceR_RTA03"];
%TD_algs = [ "Cem","Cem_NT","Cem_RTA03","AceR","AceR_NT","AceR_RTA01","AceR_RTA03","AceR_RTA05"];
TD_algs = ["AceR","AceR_RTSM","AceR_SBSSM","AceR_RTAM01","AceR_RTAM03","AceR_RTAM05","AceR_RTAM07"];
%TD_algs = ["Ace", "AceR","AceR_SBSSM", "Cem","Cem_SBSSM"];

scenes_cell = fieldnames(cell_struct{1});
scenes = string(zeros(1,length(scenes_cell)));


for i = 1:length(scenes)
     scenes(i) = string(scenes_cell(i));
end

% %% plot - visibility
%  for s = 1:length(scenes)
%    
%      consitituents_matrix = string(fieldnames(cell_struct{1}.(scenes(s))))';
%      scores_sum_vis  = zeros(length(TD_algs));
%      figure;
%      
%      for td = 1:length(TD_algs)
%          for e = 1:length(consitituents_matrix)
%             
%              TD_alg = TD_algs(td);    
%              scores_sum_vis(td) = scores_sum_vis(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).visibility;
%          
%          end
%      end
%      
%      xticks(1:length(TD_algs));
%      hold on;
%      plot(scores_sum_vis/length(consitituents_matrix),'--');
%      set(gca,'xticklabel',TD_algs.');
%      ylabel('Visibilty');
%      
%      %plot(mean(scores_sum_vis)'/3, 'ko-');
%    %  TD_algs(4) = "SAM";
%      legend([upper(TD_algs) "mean"],'Interpreter', 'none');
%      legend('Location','best');
%    %  TD_algs(4) = "mySam";
%      hold off;
%      
%      title(sprintf('%s - All endmembers - Visibility',scenes(s)), 'Interpreter', 'none');
%      grid on;
%      
%      set(gcf, 'Position', [100, 100, 800, 500])
% %     
%   %   saveas(gcf,sprintf("%s_VIS_SUMM.png", replace(scenes(s), ' ', '_')));
%  end
%  
% %% plot - MCC
%  for s = 1:length(scenes)
%    
%      consitituents_matrix = string(fieldnames(cell_struct{1}.(scenes(s))))';
%      scores_sum_mcc  = zeros(length(TD_algs));
%      figure;
%      
%      for td = 1:length(TD_algs)
%          for e = 1:length(consitituents_matrix)
%             
%              TD_alg = TD_algs(td);    
%              scores_sum_mcc(td) = scores_sum_mcc(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).score;
%          
%          end
%      end
%      
%      xticks(1:length(TD_algs));
%      hold on;
%      plot(scores_sum_mcc/length(consitituents_matrix),'--');
%      set(gca,'xticklabel',TD_algs.');
%      ylabel('MCC score');
%      
%      %plot(mean(scores_sum_vis)'/3, 'ko-');
%      legend([upper(TD_algs) "mean"],'Interpreter', 'none');
%      legend('Location','best');
% 
%      hold off;
%      
%      title(sprintf('%s - All endmembers - MCC',scenes(s)), 'Interpreter', 'none');
%      grid on;
%      
%      set(gcf, 'Position', [100, 100, 800, 500])
% %     
%   %   saveas(gcf,sprintf("%s_VIS_SUMM.png", replace(scenes(s), ' ', '_')));
%  end 
%  
%  %% plot - AUC
%  for s = 1:length(scenes)
%    
%      consitituents_matrix = string(fieldnames(cell_struct{1}.(scenes(s))))';
%      scores_sum_auc  = zeros(length(TD_algs));
%      figure;
%      
%      for td = 1:length(TD_algs)
%          for e = 1:length(consitituents_matrix)
%             
%              TD_alg = TD_algs(td);    
%               scores_sum_auc(td) =  scores_sum_auc(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).auc;
%          
%          end
%      end
%      
%      xticks(1:length(TD_algs));
%      hold on;
%      plot( scores_sum_auc/length(consitituents_matrix),'--');
%      set(gca,'xticklabel',TD_algs.');
%      ylabel('AUC score');
%      
%      %plot(mean(scores_sum_vis)'/3, 'ko-');
%      legend([upper(TD_algs) "mean"],'Interpreter', 'none');
%      legend('Location','best');
% 
%      hold off;
%      
%      title(sprintf('%s - All endmembers - AUC',scenes(s)), 'Interpreter', 'none');
%      grid on;
%      
%      set(gcf, 'Position', [100, 100, 800, 500])
% %     
%   %   saveas(gcf,sprintf("%s_VIS_SUMM.png", replace(scenes(s), ' ', '_')));
%  end 
%  
 
 %% plot - ALL
 for s = 1:length(scenes)
   
     consitituents_matrix = string(fieldnames(cell_struct{1}.(scenes(s))))';
     consitituents_matrix = consitituents_matrix;
     scores_sum_auc  = zeros(1,length(TD_algs));
     scores_sum_mcc  = zeros(1,length(TD_algs));
     scores_sum_vis  = zeros(1,length(TD_algs));
     figure;
     
     for td = 1:length(TD_algs) 
         TD_alg = TD_algs(td);   
         for e = 1:length(consitituents_matrix)
             
              scores_sum_auc(td) =  scores_sum_auc(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).auc;
              scores_sum_mcc(td) =  scores_sum_mcc(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).score;
              scores_sum_vis(td) =  scores_sum_vis(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).visibility;
         
         end
     end
     
     xticks(1:length(TD_algs));
     hold on;
     plot( scores_sum_auc/length(consitituents_matrix),'--');
     plot( scores_sum_mcc/length(consitituents_matrix),'--');
     plot( scores_sum_vis/length(consitituents_matrix),'--');
     set(gca,'TickLabelInterpreter','none');
     set(gca,'xticklabel',TD_algs.');
     ylabel('Value');
     
     legend([upper(["AUC","MCC","VIS"])],'Interpreter', 'none');
     legend('Location','best');

     hold off;
     
     title(sprintf('%s - All endmembers',scenes(s)), 'Interpreter', 'none');
     grid on;
     
     %set(gcf, 'Position', [100, 100, 800, 500])
%     
  %   saveas(gcf,sprintf("%s_VIS_SUMM.png", replace(scenes(s), ' ', '_')));
 end  
 
