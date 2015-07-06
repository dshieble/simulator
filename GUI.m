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

% Last Modified by GUIDE v2.5 30-Jun-2015 16:20:06

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
global evolving old_matrix parameter_manager save_data rects paused grid_manager plot_grid parameters_clear;
evolving = 0;
parameter_manager = ParameterManager(handles);
old_matrix = zeros(parameter_manager.matrix.edge_size);
save_data = [];
rects = [];
paused = 0;
grid_manager = [];
parameters_clear = 1;
plot_grid = handles.plot_grid_button.Value;

% remove tickmarks from axes
fill([0,0,0,0], [0,0,0,0], 'w', 'Parent', handles.axes_grid);
set(handles.axes_grid,'XTick',[]);
set(handles.axes_grid,'YTick',[]);
handles.axes_grid.XLim = [1 parameter_manager.matrix.edge_size];
handles.axes_grid.YLim = [1 parameter_manager.matrix.edge_size];


%fill the boxes properly
parameter_manager.updateBoxes();
parameter_manager.updateStructs();



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
global evolving parameter_manager save_data rects grid_manager paused plot_grid parameters_clear;
if ~evolving && ~paused
    verify_parameters();
end
if ~evolving && ~paused && parameters_clear %run
    handles.run_button.String = 'Calculating...';
    if handles.logistic_button.Value
        grid_manager = GridManagerLogistic(...
            parameter_manager.matrix.edge_size, ...
            parameter_manager.getField('logistic', 'Ninit'), ...
            MutationManager(parameter_manager),...
            plot_grid,...
            parameter_manager.getField('logistic', 'birth_rate'), ...
            parameter_manager.getField('logistic','death_rate'));
    elseif handles.exp_button.Value
        grid_manager = GridManagerLogistic(...
            parameter_manager.matrix.edge_size, ...
            parameter_manager.getField('logistic', 'Ninit'), ...
            MutationManager(parameter_manager),...
            plot_grid,...
            parameter_manager.getField('logistic', 'birth_rate'), ...
            parameter_manager.getField('logistic','death_rate'));
    elseif handles.moran_button.Value
            if ~parameter_manager.verifySizeOk('moran')
                warndlg(sprintf('Initial Populations must sum to %d', parameter_manager.matrix.edge_size.^2));
                handles.run_button.String = 'Run';
                return;
            else    
                grid_manager = GridManagerMoran(...
                    parameter_manager.matrix.edge_size, ...
                    parameter_manager.getField('moran', 'Ninit'), ...
                    MutationManager(parameter_manager),...
                    plot_grid,...
                    parameter_manager.getField('moran','birth_rate'));
            end
    elseif handles.wright_button.Value
            if ~parameter_manager.verifySizeOk('wright') 
                warndlg(sprintf('Initial Populations must sum to %d', parameter_manager.matrix.edge_size.^2));
                handles.run_button.String = 'Run';
                return;
            else    
                grid_manager = GridManagerWright(...
                    parameter_manager.matrix.edge_size, ...
                    parameter_manager.getField('wright', 'Ninit'), ...
                    MutationManager(parameter_manager),...
                    plot_grid,...
                    parameter_manager.getField('wright','fitness'));
            end
    else
        warndlg('Radio button error');
        handles.run_button.String = 'Run';
        return;        
    end
    evolving = 1;
    handles.save_button.BackgroundColor = [0 0 0];
    handles.reset_button.BackgroundColor = [0 0 0];
    cla(handles.axes_grid);
    cla(handles.axes_graph);
    rects = cell(parameter_manager.matrix.edge_size);
    handles.run_button.String = 'Pause';
    handles.run_button.BackgroundColor = [1 0 0];
    drawnow;
    run_loop(1, handles);
    save_data = grid_manager.output;
    evolving = 0;
elseif ~evolving && paused %continue
    evolving = 1;
    paused = 0;
    handles.run_button.String = 'Pause';
    handles.run_button.BackgroundColor = [1 0 0];
    handles.save_button.BackgroundColor = [0 0 0];
    handles.reset_button.BackgroundColor = [0 0 0];
    drawnow;
    run_loop(0, handles);
    evolving = 0;
elseif evolving && ~paused %pause
	evolving = 0;
    paused = 1;
    handles.save_button.BackgroundColor = [0 1 1];
    handles.reset_button.BackgroundColor = [1 0 0];
    handles.run_button.String = 'Continue';
    handles.run_button.BackgroundColor = [0 1 0];
    drawnow;
end
if ~paused && ~evolving;
    handles.run_button.String = 'Run';
    handles.run_button.BackgroundColor = [0 1 0];
    handles.save_button.BackgroundColor = [0 1 1];
    handles.reset_button.BackgroundColor = [1 0 0];
    drawnow;
end

