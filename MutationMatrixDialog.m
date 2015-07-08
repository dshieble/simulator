function matrix = MutationMatrixDialog(current, num_loci)
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
        'ColumnWidth', widths,...
        'CellEditCallback', @diagonalManager);
    if num_loci > 1
        table.RowName =  {'0','1'};
        table.ColumnName =  {'0','1'};
    end
    set(table,'data',num2cell(get(table,'data')))
    
    
       
    uiwait;
    function cancel(~,~)
        uiresume;
        delete(gcf);
    end

    function save(~,~)
       data = cell2mat(get(table,'data'));
       if sum(isnan(data)) > 0
           warndlg('ERROR: All entries must be numerical!')
           return;
       end
        for i = 1:size(data,1)
            if abs(sum(data(:,i))-1) > 1e-3
                warndlg('ERROR: All columns must sum to 1!')
                return;
            end
        end
        matrix = table.Data;
        uiresume;
        delete(gcf);
    end

    function diagonalManager(~,~)
       D = cell2mat(get(table,'data'));
       if sum(isnan(D)) > 0
           return;
       end
        for i = 1:size(D,1)
            s = sum(sum(D(:,i))) - D(i,i);
            if s < 1
                D(i,i) = 1 - s;
            else
                D(i,i) = 0;
            end
        end
        set(table,'data',num2cell(D));
    end
    

end

