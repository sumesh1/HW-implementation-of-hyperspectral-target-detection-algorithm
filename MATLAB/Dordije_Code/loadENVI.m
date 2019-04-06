clc;

%% initial 
name = 'self_test_refl';
%name = 'F3_f';
img_or_spl = 1;

%% loading
namehdr=[name,'.hdr'];

if(img_or_spl == 1)
    nameimg=[name,'.img'];
else
    nameimg=[name,'.spl'];
end    
info=read_envihdr(namehdr);

X=multibandread(nameimg,info.size,info.format,info.header_offset,...
    info.interleave,info.machine);


%% clearing
%clearvars -except X 