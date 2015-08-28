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
        group; %The group of 16 types that we are displaying on the plot_axes. This is always 1 if numTypes <= 16
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
        
        function obj = GUIHelper(handles, names)
            %The constructor for the GUIHelper class. 
            % names - The input to the Main function, which is either empty
            % or a list of class names
            
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
            handles.model_name_banner.String = classConstants(1).Name;
            for i = 1:4 
                if i <= length(classNames)
                    %Set the text on the button to be the model name
                    eval(sprintf('handles.model%s_button.String = ''%s'';',num2str(i), classConstants(i).Name));
                else
                    %Otherwise, hide the button
                    eval(['handles.model' num2str(i) '_button.Visible = ''off'';']);        
                end
            end
            
            %Initialize the basic parameters
            obj.parameterManager = ParameterManager(handles, classConstants);
            obj.group = 1;
            obj.evolving = 0;
            obj.rects = [];
            obj.paused = 0;
            obj.gridManager = [];
            obj.stepping = 0;
            
            %Temp_axes stuff
            obj.temp_axes = axes('Parent',handles.params_panel, 'Units', 'characters', 'Position', handles.param_2_text.Position);
            obj.temp_axes.Visible = 'off';
            fill([0,0,0,0], [0,0,0,0], 'w', 'Parent', handles.axes_grid);
            set(handles.axes_grid,'XTick',[]);
            set(handles.axes_grid,'YTick',[]);
            handles.axes_grid.XLim = [1 sqrt(obj.parameterManager.popSize)];
            handles.axes_grid.YLim = [1 sqrt(obj.parameterManager.popSize)];


            %Fill the boxes properly
            obj.parameterManager.updateBoxes();
            obj.parameterManager.updateStructs();
            obj.toggleVisible(handles)

        end

        function message = verifyParameters(obj, handles)
            %This function makes sure that all of the input boxes are aligned with the
            %expected inputs. This function is called only when the run button is
            %pressed
            
            if obj.parameterManager.mutating && (obj.parameterManager.numLoci > obj.parameterManager.maxNumLoci)
                message = sprintf('ERROR: The number of loci must be no greater than %d.', obj.parameterManager.maxNumLoci);
            elseif ~obj.parameterManager.updateMatrixProperties()
                message = sprintf('ERROR: If plotting is enabled, then population size must be a perfect square and less than %d. If plotting is not enabled, then population size must be less than %d. Population size must be at least 16.', obj.parameterManager.maxPlottingPopSize, obj.parameterManager.maxPopSize);
            elseif ~obj.parameterManager.verifyAllBoxesClean();
                message = 'ERROR: All input must be numerical.';
            elseif obj.parameterManager.mutating && obj.parameterManager.numLoci > 1 && obj.parameterManager.s < -1;
                message = 'ERROR: S must be no less than -1!';
            elseif ~obj.parameterManager.verifySizeOk()
                message = sprintf('ERROR: Initial Populations must sum to %d for constant size models (Moran, Wright-Fisher), and must be no greater than %d for non-constant size models (Exponential, Logistic)', obj.parameterManager.popSize, obj.parameterManager.popSize);
            elseif (handles.plot_button_age.Value && ~obj.parameterManager.matrixOn) || (handles.plot_button_age.Value && obj.parameterManager.getNumTypes() > 16)
                message = 'ERROR: In order to plot the age distribution, you need to turn the Petri Dish on. You cannot turn the Petri Dish on if the number of types is at least 16.';
            else
                message = '';
            end
        end


        function adjustText(obj, handles)
            %This function adjusts the text in Population Demographics box
            %where the user inputs the Ninit and values for param1 and
            %param2. 
            assert(nargin == 2);
            cla(handles.formula_axes);
            cla(obj.temp_axes);
            obj.temp_axes.Visible = 'off';
            if obj.parameterManager.mutating && obj.parameterManager.numLoci > 1
                handles.param_1_text.String = 'S:';
                text(handles.param_2_text.Position(3) - 1.75, 0.5,'$$\epsilon$$:','FontSize',15,...
                    'Interpreter','latex', 'Parent', obj.temp_axes, 'Units', 'characters');
                set(obj.temp_axes,...
                    'XGrid', 'off', 'YGrid', 'off', 'ZGrid', 'off', ...
                    'Color', 'none', 'Visible', 'on', ...
                    'XColor','none','YColor','none')
                handles.param_2_text.Visible = 'off';
                handles.param_2_box.Visible = 'on';
                %Draw the formula for param1 computation when numLoci > 1
                if obj.parameterManager.classConstants(obj.parameterManager.currentModel).OverlappingGenerations
                    str = 'Birth Rate: $$1+sk^{1-\epsilon}$$';
                    text(0,0.5,str,'FontSize',15, 'Interpreter','latex', 'Parent', handles.formula_axes);
                else
                    str = 'Fitness: $$  e^{sk^{1-\epsilon}} $$';
                    text(0,0.5,str,'FontSize',18, 'Interpreter','latex', 'Parent', handles.formula_axes);
                end
                if ~isempty(obj.parameterManager.classConstants(obj.parameterManager.currentModel).ParamName2)
                    str2 = 'Death Rate: 0.01';
                    text(0,0.2,str2,'FontSize',15, 'Interpreter','latex', 'Parent', handles.formula_axes);
                end
            else
                handles.param_1_text.String = [obj.parameterManager.classConstants(obj.parameterManager.currentModel).ParamName1 ':'];        
                if ~isempty(obj.parameterManager.classConstants(obj.parameterManager.currentModel).ParamName2)
                    handles.param_2_text.String = [obj.parameterManager.classConstants(obj.parameterManager.currentModel).ParamName2 ':'];  
                    handles.param_2_text.Visible = 'on';
                    handles.param_2_box.Visible = 'on';
                else 
                    handles.param_2_text.Visible = 'off';
                    handles.param_2_box.Visible = 'off';
                end
            end
        end


        function toggleVisible(obj, handles)
            %Adjust which of the buttons and knobs the user sees, based on
            %the current input state
            assert(nargin == 2);
            handles.recombination_panel.Visible = 'off';
            
            %mutating or not
            if obj.parameterManager.mutating               
                handles.mutation_panel.Visible = 'on';
                handles.num_types_string.String = 'Number of Alleles:';
                handles.params_string.String =  'Parameters For Allele:';
            else
                handles.mutation_panel.Visible = 'off';
                handles.num_types_string.String = 'Number of Types:';
                handles.params_string.String =  'Parameters For Type:';
            end
            %numLoci > 1 or not
            if obj.parameterManager.mutating && (obj.parameterManager.numLoci > 1)
                %popup
                handles.types_popup.Visible = 'off';
                handles.params_string.Visible=  'off';
                %num_types
                handles.num_types_box.Style = 'text';
                handles.num_types_string.String = 'Number of Types:';
                handles.init_pop_box.Style = 'text';
                %initial frequencies
                handles.initial_frequencies_button.Visible = 'on';
                %matrixOn
                obj.parameterManager.updateBoxes();
                handles.recombination_check.Visible = 'on';
                if obj.parameterManager.recombining == 1
                    handles.recombination_panel.Visible = 'on';
                end
            else
                %popup
                handles.types_popup.Visible = 'on';
                handles.params_string.Visible= 'on';
                %num_types
                handles.num_types_box.Style = 'edit';
                handles.init_pop_box.Style = 'edit';
                handles.recombination_check.Visible = 'off';
                %initial frequencies
                handles.initial_frequencies_button.Visible = 'off';
                %matrixOn
                obj.parameterManager.updateBoxes();
            end
            if obj.parameterManager.classConstants(obj.parameterManager.currentModel).plottingEnabled &&...
                    (~obj.parameterManager.mutating || obj.parameterManager.numLoci <= 16) %don't plot if too many loci or not plotting enabled
                handles.matrixOn_button.Enable = 'on';
            else
                obj.parameterManager.setMatrixOn(0);
                handles.matrixOn_button.Value = 0;
                handles.matrixOn_button.Enable = 'off';
            end
            if obj.parameterManager.matrixOn && ~strcmp(obj.parameterManager.classConstants(obj.parameterManager.currentModel).Name, 'Wright-Fisher')
                handles.spatial_structure_check.Visible = 'on';
                handles.remove_edges_check.Visible = 'on';
            else
                handles.spatial_structure_check.Visible = 'off';
                handles.remove_edges_check.Visible = 'off';
            end
            obj.adjustText(handles);
        end




        function enableInputs(obj, handles, on)
            %This function either enables or disables all of the user
            %inputs that affect parameters or display. This is called when
            %the user presses run or clear/reset.
            obj.toggleVisible(handles);
            if on
                s = 'on';
            else
                s = 'off';
            end
            handles.matrixOn_button.Enable = s;
            handles.population_box.Enable = s;
            handles.genetics_button.Enable = s;
            handles.spatial_structure_check.Enable = s;
            handles.recombination_check.Enable = s;
            handles.remove_edges_check.Enable = s;
            handles.model1_button.Enable = s;
            handles.model2_button.Enable = s;
            handles.model3_button.Enable = s;
            handles.model4_button.Enable = s;
            handles.num_types_box.Enable = s;
            handles.types_popup.Enable = s;
            handles.init_pop_box.Enable = s;
            handles.loci_box.Enable = s;
            handles.param_1_box.Enable = s;
            handles.param_2_box.Enable = s;
            handles.plot_button_count.Enable = s;
            handles.plot_button_percent.Enable = s;
            handles.plot_button_fitness.Enable = s;
            handles.plot_button_age.Enable = s;
