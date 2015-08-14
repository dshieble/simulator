function varargout = GUI(varargin)
% This is the main function for the Population Dynamics Simulater Project.
% This is a guide-generated file, and it contains all of the GUI Callbacks.
% The main purpose of this function is interfacing with the
% ParameterManager class, which stores the parameters that the user inputs,
% and instantiating the GridManager classes, which run the simulation using
% the variables in ParameterManager. This function also handles the button
% presses and what components of the GUI are presented to the user. 

% All messages that are presented to the user (except for the uitable dialogs)
% are created in this file

% Caveats on the Programming Style: 
% Many of the variables in the file are global and there are a few calls to
% eval. In general, global and eval are evil, but I personally find global
% both easier to read and more intuitive than getappdata/setappdata. If you have any
% suggestions, email me at Dan.Shiebler@mathworks.com



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
global group evolving parameter_manager rects paused grid_manager parameters_clear stepping spatial_on temp_axes;
classNames = {'GridManagerLogistic', 'GridManagerExp', 'GridManagerMoran', 'GridManagerWright'};
if ~isempty(varargin)
    e = [];
    for i = 1:length(varargin)
        try 
            getConstantProperty(varargin{i}, 'Name');
            getConstantProperty(varargin{i}, 'Generational');
            getConstantProperty(varargin{i}, 'Param_1_Name');
            getConstantProperty(varargin{i}, 'Param_2_Name');
            getConstantProperty(varargin{i}, 'atCapacity');
            getConstantProperty(varargin{i}, 'plottingEnabled');
        catch e
            break
        end
    end
    if isempty(e)
        disp('Names Registered Successfully!');
        classNames = varargin(1:min(4, length(varargin)));
    end
end
classConstants = struct(...
    'className', repmat({[]}, 1, length(classNames)),...
    'Name', repmat({[]}, 1, length(classNames)),...
    'Generational', repmat({[]}, 1, length(classNames)),...
    'Param_1_Name', repmat({[]}, 1, length(classNames)),...
    'Param_2_Name', repmat({[]}, 1, length(classNames)),...
    'atCapacity', repmat({[]}, 1, length(classNames)),...
    'plottingEnabled', repmat({[]}, 1, length(classNames))...
);
for i = 1:length(classNames)
    classConstants(i).className = classNames{i};
    classConstants(i).Name = getConstantProperty(classNames{i}, 'Name');
    classConstants(i).Generational = getConstantProperty(classNames{i}, 'Generational');
    classConstants(i).Param_1_Name = getConstantProperty(classNames{i}, 'Param_1_Name');
    classConstants(i).Param_2_Name = getConstantProperty(classNames{i}, 'Param_2_Name');
    classConstants(i).atCapacity = getConstantProperty(classNames{i}, 'atCapacity');
    classConstants(i).plottingEnabled = getConstantProperty(classNames{i}, 'plottingEnabled');
end
for i = 1:4
    if i <= length(classNames)
        %Set the text on the button to be the model name
        eval(sprintf('handles.model%s_button.String = ''%s'';',num2str(i), classConstants(i).Name));
    else
        %Otherwise, hide the button
        eval(['handles.model' num2str(i) '_button.Visible = ''off'';']);        
    end
end
handles.model_name_banner.String = classConstants(i).Name;
parameter_manager = ParameterManager(handles, classConstants);
group = 1;
evolving = 0;
rects = [];
paused = 0;
grid_manager = [];
parameters_clear = 1;
stepping = 0;
spatial_on = 1;
temp_axes = axes('Parent',handles.params_panel, 'Units', 'characters', 'Position', handles.param_2_text.Position);



% remove tickmarks from axes
temp_axes.Visible = 'off';
fill([0,0,0,0], [0,0,0,0], 'w', 'Parent', handles.axes_grid);
set(handles.axes_grid,'XTick',[]);
set(handles.axes_grid,'YTick',[]);
handles.axes_grid.XLim = [1 sqrt(parameter_manager.pop_size)];
handles.axes_grid.YLim = [1 sqrt(parameter_manager.pop_size)];


%fill the boxes properly
parameter_manager.updateBoxes();
parameter_manager.updateStructs();
toggle_visible(handles)


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
    fprintf('ERROR: Save Error\n');
