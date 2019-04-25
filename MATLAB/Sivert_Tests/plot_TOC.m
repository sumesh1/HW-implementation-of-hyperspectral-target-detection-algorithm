clear; close all; clc;
testInit;
warning('off');

%% Load data
types = ["FULL"];
info_tp = struct;
info_fp = struct;

for t = 1: length(types)
    type = types(t);
 
    full = load('results_full.mat');
    %data = load(sprintf('Results/results_%s.mat', type));
 
    Full_struct = fieldnames(full);
    Full_struct = Full_struct{1};
    Full_struct = full.(Full_struct);
 
    % DR_struct = fieldnames(data);
    % DR_struct = DR_struct{1};
    % DR_struct = data.(DR_struct);
 
    % Extract data - per algorithm
    for s = 5:5%length(scenes)
        scene = gt_data_set.(scenes(s));
     
        for id = 1:size(scene.signatures,1)
            end_name = scene.endmembers(id);
            en = replace(end_name, ' ', '_');
            en = replace(en, '-', '_');
            scene_name = strrep(scenes(s), '_', ' ');
            figure('name', scene_name, 'position', [100, 100, 800, 600])
            ylabel('TP');
            xlabel('TP+FP');
            legend_entry = [td_algs,'MIN','MAX'];
     
            for a = 1:length(td_algs)
                td_alg = td_algs(a);
                an = replace(td_alg, 'hyper', '');

                info_tp.(type).(scenes(s)).(an)(:, id) = ...
                  Full_struct.(scenes(s)).(en).(an).('tp');

                info_fp.(type).(scenes(s)).(an)(:, id) = ...
                  Full_struct.(scenes(s)).(en).(an).('fp');

                hold on
                grid on
                fpr = info_fp.(type).(scenes(s)).(an)(:, id);
                tpr = info_tp.(type).(scenes(s)).(an)(:, id);
               if(mod(a,2)==0)
                 plot(fpr + tpr, tpr,'-.', 'Linewidth', 1.8);
               else
                 plot(fpr + tpr, tpr,'-.', 'Linewidth', 1.8);
               end
                
                
                
            end
              [m,n] = size(scene.gt);
                positives = scene.abundance(id);
                if(scene_name == 'hymap') 
                       positives = scene.abundance_fullsub(id);
                end
                %maximum and minimum
                k1 = 0:1:m*n-1;
                k2 = zeros(1,m*n);
                k2(end-positives+1:end) = 1:positives;
                k3 = ones(1,m*n);
                k3 = k3*positives;
                k3(1:positives+1) = 0:positives;
                
                plot(k1,k2,'--', 'Linewidth', 2);
                plot(k1,k3,'--',  'Linewidth', 2);
                
                set(gca, 'FontSize', 12);            
                set(gca, 'fontweight','bold');
                set(gca, 'XScale', 'log');
                
                xlim([0 1.02*m*n])
                ylim([0 1.02*positives])
             legend(legend_entry, 'location','northeastoutside');
        
        end
    end
end
