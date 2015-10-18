classdef GUIHelper < handle
    %This is the class that stores the utility functions to support the
    %main function. The functions in this class are called by the GUI
    %Callback functions and directly manipulate the uicontrols
    
    
    % The main purpose of this class is interfacing with the
    % ParameterManager class, which stores the parameters that the user inputs,
    % and instantiating the GridManager classes, which run the simulation using
    % the variables in ParameterManager. This function also handles what components 
    % of the GUI are presented to the user. 

    % All messages that are presented to the user (except for the uitable dialogs)
    % are created in this file or the main function
    
    %TODO: Speed up plotting by changing rects to Visible/Invisible rather
    %than destroying them
    
    properties
        handles; %The struct that stores handles to all of the graphical objects
        group; %The group of 8 types that we are displaying on the plot_axes. This is always 1 if numTypes <= 16
        parameterManager; %The ParameterManager object that stores and verifies the user inputted parameters
        rects; %The matrix of rectangle objects that are drawn or changed every iteration
        gridManager; %The GridManager object that runs the simulation
        temp_axes; %TODO: Get rid of this
        
        %Status
        paused; %This is 1 if the simulator is in the paused state
        evolving; %This is 1 if the simulator is in the evolving state
        stepping; %This is 1 if the simulator is in the stepping state
    end
    
    methods
        
        
        %TODO: Make handles a class property and remove all these functions
        %calls with it as an input
        
        
        
        function obj = GUIHelper(handles, names)
            %The constructor for the GUIHelper class. 
            % names - The input to the Main function, which is either empty
            % or a list of class names
            obj.handles = handles;
            classNames = {'GridManagerLogistic', 'GridManagerExp', 'GridManagerMoran', 'GridManagerWright'};

            % Verify the Class Names input
            if ~isempty(names)
                e = [];
                for i = 1:length(names)
                    try 
                        obj.getConstantProperty(names{i}, 'Name');
                        obj.getConstantProperty(names{i}, 'OverlappingGenerations');
                        obj.getConstantProperty(names{i}, 'ParamName1');
                        obj.getConstantProperty(names{i}, 'ParamName2');
                        obj.getConstantProperty(names{i}, 'ParamBounds1');
                        obj.getConstantProperty(names{i}, 'ParamBounds2');
                        obj.getConstantProperty(names{i}, 'atCapacity');
                        obj.getConstantProperty(names{i}, 'plottingEnabled');
                    catch e
                        fprintf('%s is not a valid class. Initializing with the default classes.', names{i});
                        break
                    end
                end
                if isempty(e)
                    disp('Names Registered Successfully!');
                    classNames = names(1:min(4, length(names)));
                end
            end
            
            
            
            % Build up a struct array of the Constant properties of each class
            classConstants = struct(...
                'className', repmat({[]}, 1, length(classNames)),...
                'Name', repmat({[]}, 1, length(classNames)),...
                'OverlappingGenerations', repmat({[]}, 1, length(classNames)),...
                'ParamName1', repmat({[]}, 1, length(classNames)),...
                'ParamName2', repmat({[]}, 1, length(classNames)),...
                'ParamBounds1', repmat({[]}, 1, length(classNames)),...
                'ParamBounds2', repmat({[]}, 1, length(classNames)),...
                'atCapacity', repmat({[]}, 1, length(classNames)),...
                'plottingEnabled', repmat({[]}, 1, length(classNames))...
            );
            for i = 1:length(classNames)
                classConstants(i).className = classNames{i};
                classConstants(i).Name = obj.getConstantProperty(classNames{i}, 'Name');
                classConstants(i).OverlappingGenerations = obj.getConstantProperty(classNames{i}, 'OverlappingGenerations');
                classConstants(i).ParamName1 = obj.getConstantProperty(classNames{i}, 'ParamName1');
                classConstants(i).ParamName2 = obj.getConstantProperty(classNames{i}, 'ParamName2');
                classConstants(i).ParamBounds1 = obj.getConstantProperty(classNames{i}, 'ParamBounds1');
                classConstants(i).ParamBounds2 = obj.getConstantProperty(classNames{i}, 'ParamBounds2');
                classConstants(i).atCapacity = obj.getConstantProperty(classNames{i}, 'atCapacity');
                classConstants(i).plottingEnabled = obj.getConstantProperty(classNames{i}, 'plottingEnabled');
            end
            % Set text based on the classNames and classConstants
            obj.handles.model_name_banner.String = classConstants(1).Name;
            for i = 1:4 
                if i <= length(classNames)
                    %Set the text on the button to be the model name
                    eval(sprintf('obj.handles.model%s_button.String = ''%s'';',num2str(i), classConstants(i).Name));
                else
                    %Otherwise, hide the button
                    eval(['obj.handles.model' num2str(i) '_button.Visible = ''off'';']);        
                end
            end
            
            %Initialize the basic parameters
            obj.parameterManager = ParameterManager(obj.handles, classConstants);
            obj.group = 1;
            obj.evolving = 0;
            obj.rects = [];
            obj.paused = 0;
            obj.gridManager = [];
            obj.stepping = 0;
            
            %Temp_axes stuff
            obj.temp_axes = axes('Parent',obj.handles.params_panel, 'Position', obj.handles.param_2_text.Position);
            obj.temp_axes.Visible = 'off';
            fill([0,0,0,0], [0,0,0,0], 'w', 'Parent', obj.handles.axes_grid);
            set(obj.handles.axes_grid,'XTick',[]);
            set(obj.handles.axes_grid,'YTick',[]);
            obj.handles.axes_grid.XLim = [1 sqrt(obj.parameterManager.popSize)];
            obj.handles.axes_grid.YLim = [1 sqrt(obj.parameterManager.popSize)];


            %Fill the boxes properly
            obj.toggleVisible()

        end

        
        
        function message = verifyParameters(obj)
            %This function makes sure that all of the input boxes are aligned with the
            %expected inputs. This function is called only when the run button is
            %pressed
            
            if obj.parameterManager.mutating && (obj.parameterManager.numLoci > obj.parameterManager.maxNumLoci)
                message = sprintf('ERROR: The number of loci must be no greater than %d.', obj.parameterManager.maxNumLoci);
            elseif ~isempty(obj.parameterManager.updateBoxValues());
                message = obj.parameterManager.updateBoxValues();
            elseif obj.parameterManager.mutating && obj.parameterManager.numLoci > 1 && obj.parameterManager.s < -1;
                message = 'ERROR: S must be no less than -1!';
            elseif ~obj.parameterManager.verifySizeOk()
                message = sprintf('ERROR: Initial Populations must sum to %d for constant size models (Moran, Wright-Fisher), and must be no greater than %d for non-constant size models (Exponential, Logistic)', obj.parameterManager.popSize, obj.parameterManager.popSize);
            elseif (obj.handles.plot_button_age.Value && ~obj.parameterManager.matrixOn) || (obj.handles.plot_button_age.Value && obj.parameterManager.getNumTypes() > 16)
                message = 'ERROR: In order to plot the age distribution, you need to turn the Petri Dish on. You cannot turn the Petri Dish on if the number of types is at least 16.';
            else
                message = '';
            end
        end


        function adjustText(obj)
            %This function adjusts the text in Population Demographics box
            %where the user inputs the Ninit and values for param1 and
            %param2. 
            cla(obj.handles.formula_axes);
            cla(obj.temp_axes);
            obj.temp_axes.Visible = 'off';
            if obj.parameterManager.mutating && obj.parameterManager.numLoci > 1
                obj.handles.param_1_text.String = 'S:';
                text(obj.handles.param_2_text.Position(3) + .5, 0.5,'$$\epsilon$$:','FontSize',15,...
                    'Interpreter','latex', 'Parent', obj.temp_axes);
                set(obj.temp_axes,...
                    'XGrid', 'off', 'YGrid', 'off', 'ZGrid', 'off', ...
                    'Color', 'none', 'Visible', 'on', ...
                    'XColor','none','YColor','none')
                obj.handles.param_2_text.Visible = 'off';
                obj.handles.param_2_box.Visible = 'on';
                %Draw the formula for param1 computation when numLoci > 1
                if obj.parameterManager.classConstants(obj.parameterManager.currentModel).OverlappingGenerations
                    str = 'Birth Rate: $$1+sk^{1-\epsilon}$$';
                    text(0,0.5,str,'FontSize',15, 'Interpreter','latex', 'Parent', obj.handles.formula_axes);
                else
                    str = 'Fitness: $$  e^{sk^{1-\epsilon}} $$';
                    text(0,0.5,str,'FontSize',18, 'Interpreter','latex', 'Parent', obj.handles.formula_axes);
                end
                if ~isempty(obj.parameterManager.classConstants(obj.parameterManager.currentModel).ParamName2)
                    str2 = 'Death Rate: 0.01';
                    text(0,0.2,str2,'FontSize',15, 'Interpreter','latex', 'Parent', obj.handles.formula_axes);
                end
            else
                obj.handles.param_1_text.String = [obj.parameterManager.classConstants(obj.parameterManager.currentModel).ParamName1 ':'];        
                if ~isempty(obj.parameterManager.classConstants(obj.parameterManager.currentModel).ParamName2)
                    obj.handles.param_2_text.String = [obj.parameterManager.classConstants(obj.parameterManager.currentModel).ParamName2 ':'];  
                    obj.handles.param_2_text.Visible = 'on';
                    obj.handles.param_2_box.Visible = 'on';
                else 
                    obj.handles.param_2_text.Visible = 'off';
                    obj.handles.param_2_box.Visible = 'off';
                end
            end
        end




        function adjustDisplay(obj)
        	%Updates the initial popBox and numLoci based on the parameter
            %manager contents
            if obj.parameterManager.numLoci > 1 && obj.parameterManager.mutating
                obj.handles.num_types_box.String = sprintf('%d', 2^obj.parameterManager.numLoci);
                if ~obj.parameterManager.classConstants(obj.parameterManager.currentModel).atCapacity
                    obj.handles.init_pop_box.String = 1;
                else
                    obj.handles.init_pop_box.String = obj.parameterManager.popSize;
                end
            end
        end
        
        
        function toggleVisible(obj)
            %Adjust which of the buttons and knobs the user sees, based on
            %the current input state. Should only be called AFTER the
            %parameterManager updateAll function
            obj.adjustDisplay();
            obj.handles.recombination_panel.Visible = 'off';
            %mutating or not
            if obj.parameterManager.mutating               
                obj.handles.mutation_panel.Visible = 'on';
                obj.handles.num_types_string.String = 'Number of Alleles:';
                obj.handles.params_string.String =  'Parameters For Allele:';
            else
                obj.handles.mutation_panel.Visible = 'off';
                obj.handles.num_types_string.String = 'Number of Types:';
                obj.handles.params_string.String =  'Parameters For Type:';
            end
            %numLoci > 1 or not
            if obj.parameterManager.mutating && (obj.parameterManager.numLoci > 1)
                %popup
                obj.handles.types_popup.Visible = 'off';
                obj.handles.params_string.Visible=  'off';
                %num_types
                
                obj.handles.num_types_box.Visible = 'off';
                obj.handles.num_types_string.Visible = 'off';
                obj.handles.init_pop_box.Visible = 'off';
                %initial frequencies
                obj.handles.initial_frequencies_button.Visible = 'on';
                %matrixOn
                obj.handles.recombination_check.Visible = 'on';
                if obj.parameterManager.recombining == 1
                    obj.handles.recombination_panel.Visible = 'on';
                end
            else
                %popup
                obj.handles.types_popup.Visible = 'on';
                obj.handles.params_string.Visible= 'on';
                %num_types
                obj.handles.num_types_box.Visible = 'on';
                obj.handles.num_types_string.Visible = 'on';
                obj.handles.init_pop_box.Visible = 'on';
                obj.handles.recombination_check.Visible = 'off';
                %initial frequencies
                obj.handles.initial_frequencies_button.Visible = 'off';
            end
            if obj.parameterManager.classConstants(obj.parameterManager.currentModel).plottingEnabled &&...
                    (~obj.parameterManager.mutating || obj.parameterManager.numLoci <= 16) %don't plot if too many loci or not plotting enabled
                obj.handles.matrixOn_button.Enable = 'on';
            else
                obj.handles.matrixOn_button.Value = 0;
                obj.handles.matrixOn_button.Enable = 'off';
            end
            if obj.parameterManager.matrixOn && ~strcmp(obj.parameterManager.classConstants(obj.parameterManager.currentModel).Name, 'Wright-Fisher')
                obj.handles.spatial_structure_check.Visible = 'on';
                obj.handles.remove_edges_check.Visible = 'on';
            else
                obj.handles.spatial_structure_check.Visible = 'off';
                obj.handles.remove_edges_check.Visible = 'off';
            end
            obj.adjustText();
        end



        function enableInputs(obj, on)
            %This function either enables or disables all of the user
            %inputs that affect parameters or display. This is called when
            %the user presses run or clear/reset.
            obj.toggleVisible();
            if on
                s = 'on';
            else
                s = 'off';
            end
            obj.handles.matrixOn_button.Enable = s;
            obj.handles.population_box.Enable = s;
            obj.handles.genetics_button.Enable = s;
            obj.handles.spatial_structure_check.Enable = s;
            obj.handles.recombination_check.Enable = s;
            obj.handles.recombination_box.Enable = s;
            obj.handles.remove_edges_check.Enable = s;
            obj.handles.model1_button.Enable = s;
            obj.handles.model2_button.Enable = s;
            obj.handles.model3_button.Enable = s;
            obj.handles.model4_button.Enable = s;
            obj.handles.num_types_box.Enable = s;
            obj.handles.types_popup.Enable = s;
            obj.handles.init_pop_box.Enable = s;
            obj.handles.loci_box.Enable = s;
            obj.handles.param_1_box.Enable = s;
            obj.handles.param_2_box.Enable = s;
            obj.handles.plot_button_count.Enable = s;
            obj.handles.plot_button_percent.Enable = s;
            obj.handles.plot_button_fitness.Enable = s;
            obj.handles.plot_button_age.Enable = s;
            obj.handles.mutation_matrix_button.Enable = s;
            obj.handles.initial_frequencies_button.Enable = s;
        end

        
        function enableButtons(obj, on)
            %Enable or Disable the pause/save/step buttons
            if on
                s = 'on';
            else
                s = 'off';
            end
            obj.handles.save_button.Enable = s;
            obj.handles.step_button.Enable = s;
            obj.handles.reset_button.Enable = s;
            obj.handles.preview_button.Enable = s;
            if obj.parameterManager.getNumTypes() > 8
                obj.handles.page_button.Enable = s;
            else
                obj.handles.page_button.Enable = 'off';
            end
        end

        
        function cleanup(obj)
            %Responsible for resetting all of the things on the screen to their
            %defaults. Called when the user presses clear/reset
            obj.enableInputs(1)
            obj.enableButtons(1)
            obj.paused = 0;
            obj.evolving = 0;
            obj.stepping = 0;
            obj.handles.run_button.String = 'Run';
            obj.handles.run_button.BackgroundColor = [0 1 0];
            obj.handles.step_button.BackgroundColor = [0 0 1];
            obj.handles.save_button.BackgroundColor = [0 1 1];
            obj.handles.reset_button.BackgroundColor = [1 0 0];
            obj.handles.generationLabel.String = 'Generation: 0';
        end


        function runLoop(obj, firstRun, runOnce)
            %This function runs the actual simulation in a while loop
            %TODO: MAYBE change to a timer? Ctrl-C is useful though
            if isempty(obj.gridManager)
                fprintf('ERROR: Grid Manager Empty')
                return
            end
            warning('OFF','MATLAB:legend:PlotEmpty');
            if obj.group > obj.gridManager.numTypes
                obj.group = 1;
            end
            %Draw the rectangle objects on the grid
            for ind = 1:numel(obj.gridManager.matrix)
                [i, j] = ind2sub(sqrt(numel(obj.gridManager.matrix)), ind);
                mult = 50/sqrt(numel(obj.gridManager.matrix));
                obj.rects{i,j} = rectangle(...
                    'Parent', obj.handles.axes_grid,...
                    'Position',[mult*i-mult mult*j-mult mult*1 mult*1], ...
                    'Visible', 'off');
            end
            drawnow;
            while obj.evolving
               if ~firstRun
                   [c, halt] = obj.gridManager.getNext();
               else
                   halt = 0;
                   c = find(obj.gridManager.matrix);
               end
               obj.drawIteration(c, firstRun);
               firstRun = 0;
               if runOnce || halt
                   break;
               end
            end
        end

        
        function drawIteration(obj, c, firstRun)
            %A single iteration of the simulation loop
            if obj.gridManager.matrixOn 
                %Draw the matrix
                perm = c(randperm(length(c)))';
                for p = perm
                    %Change the color of the rectangle objects
                    %appropriately.
                    [i, j] = ind2sub(size(obj.gridManager.matrix), p);
                    if obj.gridManager.matrix(i,j) == 0
                        obj.rects{i,j}.Visible = 'off';
                    else
                        obj.rects{i,j}.Visible = 'on';
                        obj.rects{i,j}.FaceColor = obj.gridManager.getColor(obj.gridManager.matrix(i,j));
                    end
                end
            end
            obj.handles.generationLabel.String = sprintf('Generation: %d', obj.gridManager.timestep - 1);
            %Draw the plot to the lower axis
            obj.drawPage(firstRun);
            drawnow;
        end
            



        function drawPage(obj, firstRun)
            %Fills in the legendInput, draws the legend and parameter plots to the screen. Draws all
            %types in the interval [obj.group, (obj.group + 8)]
            axes(obj.handles.axes_graph); %make the axes_graph the active axes
            cla(obj.handles.axes_graph);
            if isempty(obj.gridManager)
                fprintf('ERROR: Grid Manager Empty\n')
                return
            end
            if obj.group > obj.gridManager.numTypes
                obj.group = 1;
            end
            range = obj.group:min(obj.group + 7, obj.gridManager.numTypes);
            %Plot the parameters on the graph
            if obj.handles.plot_button_count.Value
                mat = obj.gridManager.totalCount(range, :);
                y_axis_label = 'Population Count';
            elseif obj.handles.plot_button_percent.Value
                mat = obj.gridManager.percentCount(range, :);
                y_axis_label = 'Percent Population Size';
            elseif obj.handles.plot_button_age.Value
                mat = obj.gridManager.ageStructure{obj.gridManager.timestep}(range, :);
                y_axis_label = 'Proportion of Organisms';
            else
                mat = obj.gridManager.overallMeanFitness(:)';
                y_axis_label = 'Mean Fitness';
            end
            %Handle logistic plotting
            if obj.handles.plot_button_log.Value
                mat = log10(mat);
                y_axis_label = sprintf('log10(%s)', y_axis_label);
            end
            %Actually plots the line graph
            for i = 1:size(mat,1)
                hold on;
                if obj.handles.plot_button_age.Value
                    marker = 'o';
                else
                    marker = 'o-';
                end
                plot(0:length(mat(i,:))-1, mat(i,:), marker, 'MarkerFaceColor', obj.gridManager.getColor(i), 'Parent', obj.handles.axes_graph, 'Color', obj.gridManager.getColor(i));
            end
            %draws the correct xlabel
            if ~obj.handles.plot_button_age.Value
                xlabel('Generations', 'Parent', obj.handles.axes_graph);
            else
                xlabel('Age', 'Parent', obj.handles.axes_graph);
            end
            ylabel(y_axis_label, 'Parent', obj.handles.axes_graph);
            obj.drawLegend(range, firstRun);
        end
        
        
        function drawLegend(obj, range, firstRun)
            %Draws the legend to the screen
            if ~obj.handles.plot_button_fitness.Value
                legendInput = {};
                for i = range
                    if obj.parameterManager.numLoci > 1 && obj.parameterManager.mutating
                        legendInput = [legendInput sprintf('Type %s', dec2bin(i - 1, log2(obj.gridManager.numTypes)))];
                    else
                        legendInput = [legendInput sprintf('Type %d', i)];
                    end
                end
