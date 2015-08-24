
function PopulationParametersDialog(parameterManager)
%this function creates the popup dialog that displays the population
%parameters

%Create the dialog
d = dialog('Position',[200 350 380 380],'Name','Population Parameters');

%Generate the data for the table
if parameterManager.mutating && parameterManager.numLoci > 1
    data = cell(3, 2^parameterManager.numLoci + 1);
    data{1,1} = 'Type';
    data{2,1} = parameterManager.classConstants(parameterManager.currentModel).ParamName1;
    if ~isempty(parameterManager.classConstants(parameterManager.currentModel).ParamName2)
        data{3,1} = parameterManager.classConstants(parameterManager.currentModel).ParamName2;
    end
    for i = 1:2^parameterManager.numLoci
        data{1,i + 1} = dec2bin(i - 1, parameterManager.numLoci);
        if parameterManager.classConstants(parameterManager.currentModel).OverlappingGenerations %if OverlappingGenerations model
            data{2,i + 1} = num2str(parameterManager.lociParam1OverlappingGenerations(i));
        else
            data{2,i + 1} = num2str(parameterManager.lociParam1NonOverlappingGenerations(i));
        end
        if ~isempty(parameterManager.classConstants(parameterManager.currentModel).ParamName2) %if 2 parameters
            data{3,i + 1} = num2str(0.01);
        end
    end
else
    data = cell(3, parameterManager.numTypes + 1);
    data{1,1} = 'Type';
    data{2,1} = parameterManager.classConstants(parameterManager.currentModel).ParamName1;
    if ~isempty(parameterManager.classConstants(parameterManager.currentModel).ParamName2)
        data{3,1} = parameterManager.classConstants(parameterManager.currentModel).ParamName2;
    end
    for i = 1:parameterManager.numTypes
        data{1,i + 1} = num2str(i);
        data{2,i + 1} = num2str(parameterManager.modelParameters(parameterManager.currentModel).Param1(i));
        if ~isempty(parameterManager.classConstants(parameterManager.currentModel).ParamName2)
            data{3,i + 1} = num2str(parameterManager.modelParameters(parameterManager.currentModel).Param2(i));
        end
    end
end

widths = cell(1,size(data,1));
for x = 1:size(data,1)
    widths{x} = 100;
end
table = uitable(gcf,...
    'Parent',d,...
    'Data', data',...
    'Position',[0 0 380 380],...
    'FontSize', 15,...
    'ColumnWidth', widths);

    
    
    
%     txt = uicontrol('Parent',d,...
%                'Style','text',...
%                'Position',[50 150 780 400],...
%                'String',str,...
%                'HorizontalAlignment', 'Left');

%     btn = uicontrol('Parent',d,...
%                'Position',[85 20 70 25],...
%                'String','Close',...
%                'Callback','delete(gcf)');
end

