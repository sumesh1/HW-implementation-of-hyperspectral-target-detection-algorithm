clc;

%defaults
s = 2;
em = 11;    
beta = 1000;
wlen = 35;
alg = 2;
delay = 20;
sw = 1;
PCA = 20;

%% LOAD SCENE AND PREPARATION
if(exist('gt_data_set')~=1)
    load('images.mat');
    fprintf('loaded dataset \n');
end
    
scenes  = string(fieldnames(gt_data_set));


%% PROMPTS 
prompt = sprintf ('Default (%d bits), yes or no?: \n',wlen);
def = input(prompt);

if(~def) 
    prompt = 'Select scene: \n';
    disp(scenes);
    s = input(prompt);

    scene  = gt_data_set.(scenes(s));
    endmembers = scene.endmembers;
    prompt = 'Select endmember: \n';
    disp(endmembers);
    em = input(prompt);

    prompt = sprintf('Select beta (default %d): \n',beta);
    beta = input(prompt);

    prompt = 'Select word length: \n';
    wlen = input(prompt);   

    prompt = 'Select algorithm: \n';
    disp('CEM ACER ASMF');
    alg = input(prompt);
    
    prompt = 'Select PCA q: (if 0, no PCA) \n';
    PCA = input(prompt);
    
    M		= scene.cube;
    [m,n,d] = size(M);
    prompt = 'Select delay: \n';
    fprintf('Default: %d \n',d);
    delay = input(prompt);
    
end
 
scene       = gt_data_set.(scenes(s));
scene_name  = scenes(s);
M			= scene.cube;
endmembers = scene.endmembers;
signatures = scene.signatures;
gt = scene.gt; 
target = signatures(em,:)';


if(scene_name == "hymap")
   gt = scene.gt_fullsub; 
   x = 90;
   y = 458;
   sizecut = 90 - 1;
   
   M  = M(x:(x+sizecut),y:(y+sizecut),:);
   gt = gt(x:(x+sizecut),y:(y+sizecut));
   signatures=gt_data_set.hymap.signatures_corrected;
   target = signatures(em,:)';
end


if(PCA)
    q = PCA;
    [h,w,d] = size(M);
    M_2d = hyperConvert2d(M);
    M_2d = M_2d';
    [coeff,~,~,~,explained,~] = pca(M_2d);
    V = coeff(:,1:q);
    M_pct = transpose(M_2d*V);
    T = transpose(M_2d*V);
    M = hyperConvert3d(M_pct,w,h,q);
    end_sign_new = signatures*V;
    target = end_sign_new(em,:)';
    M=M_pct;
else


M = hyperConvert2d(M);
end

num_bands  = size(M,1);
num_pixels = size(M,2);



%% SCALE VALUES TO FIXED POINT
t= max(M(:));
M = M./ t;  %scaling
target = target ./ t;



fprintf('\n after treatment: \n');
fprintf('max value in cube: %f \n' ,max(M(:)));
fprintf('min value in cube: %f \n' ,min(M(:)));
fprintf('mean value in cube: %f \n',mean(M(:)));

oldmerr = 0;
merr    = 0;
rxfl    = 0;
tdfl    = 0;
tdivfl  = 0;


%% True Value
R_true = M*M' + (1/beta)*eye(num_bands,num_bands); %not divided by num_pixels
G_true = inv(R_true);
    
%% Create matrix
  
resultsCEM      = zeros(num_pixels,1);
resultsACER     = zeros(num_pixels,1);
resultsASMF     = zeros(num_pixels,1);
resultsASMF2    = zeros(num_pixels,1);
results_fpCEM   = zeros(num_pixels,1);
results_fpACER  = zeros(num_pixels,1);
results_fpASMF  = zeros(num_pixels,1);
results_fpASMF2 = zeros(num_pixels,1);

smerr      = zeros(num_pixels,1);
 
R_inv_init = (beta) * eye(num_bands ,num_bands);
An         = R_inv_init;