%             handles.plot_button_linear.Enable = s;
%             handles.plot_button_log.Enable = s;
            handles.mutation_matrix_button.Enable = s;
            handles.initial_frequencies_button.Enable = s;
        end

        
        function enableButtons(obj, handles, on)
            %Enable or Disable the pause/save/step buttons
            if on
                s = 'on';
            else
                s = 'off';
            end
            handles.save_button.Enable = s;
            handles.step_button.Enable = s;
            handles.reset_button.Enable = s;
            handles.preview_button.Enable = s;
%             handles.plot_button_linear.Enable = s;
%             handles.plot_button_log.Enable = s;
        end

        
        function cleanup(obj, handles)
            %Responsible for resetting all of the things on the screen to their
            %defaults. Called when the user presses clear/reset
            obj.enableInputs(handles, 1)
            obj.enableButtons(handles, 1)
            obj.paused = 0;
            obj.evolving = 0;
            obj.stepping = 0;
            handles.run_button.String = 'Run';
            handles.run_button.BackgroundColor = [0 1 0];
            handles.step_button.BackgroundColor = [0 0 1];
            handles.save_button.BackgroundColor = [0 1 1];
            handles.reset_button.BackgroundColor = [1 0 0];
            handles.generationLabel.String = 'Generation: 0';
        end


        function runLoop(obj, firstRun, handles, runOnce)
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
                    'Parent', handles.axes_grid,...
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
               obj.drawIteration(c, handles, firstRun);
               firstRun = 0;
               if runOnce || halt
                   break;
               end
            end
        end

        
        function drawIteration(obj, c, handles, firstRun)
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
            handles.generationLabel.String = sprintf('Generation: %d', obj.gridManager.timestep);
            %Draw the plot to the lower axis
            obj.drawPage(handles, firstRun);
            drawnow;
        end
            



        function drawPage(obj, handles, firstRun)
            %Fills in the legendInput, draws the legend and parameter plots to the screen. Draws all
            %types in the interval [obj.group, (obj.group + 16)]
            axes(handles.axes_graph); %make the axes_graph the active axes
            cla(handles.axes_graph);
            if isempty(obj.gridManager)
                fprintf('ERROR: Grid Manager Empty\n')
                return
            end
            if firstRun
                legend('hide');
            end
            if obj.group > obj.gridManager.numTypes
                obj.group = 1;
            end
            range = obj.group:min(obj.group + 15, obj.gridManager.numTypes);
            %Plot the parameters on the graph
            if handles.plot_button_count.Value
                mat = obj.gridManager.totalCount(range, :);
                y_axis_label = 'Population Count';
            elseif handles.plot_button_percent.Value
                mat = obj.gridManager.percentCount(range, :);
                y_axis_label = 'Percent Population Size';
            elseif handles.plot_button_age.Value
                mat = obj.gridManager.ageStructure{obj.gridManager.timestep}(range, :);
                y_axis_label = 'Proportion of Organisms';
            else
                mat = obj.gridManager.overallMeanFitness(:)';
                y_axis_label = 'Mean Fitness';
            end
            %Handle logistic plotting
            if handles.plot_button_log.Value
                mat = log10(mat);
                y_axis_label = sprintf('log10(%s)', y_axis_label);
            end
            %Actually plots the line or bar graph
            for i = 1:size(mat,1)
                hold on;
                plot(1:length(mat(i,:)), mat(i,:), 'Parent', handles.axes_graph, 'Color', obj.gridManager.getColor(i));

