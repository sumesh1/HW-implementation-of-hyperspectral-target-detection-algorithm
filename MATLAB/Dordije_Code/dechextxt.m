k=magic(16);
garr=[];
for i=1: 200
    garr=[garr,typecast(M(:,i),'uint16')];
end
a=dec2hex(garr,4);
fid = fopen('cube.txt','w');

for i=1:length(a)
fprintf(fid,'%s\n',a(i,:));
end
fclose(fid);