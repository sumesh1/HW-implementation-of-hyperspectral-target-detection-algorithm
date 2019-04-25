%% initial parameters
%clc;
%choose scene number
s = 6;
%choose target number
tg= 1;
%choose number of bands
%q = 20;
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
gt          = scene.gt;


if(scene_name == "hymap")
   gt = scene.gt_fullsub; 
   x = 90;
   y = 458;
   sizecut = 90 - 1;
   
   M  = M(x:(x+sizecut),y:(y+sizecut),:);
   gt = gt(x:(x+sizecut),y:(y+sizecut));
end


%remove all negative values
%M(M(:)<0)=0; 
%signatures(signatures(:)<0)=0;

% Do pca
[h,w,d] = size(M);
M = hyperConvert2d(M);
%M=M*3;

target = signatures(tg,:);

M16=int16(M); %cutting off a bit
target16=int16(target);

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



%FOR FPGA
if (w == 1)
     fileID = fopen('spca.bin','w');
     fwrite(fileID,M16,'int16');
     fclose(fileID);


     fileID = fopen('tpca.bin','w');
     fwrite(fileID,target16,'int16');
     fclose(fileID);
end

add_frac = ceil(log2(d));
pixbw  = 15;
brambw = 30;
outbw  = 30;
s1 = pixbw + add_frac + brambw - outbw -1;
s2 = pixbw + add_frac + outbw - outbw -1;
s3 = pixbw + add_frac + brambw - outbw -1;
s4 = outbw-1;
s5 = outbw-1;
sliders=[s1 s2 s3 s4 s5]-5;

resACER = hyperAceR_FP(double(M16),double(target16)',pixbw,brambw,outbw);
resASMF = hyperASMF_FP(double(M16),double(target16)',pixbw,brambw,outbw);
resASMF2 = hyperASMF2_FP(double(M16),double(target16)',pixbw,brambw,outbw);
resCEM = hyperCem_FP(double(M16),double(target16)',pixbw,brambw,outbw);
%clearvars -except M q gt_data_set





