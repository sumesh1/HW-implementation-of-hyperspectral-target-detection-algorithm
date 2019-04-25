testInit;
warning('off');

results_Full = struct;
results_Full_PI = struct;

max_step = length(td_algs)*length(scenes);

%% test - loop
for s = 1:length(scenes)
    scene       = gt_data_set.(scenes(s));
    scene_name  = scenes(s);
    M			= scene.cube;
    gt			= scene.gt;
    
    if(scene_name=="hymap")
        gt=scene.gt_fullsub;    
    end
    
    %  PCA ON OFF
    [h,w,d] = size(M);
    M_2d = hyperConvert2d(M);
    M_2d = M_2d';
    
    if(PCA) 
       [coeff,~,~,~,explained,~] = pca(M_2d);
    end
       
    for a = 1:length(td_algs)
        td_alg = td_algs(a);
        
        current_step = current_step +1;
        disp(sprintf("Current progress %.2f %%",...
                current_step/max_step*100));
        
        for id = 1:size(scene.signatures,1)
            end_name	= scene.endmembers(id);
            end_sign	= scene.signatures(id,:);
            end_index	= id;
            abundance	= scene.abundance(id);
            
            
            if(scene_name=="hymap")
                abundance = scene.abundance_fullsub(id); 
                end_sign  = scene.signatures_corrected(id,:);
            end
    
            
            en = replace(end_name,' ','_');
            en = replace(en,'-','_');
            an = replace(td_alg,'hyper','');
            
            % Store in struct
            results_Full.(scenes(s)).(en).(an).('Qlist') = Qs;
            results_Full.(scenes(s)).(en).(an).('abundance') = abundance;
            
            r_id = 1;
            
          
            M_new = M;
            end_sign_new = end_sign;
            
            if(training_portion < 1)
                T = datasample(transpose(hyperConvert2d(M_new)),...
                 floor(h*w*training_portion));
            else 
                T = transpose(hyperConvert2d(M_new));
            end 
            
            T = T';
            
            if(PCA)
                q = Qs(r_id);
                V = coeff(:,1:q);
                M_pct = transpose(M_2d*V);
                T = transpose(M_2d*V);
                M_new = hyperConvert3d(M_pct,h,w,q);
                end_sign_new = end_sign*V;
            end
            
            % Calculate score
            if td_alg == "hyperOsp"
                numEndmembers = length(scene.endmembers);
                B = getBackground(M_new, numEndmembers, end_sign_new);
                probability_img = tdRun(M_new, end_sign_new,...
                    td_alg, T, B);
            elseif td_alg == "hyperSam"
                probability_img = tdRun(M_new, end_sign_new, td_alg);
            else
               % probability_img = tdRun(M_new, end_sign_new, ...
               %     td_alg,  T);
               probability_img = tdRun(M_new, end_sign_new, td_alg);
            end
            
            %should not be needed
            %probability_img = normalize(probability_img);
            
            % Measure score
            xx = size(gt,1); yy = size(gt,2);
            
            tp = 0; tn = 0;
            fp = 0; fn = 0;
            
           % P_FA = min(probability_img(:)):0.001:max(probability_img(:));
            P_FA = linspace(min(probability_img(:)),max(probability_img(:)),P_FA_STEP);
            met = zeros(length(P_FA),3);
            
            for i = 1:length(P_FA)
                for j = 1:xx
                    for k = 1:yy
                        if and(gt(j,k) == id, probability_img(j,k) >= P_FA(i))
                            tp = tp + 1;
                        elseif and(gt(j,k) == id, probability_img(j,k) < P_FA(i))
                            fn = fn + 1;
                        elseif probability_img(j,k) >= P_FA(i)
                            fp = fp + 1;
                        else
                            tn = tn + 1;
                        end
                    end
                end
                
                met(i,:) = [metric(tp,tn,fp,fn); tp; fp;];
                tp = 0; tn = 0;
                fp = 0; fn = 0;
            end
            
            % Calculate Visibility
            T_t_sum = 0; T_t_count = 0;
            T_b_sum = 0; T_b_count = 0;
            
            for j = 1:xx
                for k = 1:yy
                    if gt(j,k) == id
                        T_t_sum     = T_t_sum + probability_img(j,k);
                        T_t_count   = T_t_count +1;
                    else
                        T_b_sum     = T_b_sum + probability_img(j,k);
                        T_b_count   = T_b_count +1;
                        
                    end
                end
            end
            T_t_avg = T_t_sum / T_t_count;
            T_b_avg = T_b_sum / T_b_count;
            
            T_max = max(probability_img(:)); T_min = min(probability_img(:));
            vis = norm(T_t_avg - T_b_avg)/(T_max - T_min);
            
            % Store score
            [max_score, max_index] = max(met(:,1));
            
            %probability of false alarm under 100% detection
            max_det = max(met(:,2));
            max_index_det = find(met(:,2)==max_det);
            search_range = met(max_index_det,3);
            p_f_a = min(search_range)/(xx*yy-abundance);
            
            %detection rate under 0% false alarm rate
            min_fa = min(met(:,3));
            min_index_fa = find(met(:,3)==min_fa);
            search_range = met(min_index_fa,2);
            p_c_a = max(search_range)/abundance;
          
            
            results_Full.(scenes(s)).(en).(an).('maxdet')(r_id) = max_det;
            results_Full.(scenes(s)).(en).(an).('pfa')(r_id) = p_f_a;
            results_Full.(scenes(s)).(en).(an).('minfa')(r_id) = min_fa;
            results_Full.(scenes(s)).(en).(an).('dr')(r_id) = p_c_a;
            results_Full.(scenes(s)).(en).(an).('tp') = met(:,2);
            results_Full.(scenes(s)).(en).(an).('fp') = met(:,3);
            results_Full.(scenes(s)).(en).(an).('score')(r_id) = max_score;
            results_Full.(scenes(s)).(en).(an).('visibility')(r_id) = vis;
            
            results_Full_PI.(scenes(s)).(en).(an).(...
                sprintf("probability_img_full")) = probability_img;
            
            
        end
    end
end