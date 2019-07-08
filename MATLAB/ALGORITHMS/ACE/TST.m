%% initial parameters
clc;
%choose scene number
s = 2;
%choose targt number
tg= 11;
%choose number of bands
q = 20;
%write files or just to workspace
w = 0;

%% LOAD CUBE

if(exist('gt_data_set')~=1)
    load('images.mat');
    fprintf('loaded dataset \n');
end

%% prepare dataset for SM testing

scenes      = string(fieldnames(gt_data_set));
scene       = gt_data_set.(scenes(s));
scene_name  = scenes(s);
M			= scene.cube;
signatures  = scene.signatures;

%remove all negative values
M(M(:)<0) = 0; 
signatures(signatures(:)<0) = 0;

% Do pca
[h,w,d] = size(M);
M_2d_pca = hyperConvert2d(M);
M_2d_pca = M_2d_pca';
[coeff,~,~,~,explained,~] = pca(M_2d_pca);
V = coeff(:,1:q);
M_pct = transpose(M_2d_pca*V);
%M_new = hyperConvert3d(M_pct,h,w,q);
M = M_pct;

signatures_pca = signatures*V;
target = signatures_pca(tg,:);

M16 = int16(M_pct); %cutting off a bit
target16 = int16(target);

%CUBE
Mwr=M16(:);
if (w == 1)
    i = dechextxt(Mwr,'cube.txt','uint16');
    i = dechextxt(target16(:),'target.txt','uint16');
end

%INVERSE CORRELATION
R = hyperCorr(double(M16));
G = inv(R);

m1 = max(G(:));
m2 = min(G(:));

p1 = abs(floor(2^31/m1));
p2 = abs(floor(2^31/m2));


if(p1 < p2)
    p1 = floor(log2(p1));
    shift = 2^p1;  
    fprintf("G shifted by %d \n",int32(p1));
else
    p2 = floor(log2(p2));
    shift = 2^p2;  
    fprintf("G shifted by %d \n",int32(p2));
end

G32 = int32(G*shift);

if (w == 1)
    i = dechextxt(G32(:),'matrix.txt','uint32'); %uint32 just for writing, it will write negative
end


%PREPARE sR^-1 vector
sR = double(target16)*G;

m1 = max(sR(:));
m2 = min(sR(:));

p1 = abs(floor(2^31/m1));
p2 = abs(floor(2^31/m2));

if(p1 < p2)
    p1 = floor(log2(p1));
    shift = 2^p1;  
    fprintf("sG shifted by %d \n",int32(p1));
else
    p2 = floor(log2(p2));
    shift = 2^p2;  
    fprintf("sG shifted by %d \n",int32(p2));
end

sR32 = int32(sR*shift);

if (w == 1)
    i = dechextxt(sR32,'stat.txt','uint32');
end

%sRs= sR*target';
sRs = sR*double(target16)';

p1 = abs(floor(2^31/sRs));
p1 = floor(log2(p1));
shift = 2^p1;  
fprintf("sGs shifted by %d \n",int32(p1));

sRs32 = int32(sRs*shift);

[results] = hyperAceRTF(double(M16), double(G32) ,double(sR32),double(sRs32));