end



% --- Executes on button press in reset_button.
function reset_button_Callback(hObject, eventdata, handles)
global evolving stepping rects parameter_manager grid_manager;
if ~evolving && ~stepping
    cleanup(handles)
    cla(handles.axes_grid);
    cla(handles.axes_graph);
    rects = cell(sqrt(numel(grid_manager.matrix)));
    drawnow;
    handles.page_button.Enable = 'off';
    toggle_visible(handles);
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

% --- Executes on button press in model1_button.
function model1_button_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.current_model = 1;
handles.model_name_banner.String = parameter_manager.classConstants(parameter_manager.current_model).Name;
parameter_manager.updateBoxes();
toggle_visible(handles);


% --- Executes on button press in model2_button.
function model2_button_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.current_model = 2;
handles.model_name_banner.String = parameter_manager.classConstants(parameter_manager.current_model).Name;
parameter_manager.updateBoxes();
toggle_visible(handles);

% --- Executes on button press in model3_button.
function model3_button_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.current_model = 3;
handles.model_name_banner.String = parameter_manager.classConstants(parameter_manager.current_model).Name;
parameter_manager.updateBoxes();
toggle_visible(handles);

% --- Executes on button press in model4_button.
function model4_button_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.current_model = 4;
handles.model_name_banner.String = parameter_manager.classConstants(parameter_manager.current_model).Name;
parameter_manager.updateBoxes();
toggle_visible(handles);

    
 
function population_box_Callback(hObject, eventdata, handles)
% hObject    handle to population_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of population_box as text
%        str2double(get(hObject,'String')) returns contents of population_box as a double
global parameter_manager;
parameter_manager.updateMatrixProperties();


    

% --- Executes on button press in plot_grid_button.
function plot_grid_button_Callback(hObject, eventdata, handles)

global parameter_manager;
parameter_manager.set_plot_grid(handles.plot_grid_button.Value);
toggle_visible(handles);


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


% --- Executes on button press in genetics_button.
function genetics_button_Callback(hObject, eventdata, handles)
global parameter_manager;
if handles.genetics_button.Value
    parameter_manager.mutating = 1;
    toggle_visible(handles);
    handles.mutation_panel.Visible = 'on';
    handles.num_types_string.String = 'Number of Alleles:';
    handles.params_string.String =  'Parameters For Allele:';
else
    parameter_manager.mutating = 0;
    toggle_visible(handles);
    handles.mutation_panel.Visible = 'off';
    handles.num_types_string.String = 'Number of Types:';
    handles.params_string.String =  'Parameters For Type:';
end 

function loci_box_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.updateMultipleLoci();
toggle_visible(handles);
parameter_manager.updateBoxes();


% function max_iterations_box_Callback(hObject, eventdata, handles)
% global parameter_manager;
% parameter_manager.updateMaxIterations();



% --- Executes on button press in step_button.
function step_button_Callback(hObject, eventdata, handles)
global grid_manager stepping evolving paused;
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
        if halt
            cleanup(handles)
        end
    end
    enable_inputs(handles, 0);
    enable_buttons(handles, 1);
end
    


% --- Executes on button press in spatial_structure_check.
function spatial_structure_check_Callback(hObject, eventdata, handles)
global spatial_on;
spatial_on = handles.spatial_structure_check.Value;



% --- Executes on button press in recombination_check.
function recombination_check_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.recombination = handles.recombination_check.Value;
toggle_visible(handles);



function recombination_box_Callback(hObject, eventdata, handles)
global parameter_manager;
parameter_manager.recombination_number = handles.recombination_box.Value;



% --- Executes on button press in page_button.
function page_button_Callback(hObject, eventdata, handles)
%Flip to the next page of the graph
global evolving stepping group grid_manager;
if isempty(grid_manager)
    return
end
if ~stepping && grid_manager.num_types > 16
    group = group + 16;
    if group > grid_manager.num_types
        group = 1;
    end
    draw_page(handles, 1);
end



















