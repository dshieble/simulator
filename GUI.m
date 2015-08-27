function varargout = GUI(varargin)
% This is the main function for the Population Dynamics Simulator Project.
% This is a guide-generated file, and it contains all of the GUI Callbacks.

% Author: Dan Shiebler
% Email: danshiebler@gmail.com
% Phone: 973-518-0886


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



% Attach global variables to handles object
handles.f.UserData = GUIHelper(handles, varargin);


% Update handles structure
guidata(hObject, handles);





% --- Outputs from this function are returned to the command line.
function varargout = GUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
varargout{1} = handles.output;

% --- Executes on button press in run_button.
function run_button_Callback(hObject, eventdata, handles)
if handles.f.UserData.stepping
    return;
end
errorMessage = handles.f.UserData.verifyParameters(handles);
if ~isempty(errorMessage)
    warndlg(errorMessage);
end
if ~handles.f.UserData.evolving && ~handles.f.UserData.paused && isempty(errorMessage)
    handles.f.UserData.run(handles, 0);
elseif ~handles.f.UserData.evolving && handles.f.UserData.paused %continue
    handles.f.UserData.continueRunning(handles);
elseif handles.f.UserData.evolving && ~handles.f.UserData.paused %pause
    handles.f.UserData.pauseRunning(handles);
end
if ~handles.f.UserData.paused && ~handles.f.UserData.evolving;
    handles.run_button.String = 'Run';
    handles.run_button.BackgroundColor = [0 1 0];
    handles.save_button.BackgroundColor = [0 1 1];
    handles.reset_button.BackgroundColor = [1 0 0];
    handles.step_button.BackgroundColor = [0 0 1];

    drawnow;
