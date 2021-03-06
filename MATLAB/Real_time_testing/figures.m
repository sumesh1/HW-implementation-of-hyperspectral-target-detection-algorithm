%% Load the result_all.mat file
clc; %clear; close all;
%[file, path] = uigetfile({'*.mat'},'Select all_mcc.mat');
%load([path file]);
% 

%% set

cell_struct={results_PCA};
%TD_algs=["Cem","Cem_NT","AceR","AceR_NT","AceR_RTA03"];
%TD_algs = [ "Cem","Cem_NT","Cem_RTA03","AceR","AceR_NT","AceR_RTA01","AceR_RTA03","AceR_RTA05"];
%TD_algs = ["Cem","Cem_NT","Cem_SBSSM","Cem_RTAM01","Cem_RTAM03","Cem_RTAM05","Cem_RTAM07","AceR","AceR_NT","AceR_RTSM","AceR_SBSSM","AceR_RTAM01","AceR_RTAM03","AceR_RTAM05","AceR_RTAM07"];
%TD_algs = ["AceR", "AceR_RT","AceR_RTA01", "AceR_RTA03","AceR_RTA05"];
%TD_algs = [ "Cem","Cem_NT","Cem_SBSSM","Cem_RTAM01","Cem_RTAM03","Cem_RTAM05","Cem_RTAM07"];
TD_algs = ["Sam","Cem","Ace","AceR"];
scenes_cell = fieldnames(cell_struct{1});
scenes = string(zeros(1,length(scenes_cell)));


for i = 1:length(scenes)
     scenes(i) = string(scenes_cell(i));
end

scenes=["pavia"];

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