%                 if ~handles.plot_button_age.Value
% %                 else
% %                     cla(handles.axes_graph);
% %                     bar(1:length(mat), mat, 'Parent', handles.axes_graph);
%                 end
            end
            %draws the correct xlabel
            if ~handles.plot_button_age.Value
                xlabel('Generations', 'Parent', handles.axes_graph);
            else
                xlabel('Age', 'Parent', handles.axes_graph);
            end
            ylabel(y_axis_label, 'Parent', handles.axes_graph);
            %There is no legend in the one line or age cases
            if firstRun && ~handles.plot_button_fitness.Value
                legendInput = {};
                for i = range
                    if obj.parameterManager.numLoci > 1 && obj.parameterManager.mutating
                        legendInput = [legendInput sprintf('Type %s', dec2bin(i - 1, log2(obj.gridManager.numTypes)))];
                    else
                        legendInput = [legendInput sprintf('Type %d', i)];
                    end
                end
                legend(legendInput, 'Location', 'northwest')
            end
        end
        
        
        function run(obj, handles, runOnce)
            %This function executes the simulation and is called directly
            %by the run button callback
 
            %If the number of types is greater than 16, turn petri dish off
            if obj.parameterManager.getNumTypes() > 16
                handles.page_button.Enable = 'on';
                obj.parameterManager.setMatrixOn(0);
                handles.matrixOn_button.Value = 0;
            end
            obj.group = 1;
            handles.run_button.String = 'Calculating...';
            obj.evolving = 1;
            obj.toggleVisible(handles)
            %Turn off the boxes on the screens and recolor the buttons
            obj.enableInputs(handles, 0);
            obj.enableButtons(handles, 0);
            handles.run_button.String = 'Pause';
            handles.run_button.BackgroundColor = [1 0 0];
            handles.save_button.BackgroundColor = [.25 .25 .25];
            handles.reset_button.BackgroundColor = [.25 .25 .25];
            handles.step_button.BackgroundColor = [.25 .25 .25];
            drawnow;
            %make the obj.gridManager and run the simulation
            obj.initializeGridManager(handles);
            obj.runLoop(1, handles, runOnce);
            %when the simulation terminates
            obj.evolving = 0;
            %if the termination is not a pause
            if ~obj.paused
                obj.cleanup(handles)
            end
        end

        function continueRunning(obj, handles)
            %Break the pause and continue running the simulation. This
            %function is called by the run button callback from the
            %continue state
            obj.evolving = 1;
            obj.paused = 0;
            obj.enableInputs(handles, 0);
            obj.enableButtons(handles, 0)
            handles.run_button.String = 'Pause';
            handles.run_button.BackgroundColor = [1 0 0];
            handles.save_button.BackgroundColor = [.25 .25 .25];
            handles.reset_button.BackgroundColor = [.25 .25 .25];
            handles.step_button.BackgroundColor = [.25 .25 .25];
            drawnow;
            obj.runLoop(0, handles, 0);
            obj.evolving = 0;
            if ~obj.paused
                obj.cleanup(handles)
            end
        end

        function pauseRunning(obj, handles)
            %Pause the simulation. 
            obj.evolving = 0;
            obj.paused = 1;
            obj.enableInputs(handles, 0);
            obj.enableButtons(handles, 1);
            handles.run_button.String = 'Continue';
            handles.run_button.BackgroundColor = [0 1 0];
            handles.step_button.BackgroundColor = [0 0 1];
            handles.save_button.BackgroundColor = [0 1 1];
            handles.reset_button.BackgroundColor = [1 0 0];
            drawnow;
        end

        function initializeGridManager(obj, handles)
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
            cla(handles.axes_grid);
            cla(handles.axes_graph);
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