%                 L = findobj('type','legend');
                if firstRun
                    legend(legendInput, 'Location', 'northwest', 'Parent', obj.handles.bottom_panel, ...
                        'FontName', 'FixedWidth', 'FontSize', 8);
                end
            end
            
        end
        
        
        function run(obj, runOnce)
            %This function executes the simulation and is called directly
            %by the run button callback
 
            %If the number of types is greater than 16, turn petri dish off
            if obj.parameterManager.getNumTypes() > 16
                obj.handles.matrixOn_button.Value = 0;
                obj.parameterManager.updateBoxValues();
            end
            obj.group = 1;
            obj.handles.run_button.String = 'Calculating...';
            obj.evolving = 1;
            obj.toggleVisible()
            %Turn off the boxes on the screens and recolor the buttons
            obj.enableInputs(0);
            obj.enableButtons(0);
            obj.handles.run_button.String = 'Pause';
            obj.handles.run_button.BackgroundColor = [1 0 0];
            obj.handles.save_button.BackgroundColor = [.25 .25 .25];
            obj.handles.reset_button.BackgroundColor = [.25 .25 .25];
            obj.handles.step_button.BackgroundColor = [.25 .25 .25];
            drawnow;
            %make the obj.gridManager and run the simulation
            obj.initializeGridManager();
            obj.runLoop(1, runOnce);
            %when the simulation terminates
            obj.evolving = 0;
            %if the termination is not a pause
            if ~obj.paused
                obj.cleanup()
            end
        end

        function continueRunning(obj)
            %Break the pause and continue running the simulation. This
            %function is called by the run button callback from the
            %continue state
            obj.evolving = 1;
            obj.paused = 0;
            obj.enableInputs(0);
            obj.enableButtons(0)
            obj.handles.run_button.String = 'Pause';
            obj.handles.run_button.BackgroundColor = [1 0 0];
            obj.handles.save_button.BackgroundColor = [.25 .25 .25];
            obj.handles.reset_button.BackgroundColor = [.25 .25 .25];
            obj.handles.step_button.BackgroundColor = [.25 .25 .25];
            drawnow;
            obj.runLoop(0, 0);
            obj.evolving = 0;
            if ~obj.paused
                obj.cleanup()
            end
        end

        function pauseRunning(obj)
            %Pause the simulation. 
            obj.evolving = 0;
            obj.paused = 1;
            obj.enableInputs(0);
            obj.enableButtons(1);
            obj.handles.run_button.String = 'Continue';
            obj.handles.run_button.BackgroundColor = [0 1 0];
            obj.handles.step_button.BackgroundColor = [0 0 1];
            obj.handles.save_button.BackgroundColor = [0 1 1];
            obj.handles.reset_button.BackgroundColor = [1 0 0];
            drawnow;
        end

        function initializeGridManager(obj)
            %Initialize the grid manager object based on the parameterManager's parameters and the
            %current model
            MM = MutationManager(obj.parameterManager.mutating,...
                        obj.parameterManager.mutationMatrix,...
                        obj.parameterManager.numLoci,...
                        obj.parameterManager.recombining,...
                        obj.parameterManager.recombinationNumber);

            constructorArguements = {...
                obj.parameterManager.popSize,...
                obj.parameterManager.getField('Ninit'), ...
                MM,...
                obj.parameterManager.matrixOn,...
                obj.parameterManager.spatialOn,...
                obj.parameterManager.edgesOn,...
                obj.parameterManager.getField('Param1'), ...
                obj.parameterManager.getField('Param2')};
            constructor = str2func(obj.parameterManager.classConstants(obj.parameterManager.currentModel).className);
            obj.gridManager = constructor(constructorArguements{:});
            cla(obj.handles.axes_grid);
            cla(obj.handles.axes_graph);
            obj.rects = cell(sqrt(numel(obj.gridManager.matrix)));
        end

        function prop = getConstantProperty(obj, name, propName)
            % Gets a constant property of a class, given that class's name as a string
            mc=meta.class.fromName(name);
            mp=mc.PropertyList;
            [~,loc]=ismember(propName,{mp.Name});
            prop = mp(loc).DefaultValue;
        end

    end
    
end