%Get the new matrix, mutat it 
function run_loop(first_run, handles)
global evolving grid_manager plot_grid parameter_manager;
warning('OFF','MATLAB:legend:PlotEmpty')
legend_input = {};
while evolving == 1

   [matrix, c, t, halt] = grid_manager.get_next();
   if plot_grid
       draw_iteration(matrix, c, t, halt, handles);
   end
   if first_run
        first_run = 0;
        legend_input = {};
        for i = 1:min(16, grid_manager.num_types)
            if parameter_manager.num_loci > 1 && parameter_manager.mutating
                legend_input = [legend_input sprintf('Type %s', dec2bin(i - 1))];
            else   
                legend_input = [legend_input sprintf('Type %d', i)];
            end
        end
        legend(legend_input, 'Location', 'northwest');
    end
    if halt && ~parameter_manager.mutating || (~plot_grid && (grid_manager.timestep > parameter_manager.max_iterations))
        break
    end
end
if ~first_run
    draw_iteration(matrix, c, t, halt, handles);
    legend(legend_input, 'Location', 'northwest')
end

    

function draw_iteration(matrix, c, t, halt, handles)
global parameter_manager rects grid_manager plot_grid;
%represents a single iteration of the grid and graph
if plot_grid 
    perm = c(randperm(length(c)))';
    for p = perm
        [i, j] = ind2sub(parameter_manager.matrix.edge_size, p);
        if (~isempty(rects(i,j)))
            delete(rects{i,j});
        end
        if (matrix(i,j) ~= 0)
            mult = (50/parameter_manager.matrix.edge_size);
            rects{i,j} = rectangle(...
                'Parent', handles.axes_grid,...
                'Position',[mult*i-mult mult*j-mult mult*1 mult*1],...
                'facecolor',grid_manager.get_color(matrix(i,j)));
        end
    end
end
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
    plot(grid_manager.generations, vec(i,:), 'Parent', handles.axes_graph, 'Color', grid_manager.get_color(i));
end
if parameter_manager.current_model == 4 || (plot_grid && (parameter_manager.current_model <= 2))
    xlabel('Generations', 'Parent', handles.axes_graph);
else
    xlabel('Reproductive Events', 'Parent', handles.axes_graph);
end
ylabel(y_axis_label, 'Parent', handles.axes_graph);
pause(0.01);
drawnow;


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



function num_types_box_Callback(~, eventdata, handles)
% hObject    handle to num_types_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_types_box as text
%        str2double(get(hObject,'String')) returns contents of num_types_box as a double
global parameter_manager;
parameter_manager.updateNumTypes();

function param_1_box_Callback(hObject, eventdata, handles)
% hObject    handle to param_1_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of param_1_box as text
%        str2double(get(hObject,'String')) returns contents of param_1_box as a double
global parameter_manager;
parameter_manager.updateStructs();


function init_pop_box_Callback(hObject, eventdata, handles)
% hObject    handle to init_pop_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of init_pop_box as text
%        str2double(get(hObject,'String')) returns contents of init_pop_box as a double
global parameter_manager;
parameter_manager.updateStructs();


function param_2_box_Callback(hObject, eventdata, handles)
% hObject    handle to param_2_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of param_2_box as text
%        str2double(get(hObject,'String')) returns contents of param_2_box as a double
global parameter_manager;
parameter_manager.updateStructs();



% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global evolving parameter_manager;
try
    if ~evolving
        c = clock; str = sprintf('Population Data: %d|%d|%d|%d|%d|%2.1f',c(1),c(2),c(3),c(4),c(5),c(6));
        save(str, 'save_data');
    end
catch 
    fprintf('ERROR: Save Error');
end



% --- Executes on button press in reset_button.
function reset_button_Callback(hObject, eventdata, handles)
% hObject    handle to reset_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global paused evolving rects parameter_manager;
if ~evolving
    paused = 0;
    evolving = 0;
    handles.run_button.String = 'Run';
    handles.run_button.BackgroundColor = [0 1 0];
    handles.save_button.String = 'Save';
    cla(handles.axes_grid);
    cla(handles.axes_graph);
    rects = cell(parameter_manager.matrix.edge_size);
    drawnow;
end


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
global parameter_manager;
parameter_manager.current_model = 1;
handles.log_exp_banner.String = 'Logistic Model';
parameter_manager.updateBoxes();
adjust_text(handles);


% --- Executes on button press in exp_button.
function exp_button_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.current_model = 2;
handles.log_exp_banner.String = 'Exponential Model';
parameter_manager.updateBoxes();
adjust_text(handles);

% --- Executes on button press in moran_button.
function moran_button_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.current_model = 3;
handles.log_exp_banner.String = 'Moran Model';
parameter_manager.updateBoxes();
adjust_text(handles);

% --- Executes on button press in wright_button.
function wright_button_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.current_model = 4;
handles.log_exp_banner.String = 'Wright-Fisher Model';
parameter_manager.updateBoxes();
adjust_text(handles);

function adjust_text(handles)
global parameter_manager;
if parameter_manager.current_model <= 2
    handles.param_1_text.String = 'Birth Rate';
    handles.param_2_text.String = 'Death Rate';
    handles.param_2_text.Visible = 'on';
    handles.param_2_box.Visible = 'on';
