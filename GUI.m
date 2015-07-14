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

% Last Modified by GUIDE v2.5 10-Jul-2015 21:33:28

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

% Choose default command line output for GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Attach global variables to handles object
global group evolving old_matrix parameter_manager rects paused grid_manager plot_grid parameters_clear stepping spatial_on;
group = 1;
evolving = 0;
parameter_manager = ParameterManager(handles);
old_matrix = zeros(parameter_manager.matrix.edge_size);
rects = [];
paused = 0;
grid_manager = [];
parameters_clear = 1;
stepping = 0;
plot_grid = handles.plot_grid_button.Value;
spatial_on = 0;

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
varargout{1} = handles.output;

% --- Executes on button press in run_button.
function run_button_Callback(hObject, eventdata, handles)
global evolving paused parameters_clear stepping;
if stepping
    return;
end
if ~evolving && ~paused
    verify_parameters(handles);
end
if ~evolving && ~paused && parameters_clear %run
    run(handles, 0);
elseif ~evolving && paused %continue
    continueRunning(handles);
elseif evolving && ~paused %pause
    pauseRunning(handles);
end
if ~paused && ~evolving;
    handles.run_button.String = 'Run';
    handles.run_button.BackgroundColor = [0 1 0];
    handles.save_button.BackgroundColor = [0 1 1];
    handles.reset_button.BackgroundColor = [1 0 0];
    handles.step_button.BackgroundColor = [0 0 1];

    drawnow;
end

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
global parameter_manager;
parameter_manager.updateBoxes();



function num_types_box_Callback(~, eventdata, handles)
% hObject    handle to num_types_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global parameter_manager;
parameter_manager.updateNumTypes();

function param_1_box_Callback(hObject, eventdata, handles)
% hObject    handle to param_1_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global parameter_manager;
parameter_manager.updateStructs();
verify_parameters(handles);

function init_pop_box_Callback(hObject, eventdata, handles)
% hObject    handle to init_pop_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global parameter_manager;
parameter_manager.updateStructs();


function param_2_box_Callback(hObject, eventdata, handles)
% hObject    handle to param_2_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global parameter_manager;
parameter_manager.updateStructs();



% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global evolving grid_manager stepping;
try
    if ~evolving && ~stepping
        c = clock; str = sprintf('Population Data: %d|%d|%d|%d|%d|%2.1f.mat',c(1),c(2),c(3),c(4),c(5),c(6));
        save_data = grid_manager.save_data;
        save(str, 'save_data');
    end
catch 
    fprintf('ERROR: Save Error');
end



% --- Executes on button press in reset_button.
function reset_button_Callback(hObject, eventdata, handles)
global paused evolving rects parameter_manager stepping;
if ~evolving && ~stepping
    paused = 0;
    evolving = 0;
    enable_inputs(handles, 1);
    enable_buttons(handles, 1);
    handles.run_button.String = 'Run';
    handles.run_button.BackgroundColor = [0 1 0];
    cla(handles.axes_grid);
    cla(handles.axes_graph);
    rects = cell(parameter_manager.matrix.edge_size);
    drawnow;
end


