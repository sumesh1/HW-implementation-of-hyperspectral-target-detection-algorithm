% created by: Dordije Boskovic

% used to show the map of detection statistic values 

% ds_vector= input vector from TD algorithm


function [map] = getColorMap(ds_vector, m , n)

	
	if( m*n ~= length(ds_vector))
		  error('Error. Matrix must have same number of elements as detection statistic vector!');
	end
	
	temp = reshape( uint8(ds_vector*255), m,n);
	
	pseudoColoredImage = ind2rgb(temp, jet);
	imshow(pseudoColoredImage);
	map=temp;
	

end