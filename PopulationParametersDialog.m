
function PopulationParametersDialog(parameter_manager)
%this function creates the popup dialog that displays the population
%parameters

%Create the dialog
d = dialog('Position',[200 350 380 380],'Name','Population Parameters');

%Generate the data for the table
if parameter_manager.mutating && parameter_manager.num_loci > 1
    data = cell(3, 2^parameter_manager.num_loci + 1);
    data{1,1} = 'Type';
    data{2,1} = parameter_manager.classConstants(parameter_manager.current_model).Param_1_Name;
    if ~isempty(parameter_manager.classConstants(parameter_manager.current_model).Param_2_Name)
        data{3,1} = parameter_manager.classConstants(parameter_manager.current_model).Param_2_Name;
    end
    for i = 1:2^parameter_manager.num_loci
        data{1,i + 1} = dec2bin(i - 1, parameter_manager.num_loci);
        if parameter_manager.classConstants(parameter_manager.current_model).Generational %if generational model
            data{2,i + 1} = num2str(parameter_manager.lociParam1Generational(i));
        else
            data{2,i + 1} = num2str(parameter_manager.lociParam1NonGenerational(i));
        end
        if ~isempty(parameter_manager.classConstants(parameter_manager.current_model).Param_2_Name) %if 2 parameters
            data{3,i + 1} = num2str(0.01);
        end
    end
else
    data = cell(3, parameter_manager.num_types + 1);
    data{1,1} = 'Type';
    data{2,1} = parameter_manager.classConstants(parameter_manager.current_model).Param_1_Name;
    if ~isempty(parameter_manager.classConstants(parameter_manager.current_model).Param_2_Name)
        data{3,1} = parameter_manager.classConstants(parameter_manager.current_model).Param_2_Name;
    end
    for i = 1:parameter_manager.num_types
        data{1,i + 1} = num2str(i);
        data{2,i + 1} = num2str(parameter_manager.model_parameters(parameter_manager.current_model).Param1(i));
        if ~isempty(parameter_manager.classConstants(parameter_manager.current_model).Param_2_Name)
            data{3,i + 1} = num2str(parameter_manager.model_parameters(parameter_manager.current_model).Param2(i));
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

