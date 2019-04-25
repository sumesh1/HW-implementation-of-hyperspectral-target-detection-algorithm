% created by: Dordije Boskovic

% used to compare detection statistic map created target detection algorithm
% with ground truth, and calculate MCC score for given th

% ds_vector= input vector from TD algorithm
% th = threshold value
% gt = ground truth matrix
% value = chosen ground truth component

function [mcc,vis,auc,tpr,fpr] = getMCC (ds_vector, gt, value, thres)

    if(nargin<4)
        %thres =  0.0001:0.0001:1.0000;
        thres = linspace(min(ds_vector)-min(ds_vector)/10,max(ds_vector)+max(ds_vector)/10,10000);
    end

	[m,n]=size(gt);
	
	if( m*n ~= length(ds_vector))
		  error('Error. GT matrix must have same number of elements as detection statistic vector!');
	end
	
	map = reshape( ds_vector, m,n);
	
	tp=0;
	fp=0;
    tpr=[];
    fpr=[];
	fn=0;
	tn=0;
    mccmax=0;
    mcc_func = @(tp,tn,fp,fn) (tp*tn-fp*fn)/(sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn))) ;

	positives = sum(gt(:)==value);
    negatives = m*n-positives;

 for i= 1:numel(thres)
    
    th = thres(i);
    tp=0;
	fp=0;
	fn=0;
	tn=0;
    mcc=0;
     
        for j = 1:m
            for k = 1:n            

                if and(gt(j,k) == value, map(j,k) >= th)
                    tp = tp + 1;
                elseif and(gt(j,k) == value, map(j,k) < th)
                    fn = fn + 1;
                elseif map(j,k) >= th
                    fp = fp + 1;
                else
                    tn = tn + 1;
                end      

            end
        end
        
        tpr=[tpr,tp];
        fpr=[fpr,fp];
        mcc = mcc_func(tp,tn,fp,fn);
        
        if(mcc>mccmax)
            mccmax=mcc;
        end
        
 end	
 
 mcc=mccmax;
 
 
    T_t_sum = 0; T_t_count = 0;
            T_b_sum = 0; T_b_count = 0;
  for j = 1:m
                for k = 1:n
                    if gt(j,k) == value
                        T_t_sum     = T_t_sum + map(j,k);
                        T_t_count   = T_t_count +1;
                    else
                        T_b_sum     = T_b_sum + map(j,k);
                        T_b_count   = T_b_count +1;
                        
                    end
                end
            end
            T_t_avg = T_t_sum / T_t_count;
            T_b_avg = T_b_sum / T_b_count;
            
            T_max = max(map(:)); T_min = min(map(:));
            
            vis = norm(T_t_avg - T_b_avg)/(T_max - T_min);
 
            
            %toc
 if(numel(thres)>1)
  figure;
  plot(fpr+tpr,tpr,'Linewidth',2);
   hold on
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
%   %  legend(legend_entry, 'location','northeastoutside');
figure;
 tpr= tpr./positives;
 fpr= fpr./negatives;
% % %  figure 
  plot(fpr,tpr,'-','Linewidth', 2);
  %hold on
 % plot(fpr(1:100:end),tpr(1:100:end),'*r');
         auc=trapz(fpr,tpr); 
 end           
            
            
% tpr= tpr./positives;
 %fpr= fpr./negatives;
 

if(numel(thres)>1)
   % semilogx(fpr,tpr,'Linewidth',4);
   % auc=trapz(fpr,tpr);           
end           
% MCC score function
	%mcc_func = @(tp,tn,fp,fn) (tp*tn-fp*fn)/(sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn))) ;

	%mcc = mcc_func(tp,tn,fp,fn);

end