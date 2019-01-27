% modified by: Dordije Boskovic
% adapted from code by: Sivert Bakken 

% used to calculate Spectral Angle Mapper (SAM) detection statistic
% M = input data, reordered hyperCube
% target = input target vector

function [results] = hyperSam(M,target)

% p is number of spectral components 
	[p,N]=size(M);
	
% initialize results vector, N is number of pixels	
	results=zeros(N,1);

% can use either of two functions

	%r_sam=@(x,s) -acos((s'*x)/sqrt((s'*s)*(x'*x)));
	r_sam=@(x,s) ((s'*x)*(s'*x)/((s'*s)*(x'*x)));

	for i=1:N

		calculated_sam = r_sam (M(:,i),target);
    
		results(i,:) = calculated_sam;
    
    end
    
end