elseif parameter_manager.current_model == 3
    handles.param_1_text.String = 'Birth Rate';
    handles.param_2_text.Visible = 'off';
    handles.param_2_box.Visible = 'off';
else
    handles.param_1_text.String = 'Fitness';
    handles.param_2_text.Visible = 'off';
    handles.param_2_box.Visible = 'off';
end
    
 
function population_box_Callback(hObject, eventdata, handles)
% hObject    handle to population_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of population_box as text
%        str2double(get(hObject,'String')) returns contents of population_box as a double
verify_parameters();

function verify_parameters
global parameter_manager parameters_clear plot_grid;
parameters_clear = 0;
if ~parameter_manager.updateMatrixProperties()
    warndlg('Population size must be a perfect square and between 16 than 2500!');
elseif plot_grid && parameter_manager.num_loci > 4
    warndlg('Uncheck the "Show Petri Dish" box to simulate more than 4 Loci.');
else
    parameters_clear = 1;
end

    

% --- Executes on button press in plot_grid_button.
function plot_grid_button_Callback(hObject, eventdata, handles)
global plot_grid;
handles.max_iterations_panel.Visible
if handles.plot_grid_button.Value
    plot_grid = 1;
    handles.max_iterations_panel.Visible = 'off';
else 
    plot_grid = 0;
    handles.max_iterations_panel.Visible = 'on';
end

% --- Executes on button press in preview_button.
function preview_button_Callback(hObject, eventdata, handles)
% hObject    handle to preview_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global parameter_manager;
%Table Formatting in a dialog box is a pain in the butt
%TODO: set a standard number of spaces for each and enforce it
str = {};
str = [str '                               Logistic/Exponential                                                                 Moran                                               Wright Fisher'];
str = [str ' '];
str = [str 'Type |  Size                    Birth Rate                    Death Rate                      Size                 Birth Rate                    Size                          Fitness'];
str = [str '         | ----------------------------------------------------------------------------------                     --------------------------------------                     ----------------------------------------------' ];
for i = 1:parameter_manager.num_types
    str = [str, sprintf(' %02d    |    %04d                  %0.2f                             %0.2f                               %04d                  %0.2f                           %04d                          %0.2f',...
        i,...
        parameter_manager.logistic.Ninit(i),...
        parameter_manager.logistic.birth_rate(i),...
        parameter_manager.logistic.death_rate(i),...
        parameter_manager.moran.Ninit(i),...
        parameter_manager.moran.birth_rate(i),...
        parameter_manager.wright.Ninit(i),...
        parameter_manager.wright.fitness(i))];
end
PopulationParametersDialog(str);

% --- Executes on button press in mutation_matrix_button.
function mutation_matrix_button_Callback(hObject, eventdata, handles)
global parameter_manager;
m = MutationMatrixDialog(parameter_manager.mutation_matrix);
if ~isempty(m)
    parameter_manager.mutation_matrix = m;
end


% --- Executes on button press in demography_button.
function demography_button_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.mutating = 0;
toggle_mutation_visible(handles);
handles.mutation_panel.Visible = 'off';
handles.num_types_string.String = 'Number of Types:';
handles.params_string.String =  'Parameters for Type:';

% --- Executes on button press in genetics_button.
function genetics_button_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.mutating = 1;
toggle_mutation_visible(handles);
handles.mutation_panel.Visible = 'on';
handles.num_types_string.String = 'Number of Alleles:';
handles.params_string.String =  'Parameters for Allele:';

function loci_box_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.updateMultipleLoci();
toggle_mutation_visible(handles);


function toggle_mutation_visible(handles)
global parameter_manager;
if (parameter_manager.num_loci > 1) && parameter_manager.mutating
    handles.type_panel.Visible = 'off';
    handles.static_type_panel.Visible = 'on';
    handles.init_pop_box.Visible = 'off';
    handles.init_pop_text.Visible = 'off';
else
    handles.static_type_panel.Visible = 'off';
    handles.type_panel.Visible = 'on';
    handles.init_pop_box.Visible = 'on';
    handles.init_pop_text.Visible = 'on';
end

function max_iterations_box_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.updateMaxIterations();

% --- Executes on button press in spatial_structure_check.
function spatial_structure_check_Callback(hObject, eventdata, handles)
% hObject    handle to spatial_structure_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of spatial_structure_check


% --- Executes on button press in recombination_check.
function recombination_check_Callback(hObject, eventdata, handles)
if handles.recombination_check.Value == 1
    handles.recombination_panel.Visible = 'on';
else
    handles.recombination_panel.Visible = 'off';
end


function recombination_box_Callback(hObject, eventdata, handles)
%TODO: Fill this in

%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%

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
function param_2_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to param_2_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function init_pop_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to init_pop_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function param_1_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to param_1_box (see GCBO)
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


% --- Executes during object creation, after setting all properties.
function loci_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to loci_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function max_iterations_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max_iterations_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function edit28_CreateFcn(hObject, eventdata, handles)
% hObject    handle to loci_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function recombination_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to recombination_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
