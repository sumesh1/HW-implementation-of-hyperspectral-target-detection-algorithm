garr=[];
for i=1: length(vect32)
    garr=[garr,typecast(vect32(:,i),'uint32')];
end
a=dec2hex(garr,8);
fid = fopen('vect.txt','w');

for i=1:length(vect32)
fprintf(fid,'%s\n',a(i,:));
end
fclose(fid);