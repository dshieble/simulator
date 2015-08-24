%function New_Model(name)
name = 'MyModel';
className = ['GridManager' name];
folderName = ['@' className];
copyfile('@GridManagerCustom', folderName);
cd(folderName);
%copyfile('GridManagerCustom.m', [className '.m']);

fin = fopen('GridManagerCustom.m');
fout = fopen([className '.m'], 'w');

while ~feof(fin)
   sOld = fgetl(fin);
   sNew = strrep(sOld, 'Custom', name);
   fprintf(fout,'%s\n',sNew);
end

fclose(fin);
fclose(fout);
delete('GridManagerCustom.m')

cd('..');