end

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
printdlg(handles.f)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.f,'Name') '?'],...
                     ['Close ' get(handles.f,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end
delete(handles.f)



function types_popup_Callback(hObject, eventdata, handles)
% Executes on selection change in types_popup.
handles.f.UserData.parameterManager.updateBoxes();

function numTypes_box_Callback(hObject, eventdata, handles)
% Executes when number of types is changed
handles.f.UserData.parameterManager.updateNumTypes();

function init_pop_box_Callback(hObject, eventdata, handles)
% Executes when initial population is changed
handles.f.UserData.parameterManager.updateStructs();

function param_1_box_Callback(hObject, eventdata, handles)
% Executes when parameter 1 is changed
handles.f.UserData.parameterManager.updateStructs();

function param_2_box_Callback(hObject, eventdata, handles)
% Executes when parameter 2 is changed
handles.f.UserData.parameterManager.updateStructs();

function save_button_Callback(hObject, eventdata, handles)
% Executes on button press in save_button.
try
    if ~handles.f.UserData.evolving && ~handles.f.UserData.stepping
        c = clock; str = sprintf('Population Data: %d|%d|%d|%d|%d|%2.1f.mat',c(1),c(2),c(3),c(4),c(5),c(6));
        saveData = handles.f.UserData.gridManager.saveData;
        save(str, 'saveData');
    end
catch 
    fprintf('ERROR: Save Error\n');
end



function reset_button_Callback(hObject, eventdata, handles)
% Executes on button press in reset_button.
if ~handles.f.UserData.evolving && ~handles.f.UserData.stepping
    handles.f.UserData.cleanup(handles)
    cla(handles.axes_grid);
    cla(handles.axes_graph);
    handles.f.UserData.rects = cell(sqrt(numel(handles.f.UserData.gridManager.matrix)));
    drawnow;
    handles.page_button.Enable = 'off';
    handles.f.UserData.toggleVisible(handles);
end


function model1_button_Callback(hObject, eventdata, handles)
% Executes on button press in model1_button.
handles.f.UserData.parameterManager.updateBasicParameters()
handles.model_name_banner.String = handles.f.UserData.parameterManager.classConstants(handles.f.UserData.parameterManager.currentModel).Name;
handles.f.UserData.parameterManager.updateBoxes();
handles.f.UserData.toggleVisible(handles);


function model2_button_Callback(hObject, eventdata, handles)
% Executes on button press in model2_button.
handles.f.UserData.parameterManager.updateBasicParameters()
handles.model_name_banner.String = ...
    handles.f.UserData.parameterManager.classConstants(handles.f.UserData.parameterManager.currentModel).Name;
handles.f.UserData.parameterManager.updateBoxes();
handles.f.UserData.toggleVisible(handles);

function model3_button_Callback(hObject, eventdata, handles)
% Executes on button press in model3_button.
handles.f.UserData.parameterManager.updateBasicParameters()
handles.model_name_banner.String = handles.f.UserData.parameterManager.classConstants(handles.f.UserData.parameterManager.currentModel).Name;
handles.f.UserData.parameterManager.updateBoxes();
handles.f.UserData.toggleVisible(handles);


function model4_button_Callback(hObject, eventdata, handles)
% Executes on button press in model4_button.
handles.f.UserData.parameterManager.updateBasicParameters()
handles.model_name_banner.String = handles.f.UserData.parameterManager.classConstants(handles.f.UserData.parameterManager.currentModel).Name;
handles.f.UserData.parameterManager.updateBoxes();
handles.f.UserData.toggleVisible(handles);

function population_box_Callback(hObject, eventdata, handles)
% Executes on changing the population
handles.f.UserData.parameterManager.updateMatrixProperties();
    

function matrixOn_button_Callback(hObject, eventdata, handles)
% Executes on button press in matrixOn_button.
handles.f.UserData.parameterManager.setMatrixOn(handles.matrixOn_button.Value);
handles.f.UserData.toggleVisible(handles);


function preview_button_Callback(hObject, eventdata, handles)
% Executes on button press in preview_button.
if handles.f.UserData.evolving || handles.f.UserData.stepping
    return
else
    if ~handles.f.UserData.parameterManager.mutating ||...
            handles.f.UserData.parameterManager.numLoci < 12
        handles.preview_button.String = 'Pulling up the Population Parameters...';
        drawnow;
        PopulationParametersDialog(handles.f.UserData.parameterManager);
        handles.preview_button.String = 'See All Population Parameters';
    else
        warndlg('Number of Loci must be less than 12 to see all population parameters!');
    end
end


function mutation_matrix_button_Callback(hObject, eventdata, handles)
% Executes on button press in mutation_matrix_button.
if ~handles.f.UserData.evolving && ~handles.f.UserData.stepping
    m = MutationMatrixDialog(handles.f.UserData.parameterManager.mutationMatrix, handles.f.UserData.parameterManager.numLoci);
    if ~isempty(m) 
        handles.f.UserData.parameterManager.setMutationMatrix(m);
    end
end

function initial_frequencies_button_Callback(hObject, eventdata, handles)
% Executes on button press in initial_frequencies_button.
if ~handles.f.UserData.evolving && ~handles.f.UserData.stepping &&...
        handles.f.UserData.parameterManager.mutating && handles.f.UserData.parameterManager.numLoci > 1
    if handles.f.UserData.parameterManager.numLoci >= 12
    	warndlg('Number of Loci must be less than 12 to edit initial frequencies');
        return;
    end
    f = InitialFrequenciesDialog(handles.f.UserData.parameterManager.initialFrequencies,...
        handles.f.UserData.parameterManager.numLoci);
    if ~isempty(f) 
        handles.f.UserData.parameterManager.setInitialFrequencies(f);
    end
end

function genetics_button_Callback(hObject, eventdata, handles)
% Executes on button press in genetics_button.
handles.f.UserData.parameterManager.updateBasicParameters();
handles.f.UserData.toggleVisible(handles);

function loci_box_Callback(hObject, eventdata, handles)
% Executes when number of loci is changed
m = handles.f.UserData.parameterManager.updateMultipleLoci();
if ~isempty(m)
    warndlg(m);
    return;
end
handles.f.UserData.toggleVisible(handles);
handles.f.UserData.parameterManager.updateBoxes();

function step_button_Callback(hObject, eventdata, handles)
% Executes on button press in step_button.
if ~handles.f.UserData.stepping && ~handles.f.UserData.evolving
    if ~handles.f.UserData.paused
        handles.f.UserData.run(handles,1)
        handles.f.UserData.pauseRunning(handles);
    else
        if isempty(handles.f.UserData.gridManager)
            fprintf('ERROR: Grid Manager Empty')
            return
        end
        handles.f.UserData.stepping = 1;
        handles.f.UserData.enableButtons(handles, 0)
        handles.run_button.Enable = 'off';
        handles.run_button.BackgroundColor = [.25 .25 .25];
        handles.save_button.BackgroundColor = [.25 .25 .25];
        handles.reset_button.BackgroundColor = [.25 .25 .25];
        handles.step_button.BackgroundColor = [.25 .25 .25];
        drawnow;
        [c, halt] = handles.f.UserData.gridManager.getNext();
        handles.f.UserData.drawIteration(c, handles, 0);
        handles.f.UserData.stepping = 0;
        handles.run_button.Enable = 'on';
        handles.run_button.BackgroundColor = [0 1 0];
        handles.save_button.BackgroundColor = [0 1 1];
        handles.reset_button.BackgroundColor = [1 0 0];
        handles.step_button.BackgroundColor = [0 0 1]; 
        handles.f.UserData.enableButtons(handles, 1)
        if halt
            handles.f.UserData.cleanup(handles)
        end
    end
    handles.f.UserData.enableInputs(handles, 0);
    handles.f.UserData.enableButtons(handles, 1);
end
    


function spatial_structure_check_Callback(hObject, eventdata, handles)
% Executes on button press in spatial_structure_check.
handles.f.UserData.parameterManager.updateBasicParameters();



function recombination_check_Callback(hObject, eventdata, handles)
% Executes on button press in recombination_check.
handles.f.UserData.parameterManager.updateBasicParameters();
handles.f.UserData.toggleVisible(handles);



function recombination_box_Callback(hObject, eventdata, handles)
% Executes on button press in recombination_box.
handles.f.UserData.parameterManager.updateBasicParameters();



function page_button_Callback(hObject, eventdata, handles)
% Executes on button press in page_button.
% Flip to the next page of the graph
if isempty(handles.f.UserData.gridManager)
    return
end
if ~handles.f.UserData.stepping &&...
        handles.f.UserData.gridManager.numTypes > 16
    handles.f.UserData.group = handles.f.UserData.group + 16;
    if handles.f.UserData.group > handles.f.UserData.gridManager.numTypes
        handles.f.UserData.group = 1;
    end
    handles.f.UserData.drawPage(handles, 1);
end


function remove_edges_check_Callback(hObject, eventdata, handles)
% Executes on button press in remove_edges_check.
handles.f.UserData.parameterManager.updateBasicParameters();


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
function numTypes_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numTypes_box (see GCBO)
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
