function varargout = GUI(varargin)
% GUI MATLAB code for GUI.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI

% Last Modified by GUIDE v2.5 28-May-2015 16:49:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before GUI is made visible.
function GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI (see VARARGIN)

%tests that run at startup
run_tests;

% Choose default command line output for GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Attach global variables to handles object
global evolving old_matrix parameter_manager save_data;
evolving = 0;
parameter_manager = ParameterManager(handles);
old_matrix = zeros(parameter_manager.matrix.edge_size);
save_data = [];

% remove tickmarks from axes
fill([0,0,0,0], [0,0,0,0], 'w', 'Parent', handles.axes_grid);
set(handles.axes_grid,'XTick',[]);
set(handles.axes_grid,'YTick',[]);
handles.axes_grid.XLim = [1 parameter_manager.matrix.edge_size];
handles.axes_grid.YLim = [1 parameter_manager.matrix.edge_size];


%fill the boxes properly
parameter_manager.updateBoxes();

%show the correct display
% handles.moran_button.KeyPressFcn = @(src, event) switchDisplay(handles);
% handles.logistic_button.KeyPressFcn = @(src, event) switchDisplay(handles);
% handles.wright_button.KeyPressFcn = @(src, event) switchDisplay(handles);
% handles.display_group.KeyPressFcn = @(src, event) switchDisplay(handles);
switchDisplay(handles);


% 
% handles.init_pop_box_logistic.String = parameter_manager.logistic.Ninit(1);
% handles.birth_rate_box_logistic.String = parameter_manager.logistic.birth_rate(1);
% handles.death_rate_box_logistic.String = parameter_manager.logistic.death_rate(1);

%add handles to catch changes
% handles.num_types_box.KeyReleaseFcn = @;
% handles.init_pop_box_logistic.KeyReleaseFcn = @;
% handles.birth_rate_box_logistic.KeyReleaseFcn = @parameter_manager.updateLogistic;
% handles.death_rate_box_logistic.KeyReleaseFcn = @parameter_manager.updateLogistic;
% 
% 
% set(handles.axes_graph,'XTick',[]);
% set(handles.axes_graph,'YTick',[]);

% handles.axes_grid.ytick = [];

% UIWAIT makes GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in run_button.
function run_button_Callback(hObject, eventdata, handles)
% handles
% f = figure();
% ax = axes('Parent',f);  %corrected from my original version
%axis([0 size(matrix, 1) 0 size(matrix, 2)], 'Parent', ax);as
% axis off; axis equal;
global evolving parameter_manager save_data;
parameter_manager.updateMatrixProperties();
if evolving == 0
    handles.run_button.String = 'Calculating...';
    if handles.logistic_button.Value
        grid_manager = GridManagerLogistic(parameter_manager.matrix.edge_size, ...
            parameter_manager.logistic.Ninit, ...
            parameter_manager.logistic.birth_rate, ...
            parameter_manager.logistic.death_rate);
    else
        if sum(parameter_manager.moran.Ninit) ~= (parameter_manager.matrix.edge_size^2)
            warndlg(sprintf('Initial Populations must sum to %d', parameter_manager.matrix.edge_size.^2));
            handles.run_button.String = 'Run';
            return;
        elseif handles.moran_button.Value
            grid_manager = GridManagerMoran(parameter_manager.matrix.edge_size, ...
                parameter_manager.moran.Ninit, ...
                parameter_manager.moran.birth_rate);
        elseif handles.wright_button.Value
            grid_manager = GridManagerWright(parameter_manager.matrix.edge_size, ...
                parameter_manager.wright.Ninit, ...
                parameter_manager.wright.fitness);
        else
            warndlg('Radio button error');
            handles.run_button.String = 'Run';
            return;        
        end
    end
    evolving = 1;
    cla(handles.axes_grid);
    cla(handles.axes_graph);
    rects = cell(parameter_manager.matrix.edge_size);
    handles.run_button.String = 'Stop';
    handles.run_button.BackgroundColor = [1 0 0];
    first_run = 1;
    drawnow;
    while evolving == 1
        %update matrix
        [matrix, c, t, halt] = grid_manager.get_next();
        handles.timestep_text.String = sprintf('Timestep: %d', t);
        perm = c(randperm(length(c)))';
        for p = perm
            [i, j] = ind2sub(parameter_manager.matrix.edge_size, p);
            if (matrix(i,j) == 0)
                if (~isempty(rects(i,j)))
                    delete(rects{i,j});
                end
            else
                mult = (50/parameter_manager.matrix.edge_size);
                rects{i,j} = rectangle('Parent', handles.axes_grid, 'Position',[mult*i-mult mult*j-mult mult*1 mult*1],'facecolor',grid_manager.get_color(matrix(i,j)));
            end
        end
        drawnow;
        pause(.01);
        %plot the graph
        if handles.plot_button_count.Value
            vec = grid_manager.total_count;
            y_axis_label = 'Population Size';
        elseif handles.plot_button_percent.Value
            vec = grid_manager.percent_count;
            y_axis_label = 'Percent Population Size';
        else
            vec = grid_manager.overall_mean_fitness;
            y_axis_label = 'Mean Fitness';
        end
        if handles.plot_button_log.Value
            vec = log(vec);
        	y_axis_label = sprintf('log(%s)', y_axis_label);
        end
        for i = 1:size(vec,1)
            hold on;
            plot(1:size(vec,2), vec(i,:), 'Parent', handles.axes_graph, 'Color', grid_manager.get_color(i));
        end
        xlabel('Timestep', 'Parent', handles.axes_graph);
        ylabel(y_axis_label, 'Parent', handles.axes_graph);
        if first_run
            first_run = 0;
            legend_input = {};
            for i = 1:size(grid_manager.total_count,1)
                legend_input = [legend_input sprintf('Type %d', i)];
            end
            legend(legend_input, 'Location', 'northwest');
        end
        if halt
            break
        end
    end
    save_data = grid_manager.output;
