% created by: Dordije Boskovic

% used to compare detection statistic map created target detection algorithm
% with ground truth, and calculate MCC score for given th

% ds_vector= input vector from TD algorithm
% th = threshold value
% gt = ground truth matrix
% value = chosen ground truth component

function [auc,tpr,fpr] = getAUC (ds_vector, gt,value,spacing,plot_f)


	[m,n]=size(gt);
	
	if( m*n ~= length(ds_vector))
		  error('Error. GT matrix must have same number of elements as detection statistic vector!');
    end
    
    if(nargin<4)
        spacing = 10000;
        plot_f = 0;
    elseif(nargin<5)
        plot_f = 0;
    end
	
	map = reshape( ds_vector, m, n);
	
    %thres =  0.0001:0.0001:1.0000;
    thres = linspace(min(ds_vector)-min(ds_vector)/10,...
                     max(ds_vector)+max(ds_vector)/10,spacing);

    tpr = zeros(numel(thres),1); 
    fpr = zeros(numel(thres),1); 

	positives = sum(gt(:) == value);
    negatives = m*n - positives;

    for i= 1:numel(thres)
    
        th = thres(i);
        tp=0;
        fp=0;
        fn=0;
        tn=0;

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
        
        tpr(i) = tp;
        fpr(i) = fp;    
        
    end	
            
    %ROC 
    tpr= tpr./positives;
    fpr= fpr./negatives;
    
    tpr = tpr(end:-1:1);
    fpr = fpr(end:-1:1);
    
    if(plot_f)
        figure;
        plot(fpr,tpr,'-','Linewidth',2);
        set(gca, 'FontSize', 12);            
        set(gca, 'fontweight','bold');
      %  set(gca, 'XScale', 'log');
    end

    auc=trapz(fpr,tpr);          



end