fm = fimath('RoundingMethod', 'Floor',...
	     'OverflowAction', 'Wrap',...
	     'ProductMode','FullPrecision',...
	     'MaxProductWordLength', 128,...
	     'SumMode','FullPrecision',...
	     'MaxSumWordLength', 128);
     
A       = fi(An, 1, wlen, 24 + (wlen-35), fm );
targ_fp = fi(target, 1, 16 , 15, fm);
M_fp    = fi(M, 1, 16, 15, fm );

switch alg
    case 1
     algorithm = @(x,An,target) (x'*An*target)/(target'*An*target); %CEM
    otherwise
     algorithmCEM = @(x,An,target) (x'*An*target)/(target'*An*target); %CEM
     algorithmACER = @(x,An,target) (target'*An*x)^2/((target'*An*target)*(x'*An*x)); %ACER
     algorithmASMF = @(x,An,target) abs(target'*An*x)*(target'*An*x)/((target'*An*target)*abs(x'*An*x)); %ASMF
     algorithmASMF2 = @(x,An,target) abs(target'*An*x)^2*(target'*An*x)/((target'*An*target)*abs(x'*An*x)^2); %ASMF-2
end

%% CALCULATE 

P = fipref;
P.LoggingMode = 'on';

%dbstop if warning fi:overflow

for i = 1: delay

    x = M(:,i);   
    u = M_fp(:,i);
    
    %floating Sherman
    [An]=ShermanMorrisonRTF(An,x);
   
    %fixed Sherman   
    TRx = fi(A*u, 1, wlen, 24 + (wlen-35), fm);
    
    TRxxR = fi(TRx * TRx', 1, wlen+ 7, 13+7 + (wlen-35), fm);
    Td = fi(u' * TRx, 1, wlen, 17 + (wlen-35), fm);%17
    Tdiv = fi(1/(double(Td)+1), 1, wlen, 32 + (wlen-35), fm);
    TT = fi(TRxxR .* Tdiv, 1, wlen, 24 + (wlen-35), fm);
    Anew = fi(A - TT, 1, wlen, 24 + (wlen-35), fm);
    
    A = Anew;
    
    oldmerr = merr;
    err = abs(An-double(A)) ./ abs(An);
    merr = vpa(100*mean(err(:)));
    smerr(i) = merr;
    fprintf("iteration %d, err = %f, diff = %f \n",i,merr,merr-oldmerr);
  % fprintf("iteration %d, max(Rx) = %f \n",i,double(max(abs(double(TRx)))));
  % fprintf("iteration %d, max(RxxR) = %f \n",i,double(max(abs(double(TRxxR(:))))));
  % fprintf("iteration %d, Td = %f \n",i,double(Td));
  % fprintf("iteration %d, Tdiv = %f \n",i,double(Tdiv));
  
  % rxfl=[rxfl,double(max(abs(double(TRx))))];
  % tdfl=[tdfl,double(Td)];
  % tdivfl=[tdivfl,double(Tdiv)];

end


for i = 1: num_pixels

    x = M(:,i);   
    u = M_fp(:,i);
   
    %fixed cem
    if(sw==0)
        TDTRx = fi(A * u, 1, wlen, 24 + (wlen-35), fm);
        TRs   = fi(A * targ_fp , 1 , wlen, 24 + (wlen-35), fm);
        SRs   = fi(targ_fp' * TRs,1, wlen, 22 + (wlen-35), fm);
        SRx   = fi(targ_fp' * TDTRx, 1, wlen, 22 + (wlen-35), fm);
        XRx   = fi(u' * TDTRx, 1, wlen, 22 + (wlen-35), fm);%33
        SRx2  = fi(SRx*SRx, 1, wlen, 22 + (wlen-35), fm);
        XRx2   = fi(XRx*XRx, 1, wlen, 22 + (wlen-35), fm); %34
        tmp2  = fi(SRs*XRx, 1, wlen, 22 + (wlen-35), fm); %27
        SRxAb = fi(abs(SRx), 1, wlen, 22 + (wlen-35), fm);
        XRxAb = fi(abs(XRx), 1, wlen, 22 + (wlen-35), fm); %33
        tmp3  = fi(SRx*SRxAb, 1, wlen, 22 + (wlen-35), fm);
        tmp4  = fi(SRs*XRxAb, 1, wlen, 22 + (wlen-35), fm); %overflow -27
        tmp5  = fi(SRx*SRx2, 1, wlen, 22 + (wlen-35), fm); %overflow 28
        tmp6  = fi(SRs*XRx2, 1, wlen, 22 + (wlen-35), fm); %overflow -27
    else
%         TDTRx = fi(A * u, 1, wlen, 28 + (wlen-35), fm);
%         TRs   = fi(A * targ_fp , 1 , wlen, 28 + (wlen-35), fm);
%         SRs   = fi(targ_fp' * TRs,1, wlen, 26 + (wlen-35), fm);
%         SRx   = fi(targ_fp' * TDTRx, 1, wlen, 26 + (wlen-35), fm);
%         XRx   = fi(u' * TDTRx, 1, wlen, 26 + (wlen-35), fm);%33
%         SRx2  = fi(SRx*SRx, 1, wlen, 26 + (wlen-35), fm);
%         XRx2   = fi(XRx*XRx, 1, wlen, 26 + (wlen-35), fm); %34
%         tmp2  = fi(SRs*XRx, 1, wlen, 26 + (wlen-35), fm); %27
%         SRxAb = fi(abs(SRx), 1, wlen, 26 + (wlen-35), fm);
%         XRxAb = fi(abs(XRx), 1, wlen, 26 + (wlen-35), fm); %33
%         tmp3  = fi(SRx*SRxAb, 1, wlen, 26 + (wlen-35), fm);
%         tmp4  = fi(SRs*XRxAb, 1, wlen, 26 + (wlen-35), fm); %overflow -27
%         tmp5  = fi(SRx*SRx2, 1, wlen, 26 + (wlen-35), fm); %overflow 28
%         tmp6  = fi(SRs*XRx2, 1, wlen, 26 + (wlen-35), fm); %overflow -27
        TDTRx = fi(A * u, 1, wlen, 28 + (wlen-35), fm);
        TRs   = fi(A * targ_fp , 1 , wlen, 28 + (wlen-35), fm);
        SRs   = fi(targ_fp' * TRs,1, wlen, 26 + (wlen-35), fm);
        SRx   = fi(targ_fp' * TDTRx, 1, wlen, 26 + (wlen-35), fm);
        XRx   = fi(u' * TDTRx, 1, wlen, 26 + (wlen-35), fm);%33
        SRx2  = fi(SRx*SRx, 1, wlen, 26 + (wlen-35), fm);
        XRx2   = fi(XRx*XRx, 1, wlen, 26 + (wlen-35), fm); %34
        tmp2  = fi(SRs*XRx, 1, wlen, 26 + (wlen-35), fm); %27
        SRxAb = fi(abs(SRx), 1, wlen, 26 + (wlen-35), fm);
        XRxAb = fi(abs(XRx), 1, wlen, 26 + (wlen-35), fm); %33
        tmp3  = fi(SRx*SRxAb, 1, wlen, 26 + (wlen-35), fm);
        tmp4  = fi(SRs*XRxAb, 1, wlen, 26 + (wlen-35), fm); %overflow -27
        tmp5  = fi(SRx*SRx2, 1, wlen, 26 + (wlen-35), fm); %overflow 28
        tmp6  = fi(SRs*XRx2, 1, wlen, 26 + (wlen-35), fm); %overflow -27
    end

%     TDTRx = fi(A * u, 1, wlen, 24+ (wlen-35), fm);
%     TRs   = fi(A * targ_fp , 1 , wlen, 24 + (wlen-35), fm);
%     SRs   = fi(targ_fp' * TRs,1, wlen, 17 + (wlen-35), fm);
%     SRx   = fi(targ_fp' * TDTRx, 1, wlen, 17 + (wlen-35), fm);
%     XRx   = fi(u' * TDTRx, 1, wlen, 17 + (wlen-35), fm);%33
%     SRx2  = fi(SRx*SRx, 1, wlen, 15 + (wlen-35), fm);
%     XRx2  = fi(XRx*XRx, 1, wlen, 15 + (wlen-35), fm); %34
%     tmp2  = fi(SRs*XRx, 1, wlen, 15 + (wlen-35), fm); %27
%     SRxAb = fi(abs(SRx), 1, wlen, 17 + (wlen-35), fm);
%     XRxAb = fi(abs(XRx), 1, wlen, 17 + (wlen-35), fm); %33
%     tmp3  = fi(SRx*SRxAb, 1, wlen, 15 + (wlen-35), fm);
%     tmp4  = fi(SRs*XRxAb, 1, wlen, 15 + (wlen-35), fm);
%     tmp5  = fi(SRx*SRx2, 1, wlen, 15 + (wlen-35), fm);
%     tmp6  = fi(SRs*XRx2, 1, wlen, 15   + (wlen-35), fm); %overflow -27

    results_fpCEM(i)   = double(SRx)/double(SRs);
    results_fpACER(i)  = double(SRx2)/double(tmp2);
    results_fpASMF(i)  = double(tmp3)/double(tmp4);
    results_fpASMF2(i) = double(tmp5)/double(tmp6);
    
    %floating
    resultsCEM(i)   = algorithmCEM(x,An,target); %CEM
    resultsACER(i)  = algorithmACER(x,An,target); %ACER
    resultsASMF(i)  = algorithmASMF(x,An,target); %ASMF
    resultsASMF2(i) = algorithmASMF2(x,An,target); %ASMF2
    
    if(i < num_pixels - delay)
    
    x = M(:,i+delay);   
    u = M_fp(:,i+delay);
    
    %floating Sherman
    [An]=ShermanMorrisonRTF(An,x);
   
    %fixed Sherman
    if (sw==0)
        TRx = fi(A*u, 1, wlen, 24 + (wlen-35), fm); 
        TRxxR = fi(TRx * TRx', 1, wlen + 7, 13 + 7 + (wlen-35), fm);
        Td = fi(u' * TRx, 1, wlen, 17 + (wlen-35), fm);%23
        Tdiv = fi(1/(double(Td)+1), 1, wlen, 32 + (wlen-35), fm);
        TT = fi(TRxxR .* Tdiv, 1, wlen, 24 + (wlen-35), fm);
        Anew = fi(A - TT, 1, wlen, 24 + (wlen-35), fm);
    else
        TRx = fi(A*u, 1, wlen, 28 + (wlen-35), fm); 
        TRxxR = fi(TRx * TRx', 1, wlen + 7, 22 + 7 + (wlen-35), fm);
        Td = fi(u' * TRx, 1, wlen, 23 + (wlen-35), fm);%15, fm);
        Tdiv = fi(1/(double(Td)+1), 1, wlen, 32 + (wlen-35), fm);
        TT = fi(TRxxR .* Tdiv, 1, wlen, 24 + (wlen-35), fm);
        Anew = fi(A - TT, 1, wlen, 24  + (wlen-35), fm); 
    end
    
    A = Anew;
   
    
    oldmerr = merr;
    err = abs(An-double(A)) ./ abs(An);
    merr = vpa(100*mean(err(:)));
    smerr(i) = merr;
    fprintf("iteration %d, err = %f, diff = %f \n",i+delay,merr,merr-oldmerr);
     %rxfl=[rxfl,double(max(abs(double(TRx))))];
  % tdfl=[tdfl,double(Td)];
   %tdivfl=[tdivfl,double(Tdiv)];
    
    end   
end


% rcomb=[results,results_fp];

