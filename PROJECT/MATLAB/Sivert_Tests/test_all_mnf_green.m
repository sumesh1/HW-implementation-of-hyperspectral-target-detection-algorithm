td_test_init;


%% test 1 - loop
q = 50;
score_csv = 'Name;score;c/a;w/a;\n';
score_struct = struct;

for s = 1:length(scenes)
    for temp = 1:size(ids,2)
        for a = 1:length(td_algs)
            id = ids(s,temp);
            
            %set params
            scene = gt_data_set.(scenes(s));
            M			= scene.cube;
            %M			= scene.corrected;
            gt			= scene.gt;
            end_name	= scene.endmembers(id);
            end_sign	= scene.signatures(id,:);
            %end_sign	= scene.signatures_corrected(id,:);
            end_index	= id;
            abundance	= scene.abundance(id);
            td_alg		= td_algs(a);
            %end set params

            % do mnf
            [h,w,d] = size(M);
            
            [Mg_mnf, Ag_mnf] = GreenMNF(M);
            Ag_mnf_inv = inv(Ag_mnf);
            
            M_new_mnf = Mg_mnf(:,:,1:q);
            T = Ag_mnf_inv(:,1:q);
            
            end_sign_new = end_sign*transpose(pinv(T));
            
            %Calculate score
            if td_alg == "hyperOsp"
                numEndmembers = length(scene.endmembers);
                B = getBackground(M_new_mnf, numEndmembers, end_sign_new);
                [a1, b1, ~] = td_results(M_new_mnf, gt, end_name, end_sign_new,...
                    end_index, abundance, scenes(s), td_alg, B);
                
            else
                [a1, b1, ~] = td_results(M_new_mnf, gt, end_name, end_sign_new,...
                    end_index, abundance, scenes(s), td_alg);
            end
            
            b1 = normalize(b1);
            % Measure score
            xx = size(gt,1); yy = size(gt,2);
            
            tp = 0; tn = 0;
            fp = 0; fn = 0;
            
            P_FA = 0.0001:0.0001:1.0000;
            met = zeros(length(P_FA),3);
            
            for i = 1:length(P_FA)
                for j = 1:xx
                    for k = 1:yy
                        if and(gt(j,k) == id, b1(j,k) >= P_FA(i))
                            tp = tp + 1;
                        elseif and(gt(j,k) == id, b1(j,k) < P_FA(i))
                            fn = fn + 1;
                        elseif b1(j,k) >= P_FA(i)
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
                        T_t_sum     = T_t_sum + b1(j,k);
                        T_t_count   = T_t_count +1;
                    else
                        T_b_sum     = T_b_sum + b1(j,k);
                        T_b_count   = T_b_count +1;
                        
                    end
                end
            end
            T_t_avg = T_t_sum / T_t_count;
            T_b_avg = T_b_sum / T_b_count;
            
            T_max = max(b1(:)); T_min = min(b1(:));
            
            vis = norm(T_t_avg - T_b_avg)/(T_max - T_min);
            
            % store score
            [max_score, max_index] = max(met(:,1));
            p_c_a = met(max_index,2)/abundance;
            p_f_a = met(max_index,3)/abundance;
            
            name = replace(join([erase(td_alg,'hyper') replace(scenes(s),'_','') end_name]),' ','_');
              result = sprintf('%s;%d;%d;%d;%d;%d\n',name,max_score,p_c_a,p_f_a,abundance,vis);
            score_csv = join([score_csv result]);
            
            end_name_alt = replace(end_name,' ','_');
            end_name_alt = replace(end_name_alt,'-','_');
            alg_name = replace(td_alg,'hyper','');
            
            result_struct.(scenes(s)).(end_name_alt).(alg_name).('ca') = p_c_a;
            result_struct.(scenes(s)).(end_name_alt).(alg_name).('wa') = p_f_a;
            result_struct.(scenes(s)).(end_name_alt).(alg_name).('score') = max_score;
            result_struct.(scenes(s)).(end_name_alt).(alg_name).('abundance') = abundance;
            result_struct.(scenes(s)).(end_name_alt).(alg_name).('visibility') = vis;
            
        end
    end
end

fid = fopen('result_full_mnf20.csv','a');
fprintf(fid, score_csv);
fprintf(fid, '\n');
fclose(fid);

disp('done!');




