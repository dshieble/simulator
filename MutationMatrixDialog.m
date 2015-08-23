%this function creates the popup dialog that allows us to edit the mutation
%matrix
function matrix = MutationMatrixDialog(current, num_loci)

    %Start Script
    d = dialog('Position',[100 100 1100 600],'Name','Mutation Matrix');
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
        %'CellSelectionCallback', @changeEditable);
    if num_loci > 1
        table.RowName =  {'0','1'};
        table.ColumnName =  {'0','1'};
    end
    table.Data = num2cell(table.Data);
    uiwait; %prevents the function from returning until uiresume is called
   
    
    %Functions
    
    %closes the window. uiresume 
    function cancel(~,~)
        uiresume;
        delete(gcf);
    end

    %Saves the data in the matrix to the matrix variable, which is returned
    %to the GUI script upon the execution of uiresume
    function save(~,~)
       data = cell2mat(table.Data);
       if ~all(all(isnumeric(data))) || any(any(data < 0)) || any(any(isnan(data)))
           warndlg('ERROR: All entries must be non-negative numbers!')
           return;
       end
        for i = 1:size(data,1)
            if abs(sum(data(:,i))-1) > 1e-3
                warndlg('ERROR: All columns must sum to 1!')
                return;
            end
        end
        matrix = cell2mat(table.Data);
        uiresume;
        delete(gcf);
    end

    %Gets called whenever the user changes the value of a cell, and change
    %the value of the diagonal in that column to balence out the change
    function diagonalManager(~,~)
       D = cell2mat(table.Data);
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
        table.Data = num2cell(D);
    end

    

end

