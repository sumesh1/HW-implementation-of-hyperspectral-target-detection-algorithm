function [fig, res_img, res_prob] = td_results(M, gt, end_name, end_sign, end_index, abundance, scene_name, td_alg, background)

% M,         A 3 dimensional datacube
% gt,        a spatial 2d representation of the different classes in the image
% end_name,  the name of the endmember to be detected
% end_sign,  the signature of the endmember to be detected
% end_index, the index of the endmember to be detected
% abundance, the number of target pixels in the image
% td_alg,    the function name of the algorithms used to do detection
% background the estimated backgroudn if relevant for the detection algorithm

%number_of_bins = round(0.25*abundance);

switch nargin
    case 8
        background = -1;
    case 9
        %Do nothing;
    otherwise
        disp('Wrong number of arguments');
end

[h,w,d] = size(M);
from_3d_to_2d = @(M) reshape(M, w*h, d).';
from_2d_to_3d = @(M,h,w,d) reshape(M.', h, w, d);

end_sign = end_sign';

M2d = from_3d_to_2d(M);

if background == -1
    res_2d = feval(td_alg,M2d, end_sign);
else
    res_2d = feval(td_alg, M2d, background, end_sign);
end

res_prob = zeros(1,abundance);
res_img = from_2d_to_3d(res_2d,h,w,1);
[rows, columns] = find(gt == end_index);

for i = length(rows)
    res_prob(i) = res_img(rows(i),columns(i));
end

fig = histogram(res_prob,20);
title([end_name erase(td_alg,'hyper') replace(scene_name,'_',' ')]);

fig = 3;

end