function verify_parameters(handles)
%This function makes sure that all of the input boxes are aligned with the
%expected inputs. This function is called only when the run button is
%pressed
global parameter_manager parameters_clear;
parameters_clear = 0;
if parameter_manager.mutating && (parameter_manager.num_loci > parameter_manager.max_num_loci)
    parameter_manager.num_loci = parameter_manager.max_num_loci;
	warndlg(sprintf('ERROR: The number of loci must be no greater than %d.', parameter_manager.max_num_loci));
elseif ~parameter_manager.updateMatrixProperties()
    warndlg(sprintf('ERROR: If plotting is enabled, then population size must be a perfect square and less than %d. If plotting is not enabled, then population size must be less than 25,000. Population size must be at least 16.', parameter_manager.max_pop_size));
elseif ~parameter_manager.verifyAllBoxesClean();
    warndlg('ERROR: All input must be numerical.');
elseif parameter_manager.mutating && parameter_manager.num_loci > 1 && parameter_manager.s < -1;
    warndlg('ERROR: S must be no less than -1!');
elseif ~parameter_manager.verifySizeOk()
	warndlg(sprintf('ERROR: Initial Populations must sum to %d for constant size models (Moran, Wright-Fisher), and must be no greater than %d for non-constant size models (Exponential, Logistic)', parameter_manager.pop_size, parameter_manager.pop_size));
else    
    parameters_clear = 1;
end

% VisibilityFunctions
%
%
%
%
%
%


function adjust_text(handles)
global parameter_manager temp_axes;
cla(handles.formula_axes);
cla(temp_axes);
temp_axes.Visible = 'off';
if parameter_manager.mutating && parameter_manager.num_loci > 1
    handles.param_1_text.String = 'S:';
    text(handles.param_2_text.Position(3) - 1.75, 0.5,'$$\epsilon$$:','FontSize',15,...
        'Interpreter','latex', 'Parent', temp_axes, 'Units', 'characters');
    set(temp_axes,...
        'XGrid', 'off', 'YGrid', 'off', 'ZGrid', 'off', ...
        'Color', 'none', 'Visible', 'on', ...
        'XColor','none','YColor','none')
    handles.param_2_text.Visible = 'off';
    handles.param_2_box.Visible = 'on';
    if parameter_manager.classConstants(parameter_manager.current_model).Generational
        str = 'Birth Rate: $$1+sk^{1-\epsilon}$$';
        text(0,0.5,str,'FontSize',15, 'Interpreter','latex', 'Parent', handles.formula_axes);
    else
    	str = 'Fitness: $$  e^{sk^{1-\epsilon}} $$';
        text(0,0.5,str,'FontSize',18, 'Interpreter','latex', 'Parent', handles.formula_axes);
    end
    if ~isempty(parameter_manager.classConstants(parameter_manager.current_model).Param_2_Name)
        str2 = 'Death Rate: 0.01';
        text(0,0.2,str2,'FontSize',15, 'Interpreter','latex', 'Parent', handles.formula_axes);
    end
else
    handles.param_1_text.String = [parameter_manager.classConstants(parameter_manager.current_model).Param_1_Name ':'];        
    if ~isempty(parameter_manager.classConstants(parameter_manager.current_model).Param_2_Name)
    	handles.param_2_text.String = [parameter_manager.classConstants(parameter_manager.current_model).Param_2_Name ':'];  
        handles.param_2_text.Visible = 'on';
        handles.param_2_box.Visible = 'on';
    else 
        handles.param_2_text.Visible = 'off';
        handles.param_2_box.Visible = 'off';
    end
end




function toggle_visible(handles)
assert(nargin > 0);
global parameter_manager;
handles.recombination_panel.Visible = 'off';
if (parameter_manager.num_loci > 1) && parameter_manager.mutating
    %popup
    handles.types_popup.Visible = 'off';
    handles.params_string.Visible=  'off';
    %num_types
    handles.num_types_box.Style = 'text';
    handles.init_pop_box.Style = 'text';
    %plot_grid
    parameter_manager.updateBoxes();
    handles.recombination_check.Enable = 'on';
    if parameter_manager.recombination == 1
        handles.recombination_panel.Visible = 'on';
    end
else
    %popup
    handles.types_popup.Visible = 'on';
    handles.params_string.Visible= 'on';
    %num_types
    handles.num_types_box.Style = 'edit';
    handles.init_pop_box.Style = 'edit';
    handles.recombination_check.Enable = 'off';
    %plot_grid
    parameter_manager.updateBoxes();
