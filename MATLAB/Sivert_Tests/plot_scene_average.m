clear; close all; clc;
testInit;
warning('off');

%% Load data
types = ["FULL"];
info_mcc = struct;
info_vis = struct;
info_pfa = struct;
info_dr  = struct;


for t = 1: length(types)
    type = types(t);
    
    full = load('newest.mat');
    %data = load(sprintf('Results/results_%s.mat', type));
    
    Full_struct = fieldnames(full);
    Full_struct = Full_struct{1};
    Full_struct = full.(Full_struct);
    
   % DR_struct = fieldnames(data);
   % DR_struct = DR_struct{1};
   % DR_struct = data.(DR_struct);
    
    % Extract data - per algorithm
    for s = 1:length(scenes)
        scene = gt_data_set.(scenes(s));
        
        for a = 1:length(td_algs)
            td_alg = td_algs(a);
            an = replace(td_alg,'hyper','');
            
            for id = 1:size(scene.signatures,1)
                end_name = scene.endmembers(id);
                en = replace(end_name,' ','_');
                en = replace(en,'-','_');
                
              %  info_mcc.(type).(scenes(s)).(an)(id,:) = ...
                 %   [0 DR_struct.(scenes(s)).(en).(an).('score')];
                info_mcc.(type).(scenes(s)).(an)(id,1) = ...
                    Full_struct.(scenes(s)).(en).(an).('score');
                
                %info_vis.(type).(scenes(s)).(an)(id,:) = ...
                 %   [0 DR_struct.(scenes(s)).(en).(an).('visibility')];
                info_vis.(type).(scenes(s)).(an)(id,1) = ...
                    Full_struct.(scenes(s)).(en).(an).('visibility');
                
%               info_pfa.(type).(scenes(s)).(an)(id,1) = ...
%                 Full_struct.(scenes(s)).(en).(an).('pfa');
% 
%               info_dr.(type).(scenes(s)).(an)(id,1) = ...
%                 Full_struct.(scenes(s)).(en).(an).('dr');
            end
        end
    end
end

%% Plot data

%xlabels = cellstr([ 'Full', strsplit(num2str(Qs))]);
xlabels = cellstr(replace(td_algs,'hyper',''));
f_names = fieldnames(info_mcc);

for t = 1:length(f_names)
    info_mcc_t = info_mcc.(f_names{t});
    info_vis_t = info_vis.(f_names{t});
    
 	FigH = figure('Name', f_names{t}, 'Renderer', 'painters',...
    'position', [10, 10, 2000,1200]);
        
    f_t_names = fieldnames(info_mcc_t);
    
    k = 0;
    
    for s = 1:length(f_t_names)
        scene_name = strrep(scenes(s),'_',' ');
        info_mcc_t_s = info_mcc_t.(f_t_names{s});
        info_vis_t_s = info_vis_t.(f_t_names{s});
        
        f_t_s_names = fieldnames(info_mcc_t_s);
       

        an = replace(td_algs,'hyper','');
        legend_entry = upper(["MCC","VIS"]);

        p_mcc = zeros(1,length(an));
        p_vis = zeros(1,length(an));
        for a = 1:length(an)
            i_mcc = info_mcc_t_s.(an(a));
            i_vis = info_vis_t_s.(an(a));
            
            switch s
                case 1
                    p_mcc(a) = mean(i_mcc([11,12])); 
                    p_vis(a) = mean(i_vis([11,12])); 
                case 2
                    p_mcc(a) = mean(i_mcc([2,5])); 
                    p_vis(a) = mean(i_vis([2,5])); 
                case 3
                    p_mcc(a) = mean(i_mcc); 
                    p_vis(a) = mean(i_vis); 
                case 4
                    p_mcc(a) = mean(i_mcc); 
                    p_vis(a) = mean(i_vis); 
                case 5
                    p_mcc(a) = mean(i_mcc); 
                    p_vis(a) = mean(i_vis); 
                otherwise
                    p_mcc(a) = mean(i_mcc); 
                    p_vis(a) = mean(i_vis); 
             end
           
        end
      
        p_vals=[p_mcc;p_vis];
        
        
        %bar graph
%         subplot(1,length(scenes), s);
%         barh(p_vals','grouped');
%         title(f_names{t} +" - "+ scene_name +" - MCC VIS");
%         grid on;
%         legend(legend_entry, 'location', 'best');
%         yticklabels(xlabels);
%         ylabel("Algorithm");
%     
%         
%         
        
        
     %line plot   
%         [Peak, PeakIdx] = max(p_mcc);
%         x =1:1:(length(an));
%         subplot(length(scenes),2, s+k);
%         hold on;
%         title(f_names{t} +" - "+ scene_name +" - MCC");
%         plot(p_mcc,'LineWidth',2);
%         plot(x(PeakIdx),Peak,'^','MarkerSize',20);
%         hold off;
%         grid on;
%         %legend(legend_entry(1), 'location', 'best');
%         xticks(1:1:(length(an)));
%         xticklabels(xlabels);
%         xlabel("Algorithm");
%         %ylim([0 1]);
%         
%         
%         [Peak, PeakIdx] = max(p_vis);
%         x =1:1:(length(an));
%         subplot(length(scenes),2, s+k+1);
%         hold on;
%         title(f_names{t} +" - "+ scene_name +" - VIS");
%         plot(p_vis,'LineWidth',2);
%         plot(x(PeakIdx),Peak,'^','MarkerSize',20);
%         hold off;
%         grid on;
%        % legend(legend_entry(2), 'location', 'best');
%         xticks(1:1:(length(an)));
%         xticklabels(xlabels);
%         xlabel("Algorithm");
%         %ylim([0 1]);
      

        %combined plot
        [PeakMCC, PeakIdxMCC] = max(p_mcc);
        [PeakVIS, PeakIdxVIS] = max(p_vis);
        x =1:1:(length(an));
        subplot(length(scenes),1, s);
        hold on;
        title(f_names{t} +" - "+ scene_name +" -MCC VIS");
        yyaxis left
        plot(p_mcc,'LineWidth',2);
        plot(x(PeakIdxMCC),PeakMCC,'^','MarkerSize',10);
        yyaxis right
        plot(p_vis,'LineWidth',2);
        plot(x(PeakIdxVIS),PeakVIS,'o','MarkerSize',10);
        hold off;
        grid on;
       % legend(legend_entry(2), 'location', 'best');
        xticks(1:1:(length(an)));
        xticklabels(xlabels);
        xlabel("Algorithm");
        %ylim([0 1]);
        
        set(gca, 'FontSize', 13);            
        set(gca, 'fontweight','bold');


        k = k+1;
            
    end
    
    F    = getframe(FigH);
    imwrite(F.cdata,join([f_names{t},'_scenes.png']), 'png')
end
