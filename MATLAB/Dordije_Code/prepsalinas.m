sc=gt_data_set.salinas.cube;
[h,w,d] = size(sc);
M=hyperConvert2d(sc);

signatures=gt_data_set.salinas.signatures;
M(M(:)<0)=0; %remove all negative values
signatures(signatures(:)<0)=0;

%DO PCA
 q=16;

 M=M';
 [coeff,~,~,~,explained,~] = pca(M);
            
V = coeff(:,1:q);
M_pct = transpose(M*V);
signaturespca = signatures*V;
target= signaturespca(11,:);



M16=int16(M_pct); %cutting off a bit
target16=int16(target);

%i = dechextxt(M16(:),'cube.txt','uint16');

%i = dechextxt(target16(:),'target.txt','uint16');


R= hyperCorr(M_pct);
G=inv(R);

G32=int32(G*2^41);

%i = dechextxt(G32(:),'matrix.txt','uint32'); %uint32 just for writing, it will write negative

%prepare sR^-1 vector

sR = target*G;
sR32=int32(sR*2^36);

%i = dechextxt(sR32,'stat.txt','uint32');

% fileID = fopen('spca.bin','w');
% fwrite(fileID,M16,'int16');
% fclose(fileID)
% 
% 
% fileID = fopen('tpca.bin','w');
% fwrite(fileID,target16,'int16');
% fclose(fileID)

