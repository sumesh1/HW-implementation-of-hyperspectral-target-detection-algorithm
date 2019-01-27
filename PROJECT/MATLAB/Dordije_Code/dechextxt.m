function [txt] = dechextxt (vect32,name,datatype)

garr=[];

if(datatype == "uint32") 
    bytes=8;

else
    bytes=4;
    
end 


    garr = typecast(vect32,datatype);

a = dec2hex(garr,bytes);
fid = fopen(name,'w');

for i=1:length(vect32)
fprintf(fid,'%s\n',a(i,:));
end
fclose(fid);

txt=0;
