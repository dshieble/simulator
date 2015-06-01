function PopulationParametersDialog(str)
%this function creates the popup dialog that displays the population
%parameters
    d = dialog('Position',[300 300 800 600],'Name','Population Parameters');

    txt = uicontrol('Parent',d,...
               'Style','text',...
               'Position',[50 150 700 400],...
               'String',str,...
               'HorizontalAlignment', 'Left');

%     btn = uicontrol('Parent',d,...
%                'Position',[85 20 70 25],...
%                'String','Close',...
%                'Callback','delete(gcf)');
end

