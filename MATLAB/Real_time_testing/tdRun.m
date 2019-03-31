function [res_img,res_2d] = tdRun(M, end_sign, td_alg, param_1, param_2)

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
    case 3
        param_2 = -1;
        param_1 = -1;
    case 4
        param_2 = 1;
    case 5
        %nothing
    otherwise
        disp('Wrong number of arguments');
end

[h,w,d] = size(M);
%from_3d_to_2d = @(M) reshape(M, w*h, d).';
from_3d_to_2d = @(M) reshape(permute(M,[2 1 3]), w*h, d).';
from_2d_to_3d = @(M,h,w,d) reshape(M, h, w, d);

end_sign = end_sign';

M2d = from_3d_to_2d(M);

if param_1 == -1
    res_2d = feval(td_alg, M2d, end_sign);
else
    res_2d = feval(td_alg, M2d, end_sign, param_1, param_2);
end

res_img = from_2d_to_3d(res_2d,w,h,1);
res_img = res_img';
end