end
evolving = 0;
handles.run_button.String = 'Run';
handles.run_button.BackgroundColor = [0 1 0];


% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on selection change in types_popup.
function types_popup_Callback(hObject, eventdata, handles)
% hObject    handle to types_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns types_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from types_popup
global parameter_manager;
parameter_manager.updateBoxes();



function num_types_box_Callback(hObject, eventdata, handles)
% hObject    handle to num_types_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_types_box as text
%        str2double(get(hObject,'String')) returns contents of num_types_box as a double
global parameter_manager;
parameter_manager.updateNumTypes();

function death_rate_box_logistic_Callback(hObject, eventdata, handles)
% hObject    handle to death_rate_box_logistic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of death_rate_box_logistic as text
%        str2double(get(hObject,'String')) returns contents of death_rate_box_logistic as a double
global parameter_manager;
parameter_manager.updateStructs();


function init_pop_box_logistic_Callback(hObject, eventdata, handles)
% hObject    handle to init_pop_box_logistic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of init_pop_box_logistic as text
%        str2double(get(hObject,'String')) returns contents of init_pop_box_logistic as a double
global parameter_manager;
parameter_manager.updateStructs();


function birth_rate_box_logistic_Callback(hObject, eventdata, handles)
% hObject    handle to birth_rate_box_logistic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of birth_rate_box_logistic as text
%        str2double(get(hObject,'String')) returns contents of birth_rate_box_logistic as a double
global parameter_manager;
parameter_manager.updateStructs();



% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global save_data;
save(sprintf('Saved Population Dynamics Data: %s',date)', 'save_data')




function birth_rate_box_moran_Callback(hObject, eventdata, handles)
% hObject    handle to birth_rate_box_moran (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of birth_rate_box_moran as text
%        str2double(get(hObject,'String')) returns contents of birth_rate_box_moran as a double
global parameter_manager;
parameter_manager.updateStructs();

function init_pop_box_moran_Callback(hObject, eventdata, handles)
% hObject    handle to init_pop_box_moran (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of init_pop_box_moran as text
%        str2double(get(hObject,'String')) returns contents of init_pop_box_moran as a double
global parameter_manager;
parameter_manager.updateStructs();


function fitness_box_wright_Callback(hObject, eventdata, handles)
% hObject    handle to fitness_box_wright (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fitness_box_wright as text
%        str2double(get(hObject,'String')) returns contents of fitness_box_wright as a double
global parameter_manager;
parameter_manager.updateStructs();


function init_pop_box_wright_Callback(hObject, eventdata, handles)
% hObject    handle to init_pop_box_wright (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of init_pop_box_wright as text
%        str2double(get(hObject,'String')) returns contents of init_pop_box_wright as a double
global parameter_manager;
parameter_manager.updateStructs();

% --- Executes on button press in logistic_button.
function logistic_button_Callback(hObject, eventdata, handles)
switchDisplay(handles)

% --- Executes on button press in moran_button.
function moran_button_Callback(hObject, eventdata, handles)
switchDisplay(handles)

% --- Executes on button press in wright_button.
function wright_button_Callback(hObject, eventdata, handles)
switchDisplay(handles)
    
function switchDisplay(handles)

handles.moran_panel.Visible = 'off';
handles.logistic_panel.Visible = 'off';
handles.wright_panel.Visible = 'off';
if handles.moran_button.Value
    handles.moran_panel.Visible = 'on';
elseif handles.logistic_button.Value
    handles.logistic_panel.Visible = 'on';
else
    handles.wright_panel.Visible = 'on';
end

 
function population_box_Callback(hObject, eventdata, handles)
% hObject    handle to population_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of population_box as text
%        str2double(get(hObject,'String')) returns contents of population_box as a double
global parameter_manager;
parameter_manager.updateMatrixProperties();



% --- Executes during object creation, after setting all properties.
function init_pop_box_wright_CreateFcn(hObject, eventdata, handles)
% hObject    handle to init_pop_box_wright (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function fitness_box_wright_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fitness_box_wright (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function init_pop_box_moran_CreateFcn(hObject, eventdata, handles)
% hObject    handle to init_pop_box_moran (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function birth_rate_box_moran_CreateFcn(hObject, eventdata, handles)
% hObject    handle to birth_rate_box_moran (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function birth_rate_box_logistic_CreateFcn(hObject, eventdata, handles)
% hObject    handle to birth_rate_box_logistic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function init_pop_box_logistic_CreateFcn(hObject, eventdata, handles)
% hObject    handle to init_pop_box_logistic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function death_rate_box_logistic_CreateFcn(hObject, eventdata, handles)
% hObject    handle to death_rate_box_logistic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function num_types_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_types_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function types_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to types_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function population_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to population_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
