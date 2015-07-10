%this function creates the popup dialog that displays the population
%parameters
function PopulationParametersDialog(parameter_manager)

%Create the dialog
d = dialog('Position',[200 350 1000 200],'Name','Population Parameters');

%Generate the data for the table
if parameter_manager.mutating && parameter_manager.num_loci > 1
    if parameter_manager.current_model <= 2
        data = cell(3, 2^parameter_manager.num_loci + 1);
        data{1,1} = 'Type';
        data{2,1} = 'Birth Rate';
        data{3,1} = 'Death Rate';
        for i = 1:2^parameter_manager.num_loci
            data{1,i + 1} = dec2bin(i - 1, parameter_manager.num_loci);
            data{2,i + 1} = num2str(parameter_manager.lociBR(i));
            data{3,i + 1} = num2str(0.01);
        end
    elseif parameter_manager.current_model == 3
        data = cell(2, 2^parameter_manager.num_loci + 1);
        data{1,1} = 'Type';
        data{2,1} = 'Birth Rate';
        for i = 1:2^parameter_manager.num_loci
            data{1,i + 1} = dec2bin(i - 1, parameter_manager.num_loci);
            data{2,i + 1} = num2str(parameter_manager.lociBR(i));
        end
    elseif parameter_manager.current_model == 4
        data = cell(2, 2^parameter_manager.num_loci + 1);
        data{1,1} = 'Type';
        data{2,1} = 'Fitness';
        for i = 1:2^parameter_manager.num_loci
            data{1,i + 1} = dec2bin(i - 1, parameter_manager.num_loci);
            data{2,i + 1} = num2str(parameter_manager.lociFitness(i));
        end
    end
else
    if parameter_manager.current_model == 1
        data = cell(3, parameter_manager.num_types + 1);
        data{1,1} = 'Type';
        data{2,1} = 'Birth Rate';
        data{3,1} = 'Death Rate';
        for i = 1:parameter_manager.num_types
            data{1,i + 1} = num2str(i);
            data{2,i + 1} = num2str(parameter_manager.logistic.birth_rate(i));
            data{3,i + 1} = num2str(parameter_manager.logistic.death_rate(i));
        end
    elseif parameter_manager.current_model == 2
        data = cell(3, parameter_manager.num_types + 1);
        data{1,1} = 'Type';
        data{2,1} = 'Birth Rate';
        data{3,1} = 'Death Rate';
        for i = 1:parameter_manager.num_types
            data{1,i + 1} = num2str(i);
            data{2,i + 1} = num2str(parameter_manager.exp.birth_rate(i));
            data{3,i + 1} = num2str(parameter_manager.exp.death_rate(i));
        end
    elseif parameter_manager.current_model == 3
        data = cell(2, parameter_manager.num_types + 1);
        data{1,1} = 'Type';
        data{2,1} = 'Birth Rate';
        for i = 1:parameter_manager.num_types
            data{1,i + 1} = num2str(i);
            data{2,i + 1} = num2str(parameter_manager.moran.birth_rate(i));
        end
    elseif parameter_manager.current_model == 4
        data = cell(2, parameter_manager.num_types + 1);
        data{1,1} = 'Type';
        data{2,1} = 'Fitness';
        for i = 1:parameter_manager.num_types
            data{1,i + 1} = num2str(i);
            data{2,i + 1} = num2str(parameter_manager.wright.birth_rate(i));
        end
    end
end

widths = cell(1,size(data,1));
for x = 1:size(data,1)
    widths{x} = 100;
end
table = uitable(gcf,...
    'Parent',d,...
    'Data', data,...
    'Position',[0 0 1000 200],...
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

