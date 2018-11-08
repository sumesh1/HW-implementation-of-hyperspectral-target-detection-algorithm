% created by: Dordije Boskovic

% used to compare detection statistic map created target detection algorithm
% with ground truth, and calculate MCC score for given th

% ds_vector= input vector from TD algorithm
% th = threshold value
% gt = ground truth matrix
% value = chosen ground truth component

function [mcc] = getMCC (ds_vector, th, gt, value)

	[m,n]=size(gt);
	
	if( m*n ~= length(ds_vector))
		  error('Error. GT matrix must have same number of elements as detection statistic vector!');
	end
	
	map = reshape( ds_vector, m,n);
	
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
	
% MCC score function
	mcc_func = @(tp,tn,fp,fn) (tp*tn-fp*fn)/(sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn))) ;

	mcc = mcc_func(tp,tn,fp,fn);

end