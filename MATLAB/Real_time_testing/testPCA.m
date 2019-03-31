testInit;
warning('off');
results_PCA = struct;

%% test parameters - fast run
fast_run = 1;
if fast_run
    td_algs = td_algs;
    scenes  = scenes([1,2,3,5]);
    %Qs = Qs(1:3);
    Qs = [50];
end

%% test - loop
current_step = 0;
max_step = 2040; % approximately for all tests

for s = 1:length(scenes)
    scene       = gt_data_set.(scenes(s));
    scene_name  = scenes(s);
    M			= scene.cube;
    gt			= scene.gt;
    
    % Do pca
    [h,w,d] = size(M);
    M_2d_pca = hyperConvert2d(M);
    M_2d_pca = M_2d_pca';
    [coeff,~,~,~,explained,~] = pca(M_2d_pca);
    
    for a = 1:length(td_algs)
        td_alg = td_algs(a);
        
        for id = 1:size(scene.signatures,1)
            end_name	= scene.endmembers(id);
            end_sign	= scene.signatures(id,:);
            end_index	= id;
            abundance	= scene.abundance(id);
            
            en = replace(end_name,' ','_');
            en = replace(en,'-','_');
            an = replace(td_alg,'hyper','');
            
            % Store in struct
            results_PCA.(scenes(s)).(en).(an).('Qlist') = Qs;
            results_PCA.(scenes(s)).(en).(an).('abundance') = abundance;
            
            for r_id = 1:length(Qs)
                current_step = current_step + 1;
                disp(sprintf("Current progress %.2f %%",...
                    current_step/max_step*100));
                
                q = Qs(r_id);
                
                %Project
                V = coeff(:,1:q);
                M_pct = transpose(M_2d_pca*V);
                M_new = hyperConvert3d(M_pct,h,w,q);
                end_sign_new = end_sign*V;
                
                % Calculate score
                if td_alg == "hyperAceR_NT"
                    probaility_image = tdRun(M_new, end_sign_new, td_alg, gt, end_index);
                elseif td_alg == "hyperCem_NT" 
                    probaility_image = tdRun(M_new, end_sign_new, td_alg, gt, end_index);
                else    
                    probaility_image = tdRun(M_new, end_sign_new, td_alg);
                end
                
                %should not be needed
                probaility_image = normalize(probaility_image); %not from matlab toolbox
                
                % Measure score
                xx = size(gt,1); yy = size(gt,2);
                
                tp = 0; tn = 0;
                fp = 0; fn = 0;
                
                P_FA = 0:0.001:1.0000;
                met = zeros(length(P_FA),3);
                
                for i = 1:length(P_FA)
                    for j = 1:xx
                        for k = 1:yy
                            if and(gt(j,k) == id, probaility_image(j,k) >= P_FA(i))
                                tp = tp + 1;
                            elseif and(gt(j,k) == id, probaility_image(j,k) < P_FA(i))
                                fn = fn + 1;
                            elseif probaility_image(j,k) >= P_FA(i)
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
                            T_t_sum     = T_t_sum + probaility_image(j,k);
                            T_t_count   = T_t_count + 1;
                        else
                            T_b_sum     = T_b_sum + probaility_image(j,k);
                            T_b_count   = T_b_count + 1;
                            
                        end
                    end
                end
                T_t_avg = T_t_sum / T_t_count;
                T_b_avg = T_b_sum / T_b_count;
                
                T_max = max(probaility_image(:)); T_min = min(probaility_image(:));
                vis = norm(T_t_avg - T_b_avg)/(T_max - T_min);
                
                % Store score
                [max_score, max_index] = max(met(:,1));
                p_c_a = met(max_index,2)/abundance;
                p_f_a = met(max_index,3)/abundance;
                
                
                %prepare ROC / AUC
                tpr = met(:,2)'./ abundance;
                fpr = met(:,3)'./ (xx*yy-abundance);
                auc = trapz(fliplr(fpr),fliplr(tpr));
                
                results_PCA.(scenes(s)).(en).(an).('ca')(r_id) = p_c_a;
                results_PCA.(scenes(s)).(en).(an).('wa')(r_id) = p_f_a;
                results_PCA.(scenes(s)).(en).(an).('score')(r_id) = max_score;
                results_PCA.(scenes(s)).(en).(an).('visibility')(r_id) = vis;
                results_PCA.(scenes(s)).(en).(an).('auc')(r_id) = auc;
                results_PCA.(scenes(s)).(en).(an).('tpr')(:,r_id) = tpr';
                results_PCA.(scenes(s)).(en).(an).('fpr')(:,r_id) = fpr';
                
            end
        end
    end
end

%clearvars -except results_PCA