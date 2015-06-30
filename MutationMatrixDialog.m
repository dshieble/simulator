function matrix = MutationMatrixDialog(current)
%this function creates the popup dialog that allows us to edit the mutation
%matrix
    d = dialog('Position',[300 300 800 600],'Name','Population Parameters');
    matrix = [];
    txt = uicontrol('Parent',d,...
               'Style','text',...
               'Position',[50 150 780 400],...
               'FontSize', 20,...
               'String','Fill in the Mutation Matrix Below',...
               'HorizontalAlignment', 'Left');

    btn = uicontrol('Parent',d,...
               'Position',[255 20 70 25],...
               'String','Cancel',...
               'Callback',@cancel);
           
    btn = uicontrol('Parent',d,...
           'Position',[55 20 70 25],...
           'String','Save',...
           'Callback',@save);       
    
    table = uitable(gcf, 'Data', current,...
        'Position',[50 100 400 400],...
        'ColumnEditable', logical(ones(1,size(current,1))));
       
       
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