%  %% plot - ROC
%  for s = 1:length(scenes)
%    
%      consitituents_matrix = string(fieldnames(cell_struct{1}.(scenes(s))))';
%      consitituents_matrix = consitituents_matrix(1);
%      
%     
%      for e = 1:length(consitituents_matrix)
%         figure;
%         hold on; 
%          for td = 1:length(TD_algs) 
%               TD_alg = TD_algs(td);   
%                    
%               tpr =   cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).tpr;
%               fpr =   cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).fpr;   
%               semilogx(fpr,tpr,'--');
%          end
%          ylabel('TPR');
%          set(gca, 'XScale', 'log');
%          l = legend([upper(TD_algs)]);
%          l.ItemHitFcn = @hitcallback_ex2;
%          %legend('Location','best');
% 
%          hold off;
% 
%          title(sprintf('%s - %s',scenes(s),consitituents_matrix(e)), 'Interpreter', 'none');
%          grid on;
%      end
%      
% 
%  end  
%    
  %% plot - ALL
 figure;
 for s = 1:length(scenes)
    
     consitituents_matrix = string(fieldnames(cell_struct{1}.(scenes(s))))';
     consitituents_matrix = consitituents_matrix;
     
      if scenes(s)== "salinas"
           
           consitituents_matrix = consitituents_matrix([11,12]);
           
      elseif scenes(s)== "pavia"
          
           consitituents_matrix = consitituents_matrix([5]);
           
      elseif scenes(s)== "hopavaagen"
          
           consitituents_matrix = consitituents_matrix(4);
           
      elseif scenes(s)== "indian_pines"
          
          consitituents_matrix = consitituents_matrix(4);
         
     end
     
     
     scores_sum_auc  = zeros(1,length(TD_algs));
     scores_sum_mcc  = zeros(1,length(TD_algs));
     scores_sum_vis  = zeros(1,length(TD_algs));
   
     
     for td = 1:length(TD_algs) 
         TD_alg = TD_algs(td);   
         for e = 1:length(consitituents_matrix)
             
              %scores_sum_auc(td) =  scores_sum_auc(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).auc;
              
      
              scores_sum_mcc(td) =  scores_sum_mcc(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).score;
              scores_sum_vis(td) =  scores_sum_vis(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).visibility;
             
         end
     end
     
     xticks(1:length(TD_algs));
     
     hold on;
    % plot( scores_sum_auc/length(consitituents_matrix),'--','LineWidth',1.5);
     plot( scores_sum_mcc/length(consitituents_matrix),'--','LineWidth',1.5);
     plot( scores_sum_vis/length(consitituents_matrix),'--','LineWidth',1.5);
     set(gca,'TickLabelInterpreter','none');
     set(gca,'xticklabel',TD_algs.');
     ylabel('Value');
     
     l = legend([upper(["mcc","vis"])],'Interpreter', 'none');
     legend('Location','best');
 l.ItemHitFcn = @hitcallback_ex2;
     hold off;
     
     title(sprintf('%s - All endmembers',scenes(s)), 'Interpreter', 'none');
     grid on;
     
     set(gcf, 'Position', [100, 100, 1100, 600])
%     
    % saveas(gcf,sprintf("%s_VIS_SUMM.png", replace(scenes(s), ' ', '_')));
 end  
 
%  %% plot - ALL
%   figure;
%  for s = 1:length(scenes)
%    
%      consitituents_matrix = string(fieldnames(cell_struct{1}.(scenes(s))))';
%      consitituents_matrix = consitituents_matrix;
%      
%        if scenes(s)== "salinas"
%            
%            consitituents_matrix = consitituents_matrix(11);
%            
%       elseif scenes(s)== "pavia"
%           
%            consitituents_matrix = consitituents_matrix;
%            
%       elseif scenes(s)== "hopavaagen"
%           
%            consitituents_matrix = consitituents_matrix(4);
%            
%       elseif scenes(s)== "indian_pines"
%           
%           consitituents_matrix = consitituents_matrix(4);
%          
%      end
%      
%      
%      
%      scores_sum_auc  = zeros(1,length(TD_algs));
%      scores_sum_mcc  = zeros(1,length(TD_algs));
%      scores_sum_vis  = zeros(1,length(TD_algs));
%    
%      
%      for td = 1:length(TD_algs) 
%          TD_alg = TD_algs(td);   
%          for e = 1:length(consitituents_matrix)
%              
%               %scores_sum_auc(td) =  scores_sum_auc(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).auc;
%              %scores_sum_mcc(td) =  scores_sum_mcc(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).score;
%               scores_sum_vis(td) =  scores_sum_vis(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).visibility;
%          
%          end
%      end
%      
%      xticks(1:length(TD_algs));
%      hold on;
%     % plot( scores_sum_auc/length(consitituents_matrix),'--','LineWidth',1.5);
%     % plot( scores_sum_mcc/length(consitituents_matrix),'--','LineWidth',1.5);
%      plot( scores_sum_vis/length(consitituents_matrix),'--','LineWidth',1.5);
%      set(gca,'TickLabelInterpreter','none');
%      set(gca,'xticklabel',TD_algs.');
%      ylabel('Value');
%      
%      l = legend([upper(scenes)],'Interpreter', 'none');
%      legend('Location','best');
%  l.ItemHitFcn = @hitcallback_ex2;
%      %hold off;
%      
%      title(sprintf('%s - All endmembers',scenes(s)), 'Interpreter', 'none');
%      grid on;
%      
%      set(gcf, 'Position', [100, 100, 1100, 600])
% %     
%     % saveas(gcf,sprintf("%s_VIS_SUMM.png", replace(scenes(s), ' ', '_')));
%  end  
 
%  %% plot - ALL
%  for s = 1:length(scenes)
%    
%      consitituents_matrix = string(fieldnames(cell_struct{1}.(scenes(s))))';
%      consitituents_matrix = consitituents_matrix;
%      scores_sum_auc  = zeros(1,length(TD_algs));
%      scores_sum_mcc  = zeros(1,length(TD_algs));
%      scores_sum_vis  = zeros(1,length(TD_algs));
%      figure;
%      
%      for td = 1:length(TD_algs) 
%          TD_alg = TD_algs(td);   
%          for e = 1:length(consitituents_matrix)
%              
%               scores_sum_auc(td) =  scores_sum_auc(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).auc;
%               scores_sum_mcc(td) =  scores_sum_mcc(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).score;
%               scores_sum_vis(td) =  scores_sum_vis(td)  + cell_struct{1}.(scenes(s)).(consitituents_matrix(e)).(TD_alg).visibility;
%          
%          end
%      end
%      
%      xticks(1:length(TD_algs));
%      hold on;
%      plot( scores_sum_auc/length(consitituents_matrix),'--','LineWidth',1.5);
%      plot( scores_sum_mcc/length(consitituents_matrix),'--','LineWidth',1.5);
%      plot( scores_sum_vis/length(consitituents_matrix),'--','LineWidth',1.5);
%      set(gca,'TickLabelInterpreter','none');
%      set(gca,'xticklabel',TD_algs.');
%      ylabel('Value');
%      
%      l = legend([upper(["AUC","MCC","VIS"])],'Interpreter', 'none');
%      legend('Location','best');
%  l.ItemHitFcn = @hitcallback_ex2;
%      hold off;
%      
%      title(sprintf('%s - All endmembers',scenes(s)), 'Interpreter', 'none');
%      grid on;
%      
%      set(gcf, 'Position', [100, 100, 1100, 600])
% %     
%      saveas(gcf,sprintf("%s_VIS_SUMM.png", replace(scenes(s), ' ', '_')));
%  end  
 
function hitcallback_ex2(src,evnt)

if evnt.Peer.LineWidth == 3
    evnt.Peer.LineWidth = 0.5;
else 
    evnt.Peer.LineWidth = 3;
end

end