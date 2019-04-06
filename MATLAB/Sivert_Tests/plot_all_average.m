clear; close all; clc;
testInit;
warning('off');

%% Load data
types = ["PCA","MNFs", "ICA", "MNF"];
FigH = figure('Name', "All Averages", 'Renderer', ...
    'painters','position', [10, 10, 2000,1200]);

for t = 1: length(types)
    type = types(t);
    
    full = load('Results/results_Full.mat');
    data = load(sprintf('Results/results_%s.mat', type));
    
    Full_struct = fieldnames(full);
    Full_struct = Full_struct{1};
    Full_struct = full.(Full_struct);
    
    DR_struct = fieldnames(data);
    DR_struct = DR_struct{1};
    DR_struct = data.(DR_struct);
    
    %% Extract data - per algorithm
    c = 1;
    
    info_mcc = struct;
    info_vis = struct;
    
    for a = 1:length(td_algs)
        td_alg = td_algs(a);
        an = replace(td_alg,'hyper','');
        
        info_mcc.(an) = zeros(1, 1+length(Qs));
        info_vis.(an) = zeros(1, 1+length(Qs));
        
        c = 1;
        for s = 1:length(scenes)
            scene = gt_data_set.(scenes(s));
            
            for id = 1:size(scene.signatures,1)
                end_name = scene.endmembers(id);
                en = replace(end_name,' ','_');
                en = replace(en,'-','_');
                
                info_mcc.(an)(c,:) = [0 DR_struct.(scenes(s)).(en).(an).('score')];
                info_mcc.(an)(c,1) = Full_struct.(scenes(s)).(en).(an).('score');
                
                info_vis.(an)(c,:) = [0 DR_struct.(scenes(s)).(en).(an).('visibility')];
                info_vis.(an)(c,1) = Full_struct.(scenes(s)).(en).(an).('visibility');
                
                c = c +1;
            end
        end
        c = c-1;
        
        info_mcc.(an) = info_mcc.(an)(1:c, :);
        info_vis.(an) = info_vis.(an)(1:c, :);
    end
    
    %% Plot data
    
    xlabels = cellstr([ 'Full', strsplit(num2str(Qs))]);
    for a = 1:length(fieldnames(info_mcc))
        an = replace(td_algs(a),'hyper','');
        
        subplot(length(types),3,1 +(t-1)*(length(types)-1));
        hold on;
        title(type + " - Mean - F_1");
        plot(mean(info_mcc.(an)));
        hold off;
        grid on;
        legend(upper(fieldnames(info_mcc)), 'location', 'best');
        xticks(1:1:(length(Qs) +1));
        xticklabels(xlabels);
        xlabel("Number of Components");
        ylim([0 1]);
        
        
        subplot(length(types),3,2 +(t-1)*(length(types)-1));
        hold on;
        title(type + " - Variance");
        plot(var(info_mcc.(an)));
        hold off;
        grid on;
        legend(upper(fieldnames(info_mcc)), 'location', 'best');
        xticks(1:1:(length(Qs) +1));
        xticklabels(xlabels);
        xlabel("Number of Components");
        ylim([0 .2]);
        
        subplot(length(types),3,3 +(t-1)*(length(types)-1));
        hold on;
        title(type + " - Visibility");
        plot(mean(info_vis.(an)));
        hold off;
        grid on;
        legend(upper(fieldnames(info_mcc)), 'location', 'best');
        xticks(1:1:(length(Qs) +1));
        xticklabels(xlabels);
        xlabel("Number of Components");
        ylim([0 1]);
    end
end

F    = getframe(FigH);
imwrite(F.cdata,join(['Results/img/','Averages.png']), 'png')