function birth_rate_box_moran_Callback(hObject, eventdata, handles)
% hObject    handle to birth_rate_box_moran (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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

    
 
function population_box_Callback(hObject, eventdata, handles)
% hObject    handle to population_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of population_box as text
%        str2double(get(hObject,'String')) returns contents of population_box as a double
verify_parameters(handles);


    

% --- Executes on button press in plot_grid_button.
function plot_grid_button_Callback(hObject, eventdata, handles)
global plot_grid;
plot_grid = handles.plot_grid_button.Value;
% handles.max_iterations_panel.Visible
% if handles.plot_grid_button.Value
%     plot_grid = 1;
%     handles.max_iterations_panel.Visible = 'off';
% else 
%     plot_grid = 0;
%     handles.max_iterations_panel.Visible = 'on';
% end

% --- Executes on button press in preview_button.
function preview_button_Callback(hObject, eventdata, handles)
% hObject    handle to preview_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global parameter_manager evolving stepping;
%Table Formatting in a dialog box is a pain in the butt
%TODO: set a standard number of spaces for each and enforce it
if evolving || stepping
    return
else
    handles.preview_button.String = 'Pulling up the Population Parameters...';
    drawnow;
    PopulationParametersDialog(parameter_manager);
    handles.preview_button.String = 'See All Population Parameters';
end


% --- Executes on button press in mutation_matrix_button.
function mutation_matrix_button_Callback(hObject, eventdata, handles)
global parameter_manager evolving stepping;
if ~evolving && ~stepping
    m = MutationMatrixDialog(parameter_manager.mutation_matrix, parameter_manager.num_loci);
    if ~isempty(m) 
        parameter_manager.mutation_matrix = m;
    end
end


% --- Executes on button press in demography_button.
function demography_button_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.mutating = 0;
toggle_mutation_visible(handles);
handles.mutation_panel.Visible = 'off';
handles.num_types_string.String = 'Number of Types:';
handles.params_string.String =  'Parameters For Type:';

% --- Executes on button press in genetics_button.
function genetics_button_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.mutating = 1;
toggle_mutation_visible(handles);
handles.mutation_panel.Visible = 'on';
handles.num_types_string.String = 'Number of Alleles:';
handles.params_string.String =  'Parameters For Allele:';

function loci_box_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.updateMultipleLoci();
toggle_mutation_visible(handles);
verify_parameters(handles);
parameter_manager.updateBoxes();

% function max_iterations_box_Callback(hObject, eventdata, handles)
% global parameter_manager;
% parameter_manager.updateMaxIterations();



% --- Executes on button press in step_button.
function step_button_Callback(hObject, eventdata, handles)
global grid_manager stepping evolving paused plot_grid;
if ~stepping && ~evolving
    if ~paused
        run(handles,1)
        pauseRunning(handles);
    else
        if isempty(grid_manager)
            fprintf('ERROR: Grid Manager Empty')
            return
        end
        stepping = 1;
        enable_buttons(handles, 0)
        handles.run_button.Enable = 'off';
        handles.run_button.BackgroundColor = [.25 .25 .25];
        handles.save_button.BackgroundColor = [.25 .25 .25];
        handles.reset_button.BackgroundColor = [.25 .25 .25];
        handles.step_button.BackgroundColor = [.25 .25 .25];
        drawnow;
        [matrix, c, t, halt] = grid_manager.get_next();
        draw_iteration(matrix, c, handles, 0);
        stepping = 0;
        handles.run_button.Enable = 'on';
        handles.run_button.BackgroundColor = [0 1 0];
        handles.save_button.BackgroundColor = [0 1 1];
        handles.reset_button.BackgroundColor = [1 0 0];
        handles.step_button.BackgroundColor = [0 0 1]; 
        enable_buttons(handles, 1)

    end
end
    


% --- Executes on button press in spatial_structure_check.
function spatial_structure_check_Callback(hObject, eventdata, handles)
global spatial_on;
spatial_on = handles.spatial_structure_check.Value;



% --- Executes on button press in recombination_check.
function recombination_check_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.recombination = handles.recombination_check.Value;
if handles.recombination_check.Value == 1
    handles.recombination_panel.Visible = 'on';
else
    handles.recombination_panel.Visible = 'off';
end


function recombination_box_Callback(hObject, eventdata, handles)
%TODO: Fill this in




% --- Executes on button press in page_button.
function page_button_Callback(hObject, eventdata, handles)
%Flip to the next page of the graph
global evolving stepping group grid_manager;
if isempty(grid_manager)
    return
end
if ~evolving && ~stepping && grid_manager.num_types > 16
    group = group + 16;
    if group > grid_manager.num_types
        group = 1;
    end
    draw_page(handles, 1);
end






















function verify_parameters(handles)
global parameter_manager parameters_clear plot_grid;
parameters_clear = 0;
if parameter_manager.mutating && (parameter_manager.num_loci > parameter_manager.max_num_loci)
    parameter_manager.num_loci = parameter_manager.max_num_loci;
	warndlg(sprintf('ERROR: The number of loci must be no greater than %d.', parameter_manager.max_num_loci));
elseif ~parameter_manager.updateMatrixProperties()
    warndlg('ERROR: Population size must be a perfect square and between 16 than 2500!');
elseif ~parameter_manager.verifyAllBoxesClean();
    warndlg('ERROR: All input must be numerical.');
elseif parameter_manager.mutating && parameter_manager.num_loci > 1 && parameter_manager.s < -1;
    warndlg('ERROR: S must be no less than -1!');
elseif parameter_manager.current_model > 2 && ~parameter_manager.verifySizeOk('moran')
	warndlg(sprintf('ERROR: Initial Populations must sum to %d', parameter_manager.matrix.edge_size.^2));
elseif plot_grid && parameter_manager.num_loci > 4
    warndlg('ERROR: Uncheck the "Show Petri Dish" box to simulate more than 4 Loci.');
else    
    parameters_clear = 1;
end

%VisibilityFunctions
function adjust_text(handles)
global parameter_manager;
cla(handles.formula_axes);
if parameter_manager.mutating && parameter_manager.num_loci > 1
    handles.param_1_text.String = 'S:';
    handles.param_2_text.String = 'E';
    handles.param_2_text.Visible = 'on';
    handles.param_2_box.Visible = 'on';
    if parameter_manager.current_model <=2
        str1 = 'Birth Rate: $$1+sk^{1-\epsilon}$$';
        str2 = 'Death Rate: 0.01';
        text(0,0.5,str1,'FontSize',15, 'Interpreter','latex', 'Parent', handles.formula_axes);
        text(0,0.2,str2,'FontSize',15, 'Interpreter','latex', 'Parent', handles.formula_axes);

    elseif parameter_manager.current_model == 3
        str = 'Birth Rate: $$1+sk^{1-\epsilon}$$';
        text(0,0.5,str,'FontSize',15, 'Interpreter','latex', 'Parent', handles.formula_axes);
    elseif parameter_manager.current_model == 4
    	str = 'Fitness: $$  e^{sk^{1-\epsilon}} $$';
        text(0,0.5,str,'FontSize',18, 'Interpreter','latex', 'Parent', handles.formula_axes);
    end
    
elseif parameter_manager.current_model <= 2
    handles.param_1_text.String = 'Birth Rate:';
    handles.param_2_text.String = 'Death Rate:';
    handles.param_2_text.Visible = 'on';
    handles.param_2_box.Visible = 'on';
elseif parameter_manager.current_model == 3
    handles.param_1_text.String = 'Birth Rate:';
    handles.param_2_text.Visible = 'off';
    handles.param_2_box.Visible = 'off';
else
    handles.param_1_text.String = 'Fitness:';
    handles.param_2_text.Visible = 'off';
    handles.param_2_box.Visible = 'off';
end
%annotation('arrow','X',[0.32,0.5],'Y',[0.6,0.4])


function toggle_mutation_visible(handles)
global parameter_manager;
if (parameter_manager.num_loci > 1) && parameter_manager.mutating
    %popup
    handles.types_popup.Visible = 'off';
    handles.params_string.Visible=  'off';
    %num_types
    handles.num_types_box.Style = 'text';
    handles.init_pop_box.Style = 'text';
    parameter_manager.updateBoxes();
else
    %popup
    handles.types_popup.Visible = 'on';
    handles.params_string.Visible= 'on';
    %num_types
    handles.num_types_box.Style = 'edit';
    handles.init_pop_box.Style = 'edit';
    parameter_manager.updateBoxes();
end
adjust_text(handles);


%Get the new matrix, mutate it
function run_loop(first_run, handles, runOnce)
global evolving grid_manager plot_grid parameter_manager stepping group;
if isempty(grid_manager)
    fprintf('ERROR: Grid Manager Empty')
    return
end
warning('OFF','MATLAB:legend:PlotEmpty');
group = 1;
while evolving == 1
   [matrix, c, t, halt] = grid_manager.get_next();
   draw_iteration(matrix, c,handles, first_run);
   first_run = 0;
    if runOnce || halt% || (~plot_grid && (grid_manager.timestep > parameter_manager.max_iterations))
        break
    end
end
    
%IterationFunctions
function draw_iteration(matrix, c, handles, first_run)
global parameter_manager rects grid_manager plot_grid;
%represents a single iteration of the grid and graph
if isempty(grid_manager)
    fprintf('ERROR: Grid Manager Empty')
    return
end
if grid_manager.plot_grid 
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
    drawnow;
end
draw_page(handles, first_run);
pause(0.01);
drawnow;


%Fills in the legend_input, draws the legend and parameter plots to the screen. Draws all
%types in the interval [group, (group + 16)]
function draw_page(handles, first_run)
global grid_manager parameter_manager group;
if isempty(grid_manager)
    fprintf('ERROR: Grid Manager Empty')
    return
end
if first_run
    cla(handles.axes_graph);
end
if group > grid_manager.num_types
    group = 1;
end
range = group:min(group + 15, grid_manager.num_types);
%plot the graph
switch grid_manager.plottingParams.plot_type
    case 'total_count'
    	vec = grid_manager.total_count(range, :);
        y_axis_label = 'Population Size';
    case 'percent_count'
        vec = grid_manager.percent_count(range, :);
        y_axis_label = 'Percent Population Size';
    case 'overall_mean_fitness'
        vec = grid_manager.overall_mean_fitness(range, :);
        y_axis_label = 'Mean Fitness';
end
if grid_manager.plottingParams.plot_log
    vec = log(vec);
    y_axis_label = sprintf('log(%s)', y_axis_label);
end
for i = 1:size(vec,1)
    hold on;
    plot(grid_manager.generations, vec(i,:), 'Parent', handles.axes_graph, 'Color', grid_manager.get_color(i));
end
xlabel('Generations', 'Parent', handles.axes_graph);
ylabel(y_axis_label, 'Parent', handles.axes_graph);
if first_run
    legend_input = {};
    for i = range
        if parameter_manager.num_loci > 1 && parameter_manager.mutating
            legend_input = [legend_input sprintf('Type %s', dec2bin(i - 1, log2(grid_manager.num_types)))];
        else
            legend_input = [legend_input sprintf('Type %d', i)];
        end
    end
    legend(legend_input, 'Location', 'northwest')
end


%RunFunctions
function run(handles, runOnce)
%Execute the simulation
global grid_manager evolving group;
group = 1;
handles.run_button.String = 'Calculating...';
evolving = 1;
enable_inputs(handles, 0)
enable_buttons(handles, 0)
handles.run_button.String = 'Pause';
handles.run_button.BackgroundColor = [1 0 0];
handles.save_button.BackgroundColor = [.25 .25 .25];
handles.reset_button.BackgroundColor = [.25 .25 .25];
handles.step_button.BackgroundColor = [.25 .25 .25];
drawnow;
initializeGridManager(handles);
run_loop(1, handles, runOnce);
evolving = 0;
enable_inputs(handles, 1)
enable_buttons(handles, 1)

function continueRunning(handles)
%Break the pause and continue running the simulation
global evolving paused;
evolving = 1;
paused = 0;
enable_inputs(handles, 0);
enable_buttons(handles, 0)
handles.run_button.String = 'Pause';
handles.run_button.BackgroundColor = [1 0 0];
handles.save_button.BackgroundColor = [.25 .25 .25];
handles.reset_button.BackgroundColor = [.25 .25 .25];
handles.step_button.BackgroundColor = [.25 .25 .25];
drawnow;
run_loop(0, handles, 0);
evolving = 0;

function pauseRunning(handles)
%Pause the simulation
global evolving paused;
evolving = 0;
paused = 1;
enable_buttons(handles, 1);
enable_inputs(handles, 0);
handles.run_button.String = 'Continue';
handles.run_button.BackgroundColor = [0 1 0];
handles.step_button.BackgroundColor = [0 0 1];
handles.save_button.BackgroundColor = [0 1 1];
handles.reset_button.BackgroundColor = [1 0 0];
drawnow;

function initializeGridManager(handles)
global grid_manager parameter_manager plot_grid rects spatial_on;
%Initialize the grid manager object based on the parameter_manager and the
%current model
plottingParams = struct();
if handles.plot_button_count.Value
    plottingParams.plot_type = 'total_count';
elseif handles.plot_button_percent.Value
    plottingParams.plot_type = 'percent_count';
else
	plottingParams.plot_type = 'overall_mean_fitness';
end
if handles.plot_button_log.Value
    plottingParams.plot_log = 1;
else
    plottingParams.plot_log = 0;
end
if parameter_manager.current_model == 1
    grid_manager = GridManagerLogistic(...
        parameter_manager.matrix.edge_size, ...
        parameter_manager.getField('logistic', 'Ninit'), ...
        MutationManager(parameter_manager),...
        plot_grid,...
        plottingParams, ...
        spatial_on,...
        parameter_manager.getField('logistic', 'birth_rate'), ...
        parameter_manager.getField('logistic','death_rate'));
elseif parameter_manager.current_model == 2
    grid_manager = GridManagerExp(...
        parameter_manager.matrix.edge_size, ...
        parameter_manager.getField('exp', 'Ninit'), ...
        MutationManager(parameter_manager),...
        plot_grid,...
        plottingParams, ...
        spatial_on,...
        parameter_manager.getField('exp', 'birth_rate'), ...
        parameter_manager.getField('exp','death_rate'));
elseif parameter_manager.current_model == 3
        grid_manager = GridManagerMoran(...
        parameter_manager.matrix.edge_size, ...
        parameter_manager.getField('moran', 'Ninit'), ...
        MutationManager(parameter_manager),...
        plot_grid,...
        plottingParams, ...
        spatial_on,...
        parameter_manager.getField('moran','birth_rate'));
elseif parameter_manager.current_model == 4  
        grid_manager = GridManagerWright(...
            parameter_manager.matrix.edge_size, ...
            parameter_manager.getField('wright', 'Ninit'), ...
            MutationManager(parameter_manager),...
            plot_grid,...
            plottingParams, ...
            spatial_on,...
            parameter_manager.getField('wright','fitness'));
else
    warndlg('Radio button error');
    handles.run_button.String = 'Run';
    return;        
end
cla(handles.axes_grid);
cla(handles.axes_graph);
rects = cell(parameter_manager.matrix.edge_size);

function enable_buttons(handles, on)
if on
    handles.save_button.Enable = 'on';
    handles.step_button.Enable = 'on';
    handles.reset_button.Enable = 'on';
else
    handles.save_button.Enable = 'off';
    handles.step_button.Enable = 'off';
    handles.reset_button.Enable = 'off';
end


function enable_inputs(handles, on)
if on
    handles.plot_grid_button.Enable = 'on';
    handles.population_box.Enable = 'on';
    handles.genetics_button.Enable = 'on';
    handles.demography_button.Enable = 'on';
    handles.spatial_structure_check.Enable = 'on';
    handles.recombination_check.Enable = 'on';
    handles.logistic_button.Enable = 'on';
    handles.exp_button.Enable = 'on';
    handles.moran_button.Enable = 'on';
    handles.wright_button.Enable = 'on';
    handles.num_types_box.Enable = 'on';
    handles.types_popup.Enable = 'on';
    handles.init_pop_box.Enable = 'on';
    handles.param_1_box.Enable = 'on';
    handles.param_2_box.Enable = 'on';
    handles.plot_button_count.Enable = 'on';
    handles.plot_button_percent.Enable = 'on';
    handles.plot_button_fitness.Enable = 'on';
    handles.plot_button_linear.Enable = 'on';
    handles.plot_button_log.Enable = 'on';
%     handles.save_button.Enable = 'on';
%     handles.step_button.Enable = 'on';
%     handles.reset_button.Enable = 'on';
else
    handles.plot_grid_button.Enable = 'off';
    handles.population_box.Enable = 'off';
    handles.genetics_button.Enable = 'off';
    handles.demography_button.Enable = 'off';
    handles.spatial_structure_check.Enable = 'off';
    handles.recombination_check.Enable = 'off';
    handles.logistic_button.Enable = 'off';
    handles.exp_button.Enable = 'off';
    handles.moran_button.Enable = 'off';
    handles.wright_button.Enable = 'off';
    handles.num_types_box.Enable = 'off';
    handles.types_popup.Enable = 'off';
    handles.init_pop_box.Enable = 'off';
    handles.param_1_box.Enable = 'off';
    handles.param_2_box.Enable = 'off';
    handles.plot_button_count.Enable = 'off';
    handles.plot_button_percent.Enable = 'off';
    handles.plot_button_fitness.Enable = 'off';
    handles.plot_button_linear.Enable = 'off';
    handles.plot_button_log.Enable = 'off';
%     handles.save_button.Enable = 'off';
%     handles.step_button.Enable = 'off';
%     handles.reset_button.Enable = 'off';
end




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

% % --- Executes during object creation, after setting all properties.
% function max_iterations_box_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to max_iterations_box (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end


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
