% created by: Dordije Boskovic

% used to show the map of detection statistic values 

% ds_vector= input vector from TD algorithm
% th = threshold value


function [map,detected] = getThMap(ds_vector,m,n,th)

	
	if( m*n ~= length(ds_vector))
		  error('Error. Matrix must have same number of elements as detection statistic vector!');
	end
	
	temp =[];
	
	for i = 1 : length(ds_vector)
		if (ds_vector (i) >= th)
			temp(i) = 255;
		else
			temp(i) = 0;
		end
	end
	
	detected = sum(temp == 255);
	map = reshape( temp, m,n); 
	
	imshow(map);
	

end