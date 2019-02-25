
%% Open and load files
fid_st1 = fopen('res_step1.txt','r');
fid_st2 = fopen('res_step2.txt','r');
fid_st3 = fopen('res_step3.txt','r');

formatSpec = '%s \n';
A_st1 = [];
A_st2 = [];
A_st3 = [];

tline_st1 = fgetl(fid_st1);
while ischar(tline_st1)
    A_st1 = [A_st1 ;tline_st1];
    tline_st1 = fgetl(fid_st1);  
end

tline_st2 = fgetl(fid_st2);
while ischar(tline_st2)
    A_st2 = [A_st2 ;tline_st2];
    tline_st2 = fgetl(fid_st2);  
end

tline_st3 = fgetl(fid_st3);
while ischar(tline_st3)
    A_st3 = [A_st3 ;tline_st3];
    tline_st3 = fgetl(fid_st3);  
end

fclose(fid_st1);
fclose(fid_st2);
fclose(fid_st3);
%% Rearrange format
[m,n] = size(A_st1);
b = 8; %8 hex numbers for 32 bits element
B_st1 = [];

for i = 1:m   
    tline_st1 = A_st1(i,:);
    a = cellstr(reshape(tline_st1,b,[])');
    B_st1 = [B_st1,a];  
end

[m,n] = size(A_st2);
B_st2 = [];
for i = 1:m   
    tline_st2 = A_st2(i,:);
    a = cellstr(reshape(tline_st2,b,[])');
    B_st2 = [B_st2,a];  
end

[m,n] = size(A_st3);
B_st3 = [];
for i = 1:m   
    tline_st3 = A_st3(i,:);
    a = cellstr(reshape(tline_st3,b,[])');
    B_st3 = [B_st3,a];  
end

%% Convert to signed decimal
[m,n] = size(B_st1);
C_st1 = [];

for i = 1:n
    
  C_st1 = [C_st1, typecast(uint32(hex2dec(B_st1(:,i))), 'int32')];
    
end

[m,n] = size(B_st2);
C_st2 = [];

for i = 1:n
    
  C_st2 = [C_st2, typecast(uint32(hex2dec(B_st2(:,i))), 'int32')];
    
end

[m,n] = size(B_st3);
C_st3 = [];

for i = 1:n
    
  C_st3 = [C_st3, typecast(uint32(hex2dec(B_st3(:,i))), 'int32')];
    
end

%% Naming
Rx_sim = C_st1;
RxxR_sim = C_st2;
Rn = C_st3;

clear A_st1 A_st2 A_st3 B_st1 B_st2 B_st3 C_st1 C_st2 C_st3 tline_st1 tline_st2 tline_st3 fid_st1...
    fid_st2 fid_st3 m n a b i formatSpec;

