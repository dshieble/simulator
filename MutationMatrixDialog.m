function matrix = MutationMatrixDialog(current)
%this function creates the popup dialog that allows us to edit the mutation
%matrix
    d = dialog('Position',[100 100 1100 600],'Name','Population Parameters');
    matrix = [];
    txt = uicontrol('Parent',d,...
               'Style','text',...
               'Position',[350 180 400 400],...
               'FontSize', 20,...
               'String','Fill in the Mutation Matrix Below',...
               'HorizontalAlignment', 'Center');

    btn = uicontrol('Parent',d,...
               'Position',[550 20 100 25],...
               'String','Cancel',...
               'Callback',@cancel);
           
    btn = uicontrol('Parent',d,...
           'Position',[400 20 100 25],...
           'String','Save',...
           'Callback',@save);       
    
    widths = cell(1,size(current,1));
    for x = 1:size(current,1)
        widths{x} = 60;
    end
       
    table = uitable(gcf,...
        'Parent',d,...
        'Data', current,...
        'Position',[50 100 1000 350],...
        'ColumnEditable', logical(ones(1,size(current,1))),...
        'ColumnWidth', widths);
       
       
    uiwait;
    function cancel(~,~)
        uiresume;
        delete(gcf);
    end

    function save(~,~)
        for i = 1:size(table.Data,1)
            if abs(sum(table.Data(:,i))-1) > 1e-3
                warndlg('ERROR: All columns must sum to 1!')
                return;
            end
        end
        matrix = table.Data;
        uiresume;
        delete(gcf);
    end

end