end
if parameter_manager.classConstants(parameter_manager.current_model).plottingEnabled
    handles.plot_grid_button.Enable = 'on';
else
    parameter_manager.set_plot_grid(0);
    handles.plot_grid_button.Value = 0;
    handles.plot_grid_button.Enable = 'off';
end

if parameter_manager.plot_grid && ~strcmp(parameter_manager.classConstants(parameter_manager.current_model).Name, 'Wright-Fisher')
    handles.spatial_structure_check.Enable = 'on';
else
    handles.spatial_structure_check.Enable = 'off';
end


adjust_text(handles);




function enable_inputs(handles, on)
if on
    handles.plot_grid_button.Enable = 'on';
    handles.population_box.Enable = 'on';
    handles.genetics_button.Enable = 'on';
    handles.spatial_structure_check.Enable = 'on';
    handles.recombination_check.Enable = 'on';
    handles.model1_button.Enable = 'on';
    handles.model2_button.Enable = 'on';
    handles.model3_button.Enable = 'on';
    handles.model4_button.Enable = 'on';
    handles.num_types_box.Enable = 'on';
    handles.types_popup.Enable = 'on';
    handles.init_pop_box.Enable = 'on';
    handles.loci_box.Enable = 'on';
    handles.param_1_box.Enable = 'on';
    handles.param_2_box.Enable = 'on';
    handles.plot_button_count.Enable = 'on';
    handles.plot_button_percent.Enable = 'on';
    handles.plot_button_fitness.Enable = 'on';
    handles.plot_button_linear.Enable = 'on';
    handles.plot_button_log.Enable = 'on';
    handles.mutation_matrix_button.Enable = 'on';
else
    handles.plot_grid_button.Enable = 'off';
    handles.population_box.Enable = 'off';
    handles.genetics_button.Enable = 'off';
    handles.spatial_structure_check.Enable = 'off';
    handles.recombination_check.Enable = 'off';
    handles.model1_button.Enable = 'off';
    handles.model2_button.Enable = 'off';
    handles.model3_button.Enable = 'off';
    handles.model4_button.Enable = 'off';
    handles.num_types_box.Enable = 'off';
    handles.types_popup.Enable = 'off';
    handles.init_pop_box.Enable = 'off';
    handles.loci_box.Enable = 'off';
    handles.param_1_box.Enable = 'off';
    handles.param_2_box.Enable = 'off';
    handles.plot_button_count.Enable = 'off';
    handles.plot_button_percent.Enable = 'off';
    handles.plot_button_fitness.Enable = 'off';
    handles.plot_button_linear.Enable = 'off';
    handles.plot_button_log.Enable = 'off';
    handles.mutation_matrix_button.Enable = 'off';

end

%Responsible for resetting all of the things on the screen to their
%defaults
function cleanup(handles)
global paused evolving stepping;
enable_inputs(handles, 1)
enable_buttons(handles, 1)
paused = 0;
evolving = 0;
stepping = 0;
handles.run_button.String = 'Run';
handles.run_button.BackgroundColor = [0 1 0];
handles.step_button.BackgroundColor = [0 0 1];
handles.save_button.BackgroundColor = [0 1 1];
handles.reset_button.BackgroundColor = [1 0 0];





% Iteration Functions
%
%
%
%
%
function run_loop(first_run, handles, runOnce)
global evolving grid_manager group;
if isempty(grid_manager)
    fprintf('ERROR: Grid Manager Empty')
    return
end
warning('OFF','MATLAB:legend:PlotEmpty');
if group > grid_manager.num_types
    group = 1;
end
while evolving == 1
   try
       [matrix, c, t, halt] = grid_manager.get_next();
   catch e
       disp(e.message);
       break;
   end
   draw_iteration(matrix, c,handles, first_run);
   first_run = 0;
    if runOnce || halt% || (~plot_grid && (grid_manager.timestep > parameter_manager.max_iterations))
        break
    end
end

function draw_iteration(matrix, c, handles, first_run)
global parameter_manager rects grid_manager;
%represents a single iteration of the grid and graph
if isempty(grid_manager)
    fprintf('ERROR: Grid Manager Empty')
    return
