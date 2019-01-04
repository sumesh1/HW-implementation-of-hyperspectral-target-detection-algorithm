comparevalues.m		: used to compare detection statistic values from MATLAB and from HW accelerator. Specifically designed for Salinas cube prepared with prepsalinas.m 	
dechextxt.m			: used for preparation of hex file for SD card. 
dynamic_range.m		: loads Salinas cube and determines necessary fixed point formats for inverted correlation matrix and hyperspectral data with full and reduced dimensionality (PCA)
					for use in HW accelerator.
prepsalinas.m   	: used to prepare Salinas cube for HW accelerator (or comparison with SW generated data) with fixed point formats determined in dynamic_range.m
getColorMap.m		: shows used the map of detection statistic values using a specific color map
getMCC.m			: used to compare detection statistic map created target detection algorithm with ground truth, and calculate MCC score for given th
getThMap.m			: used to show the map of detection statistic values compared with threshold
gt_extract.m 		: used to create a figure showing different classes of groundtruth data using a custom color map
ShermanMorrison.m	: Sherman Morrison formula
showdistribution.m	: (test) showing pseudo-colored map of detection statistic values for Salinas ACE-R target detection using full-dim, PCA and MNF


gaussjordan.m		: Gauss-Jordan inversion code
lup.m 				: LUP decomposition code
 