end
if grid_manager.plot_grid 
    perm = c(randperm(length(c)))';
    for p = perm
        [i, j] = ind2sub(sqrt(numel(grid_manager.matrix)), p);
        if (~isempty(rects(i,j)))
            delete(rects{i,j});
        end
        if (matrix(i,j) ~= 0)
            mult = 50/sqrt(numel(grid_manager.matrix));
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
axes(handles.axes_graph); %make the axes_graph the active axes
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
        y_axis_label = 'Population Count';
    case 'percent_count'
        vec = grid_manager.percent_count(range, :);
        y_axis_label = 'Percent Population Size';
    case 'overall_mean_fitness'
        vec = grid_manager.overall_mean_fitness(:)';
        y_axis_label = 'Mean Fitness';
end
if grid_manager.plottingParams.plot_log
    vec = log10(vec);
    y_axis_label = sprintf('log10(%s)', y_axis_label);
end
for i = 1:size(vec,1)
    hold on;
    plot(grid_manager.generations, vec(i,:), 'Parent', handles.axes_graph, 'Color', grid_manager.get_color(i));
end
xlabel('Generations', 'Parent', handles.axes_graph);
ylabel(y_axis_label, 'Parent', handles.axes_graph);
%If the plot type is overall mean fitness, there is only one line and no
%need for a legend
if first_run && ~strcmp(grid_manager.plottingParams.plot_type, 'overall_mean_fitness')
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

%   RunFunctions
% 
%
%
%
function run(handles, runOnce)
%Execute the simulation
global evolving group paused parameter_manager;
toggle_visible(handles)
group = 1;
handles.run_button.String = 'Calculating...';
evolving = 1;
%If the number of types is greater than 16, remove plot_grid
if parameter_manager.getNumTypes() > 16
    handles.page_button.Enable = 'on';
    parameter_manager.set_plot_grid(0);
    handles.plot_grid_button.Value = 0;
end
%Turn off the boxes on the screens and recolor the buttons
enable_inputs(handles, 0);
enable_buttons(handles, 0);
handles.run_button.String = 'Pause';
handles.run_button.BackgroundColor = [1 0 0];
handles.save_button.BackgroundColor = [.25 .25 .25];
handles.reset_button.BackgroundColor = [.25 .25 .25];
handles.step_button.BackgroundColor = [.25 .25 .25];
drawnow;
%make the grid_manager and run the simulation
initializeGridManager(handles);
run_loop(1, handles, runOnce);
%when the simulation terminates
evolving = 0;
%if the termination is not a pause
if ~paused
    cleanup(handles)
end

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
if ~paused
    cleanup(handles)
end

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
global grid_manager parameter_manager rects spatial_on;
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
constructor_arguements = {...
    parameter_manager.pop_size,...
    parameter_manager.getField('Ninit'), ...
    MutationManager(parameter_manager),...
    parameter_manager.plot_grid,...
    plottingParams, ...
    spatial_on,...
    parameter_manager.getField('Param1'), ...
    parameter_manager.getField('Param2')};
constructor = str2func(parameter_manager.classConstants(parameter_manager.current_model).className);
grid_manager = constructor(constructor_arguements{:});
cla(handles.axes_grid);
cla(handles.axes_graph);
rects = cell(sqrt(numel(grid_manager.matrix)));

function enable_buttons(handles, on)
if on
    handles.save_button.Enable = 'on';
    handles.step_button.Enable = 'on';
    handles.reset_button.Enable = 'on';
    handles.preview_button.Enable = 'on';
%     handles.page_button.Enable = 'on';
else
    handles.save_button.Enable = 'off';
    handles.step_button.Enable = 'off';
    handles.reset_button.Enable = 'off';
    handles.preview_button.Enable = 'off';
%     handles.page_button.Enable = 'off';
end

function prop = getConstantProperty(name, propName)
% Gets a constant property of a class, given that class's name as a string
mc=meta.class.fromName(name);
mp=mc.PropertyList;
[~,loc]=ismember(propName,{mp.Name});
prop = mp(loc).DefaultValue;
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

% Last Modified by GUIDE v2.5 09-Aug-2015 14:49:25
