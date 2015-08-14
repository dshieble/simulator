
classdef ParameterManager < handle
%This powerhouse of a class stores the parameters for each of the different
%models and updates the display based on these parameters. It serves as an
%interface between the backend and frontend. 

    properties (SetAccess = private)
    	plot_grid;
    end
    
    properties
        
        current_model;
        max_types;
        num_types;
        handles;
        pop_size;
        max_pop_size;
        
        model_parameters;
        classConstants;
        
        mutating;
        mutation_matrix;
        num_loci;
        s;
        e;
        %function variables
        numOnes;
        lociParam1Generational;
        lociParam1NonGenerational;
        max_num_loci;
        recombination;
        recombination_number;
    end
    
    methods (Access = public)
        
        %Constructor method. This method initializes all of the instance
        %variables, particularly the seperate structs that store the
        %parameters for each model.
        function obj = ParameterManager(handles, classConstants)
            obj.classConstants = classConstants;
            obj.current_model = 1;
            obj.set_plot_grid(handles.plot_grid_button.Value);
            %numerical parameters
            obj.pop_size = 2500;
            obj.max_pop_size = 25000;
            obj.max_types = 500;
            obj.num_types = 2;
            
            obj.handles = handles;
            obj.model_parameters = struct(...
                'Ninit_default', repmat({[]},1,length(obj.classConstants)),...
                'Param1_default', repmat({[]},1,length(obj.classConstants)),...
                'Param2_default', repmat({[]},1,length(obj.classConstants)),...
                'Ninit', repmat({[]},1,length(obj.classConstants)));
            for i = 1:length(obj.classConstants)
                if obj.classConstants(i).atCapacity
                    obj.model_parameters(i).Ninit_default = 1250;
                else
                    obj.model_parameters(i).Ninit_default = 1;
                end
                obj.model_parameters(i).Param1_default = 1;
                obj.model_parameters(i).Param2_default = 0.01;
                obj.model_parameters(i).Ninit = repmat(obj.model_parameters(i).Ninit_default,1, 2);
                obj.model_parameters(i).Param1 = repmat(obj.model_parameters(i).Param1_default,1, 2);
                obj.model_parameters(i).Param2 = repmat(obj.model_parameters(i).Param2_default,1, 2);
            end
            %mutations
            obj.mutating = 0;
            obj.mutation_matrix = [0.99 0.01; 0.01 0.99];
            obj.num_loci = 1;
            obj.max_num_loci = 15;
            obj.recombination = 0;
            obj.recombination_number = 0;

            %multiple loci params
            obj.s = -0.5;
            obj.e = 0;
            %function variables
            obj.numOnes = @(x) sum(bitget(x,1:ceil(log2(x))+1)); %number of one bits
            obj.lociParam1Generational = @(num) 1 + obj.s*(obj.numOnes(num - 1)^(1-obj.e));
            obj.lociParam1NonGenerational = @(num) exp(obj.s*(obj.numOnes(num - 1)^(1-obj.e)));
            %cleanup
            obj.updateNumTypes();
        end
        
        %Updates the stored structs to the box values
        function updateStructs(obj)
            type = obj.handles.types_popup.Value;
            %logistic
            ninit_temp = str2double(obj.handles.init_pop_box.String);
            param_1_temp = str2double(obj.handles.param_1_box.String);
            param_2_temp = str2double(obj.handles.param_2_box.String);
            if obj.mutating && obj.num_loci > 1
                if isnumeric(param_1_temp)
                    obj.s = param_1_temp;
                end
                if isnumeric(param_2_temp)
                    obj.e = param_2_temp;
                end
            else
                if isnumeric(ninit_temp)
                    obj.model_parameters(obj.current_model).Ninit(type) = round(ninit_temp);
                end
                if isnumeric(param_1_temp)
                    obj.model_parameters(obj.current_model).Param1(type) = param_1_temp;
                end
                if isnumeric(param_2_temp)
                    obj.model_parameters(obj.current_model).Param2(type) = param_2_temp;
                end
            end
            obj.updateMatrixProperties();
        end
        
        
        %Updates the number of types and then update the boxes to type 1
        function updateNumTypes(obj)
            num = min(obj.max_types, str2double(obj.handles.num_types_box.String));
            if isnumeric(num)
                if num < obj.num_types && num > 0
                    obj.handles.types_popup.String(num+1:end) = [];
                    for model = 1:length(obj.classConstants)
                        obj.model_parameters(model).Ninit(num+1:end) = [];
                        obj.model_parameters(model).Param1(num+1:end) = [];
                        obj.model_parameters(model).Param2(num+1:end) = [];
                    end
                elseif num > obj.num_types && num > 0
                    for i = obj.num_types+1:num
                        obj.handles.types_popup.String{i} = i;
                        for model = 1:length(obj.classConstants)
                            obj.model_parameters(model).Ninit(i) = obj.model_parameters(model).Ninit_default;
                            obj.model_parameters(model).Param1(i) = obj.model_parameters(model).Param1_default;
                            obj.model_parameters(model).Param2(i) = obj.model_parameters(model).Param2_default;
                        end
                    end
                end
                %adjust birth and death rates accordingly
                if num ~= obj.num_types
                    for i = 1:length(obj.classConstants)
                        if obj.classConstants(i).atCapacity
                        	obj.model_parameters(i).Ninit = zeros(1,num);
                            for j = 1:(num-1)
                                obj.model_parameters(i).Ninit(j) = floor(obj.pop_size/num);
                                obj.model_parameters(i).Ninit(j) = floor(obj.pop_size/num);
                            end
                            obj.model_parameters(i).Ninit(num) = obj.pop_size - sum(obj.model_parameters(i).Ninit);
                        end
                    end
                end
                obj.num_types = num;
                obj.handles.types_popup.Value = 1;
                obj.updateBoxes();
            end
            obj.handles.num_types_box.String = num2str(obj.num_types);
            obj.updateMultipleLoci();
        end
        
        %Updates the mutation matrix and the num_loci box
        function updateMultipleLoci(obj) 
            num_l = str2double(obj.handles.loci_box.String);
            if isnumeric(num_l)
                obj.num_loci = max(1,num_l);
            end
            if obj.num_loci == 1
                num_a = obj.num_types;
            else
                num_a = 2;
            end
            %reinitialize mutation matrix
            obj.mutation_matrix = zeros(num_a);
            for i = 1:num_a
                for j = 1:num_a
                    if i == j
                        obj.mutation_matrix(i,j) = 1 - 0.01*(num_a-1);
                    else
                        obj.mutation_matrix(i,j) = 0.01;
                    end
                end
            end  
            obj.handles.num_loci_box.String = num2str(obj.num_loci);

        end
        
        %Updates the boxes to the stored struct values (sister function of
        %updateStructs)
        function updateBoxes(obj)
            type = obj.handles.types_popup.Value;
            if obj.num_loci > 1 && obj.mutating
                obj.handles.num_types_box.String = 2;
                obj.handles.param_1_box.String = obj.s;
                obj.handles.param_2_box.String = obj.e;
                if ~obj.classConstants(obj.current_model).atCapacity
                    obj.handles.init_pop_box.String = 1;
                else
                    obj.handles.init_pop_box.String = obj.pop_size;
                end
                obj.handles.loci_box.String = obj.num_loci;
            else
                obj.handles.num_types_box.String = obj.num_types;
                obj.handles.param_1_box.String = obj.model_parameters(obj.current_model).Param1(type);
                obj.handles.param_2_box.String = obj.model_parameters(obj.current_model).Param2(type);
                obj.handles.init_pop_box.String = obj.model_parameters(obj.current_model).Ninit(type);
            end
                
        end
        
        %Updates the size of the matrix/population based on the input to the
        %population box string
        function noerror = updateMatrixProperties(obj)
            size_temp = str2double(obj.handles.population_box.String);
            noerror = 0;
            changed = 0;
            if isnumeric(size_temp)
                %asserting that if plotting is enabled, the size is less
                %than 2500 and square.
                if (size_temp >= 16) && ...
                    ((~obj.plot_grid && size_temp <= obj.max_pop_size) || (round(sqrt(size_temp))^2 == size_temp && (size_temp <= 2500)))
                    if size_temp ~= obj.pop_size
                        changed = 1;
                    end
                    obj.pop_size = size_temp;
                    noerror = 1;
                end
            end
            if changed
                for i = 1:length(obj.classConstants)
                    if obj.classConstants(i).atCapacity
                        obj.model_parameters(i).Ninit = zeros(1,obj.num_types);
                        for j = 1:(obj.num_types-1)
                            obj.model_parameters(i).Ninit(j) = floor(obj.pop_size/obj.num_types);
                            obj.model_parameters(i).Ninit(j) = floor(obj.pop_size/obj.num_types);
                        end
                        obj.model_parameters(i).Ninit(obj.num_types) = obj.pop_size - sum(obj.model_parameters(i).Ninit);
                    end
                end
            end
            obj.updateBoxes();
        end
       
        
        %Provides an interface for accessing parameters that does not
        %require the user to know whether the num_loci > 1, or what the
        %current model is
        function out = getField(obj, param)
            model = obj.current_model;
            if strcmp(param,'num_types')
                if ~obj.mutating || obj.num_loci == 1
                    out = obj.num_types;
                    return;
                else
                    out = 2^obj.num_loci;
                    return;
                end
            end
            if obj.num_loci > 1 && obj.mutating
                if strcmp(param, 'Ninit')
                    if ~obj.classConstants(model).atCapacity
                        out = [obj.model_parameters(model).Ninit_default zeros(1, 2^obj.num_loci - 1)];
                    else
                    	out = [obj.pop_size zeros(1, 2^obj.num_loci - 1)];
                    end
                elseif strcmp(param, 'Param2')
                	out = repmat(obj.model_parameters(model).Param2_default,1,2^obj.num_loci);
                elseif strcmp(param, 'Param1')
                    out = zeros(1,2^obj.num_loci);
                    for i = 1:2^obj.num_loci
                        if obj.classConstants(model).Generational
                            out(i) = obj.lociParam1Generational(i); 
                        else
                            out(i) = obj.lociParam1NonGenerational(i);
                        end
                    end
                else
                    error('Incorrect input to getField')
                end
            else
                out = getfield(obj.model_parameters(model), param);
            end
        end

        %For the num_loci<1 case, verifies that the sum of the Ninits for 
        % all species is the original populaiton size 
        function out = verifySizeOk(obj)
            out = 1;
            if (obj.num_loci == 1 || ~obj.mutating)
                if obj.classConstants(obj.current_model).atCapacity
                    if sum(obj.model_parameters(obj.current_model).Ninit) ~= obj.pop_size
                        out = 0;
                    end
                else
                    if sum(obj.model_parameters(obj.current_model).Ninit) > obj.pop_size
                        out = 0;
                    end
                end
            end
        end
        
        %Verifies that the input to all boxes is numerical
        function ok = verifyAllBoxesClean(obj)
            ok = ~(isnan(str2double(obj.handles.param_1_box.String)) || ...
               isnan(str2double(obj.handles.param_2_box.String)) || ...
               isnan(str2double(obj.handles.init_pop_box.String)) || ...
               isnan(str2double(obj.handles.num_types_box.String)) || ...
               isnan(str2double(obj.handles.population_box.String)));
               %isnan(str2double(obj.handles.max_iterations_box.String)));
        end

        %returns the current number of types, regardless of whether
        %num_loci > 1 or not
        function out = getNumTypes(obj)
            if obj.mutating && obj.num_loci > 1
                out = 2^obj.num_loci;
            else
                out = obj.num_types;
            end
        end
        
        %sets the plot_grid variable. I might add some interesting logic
        %here...
        function set_plot_grid(obj, input)
            obj.plot_grid = input;
        end
        
        %Updates the maximum number of iterations for the non-plotting case
        %based on the input to the max_iterations box
%         function updateMaxIterations(obj)
%             num = str2double(obj.handles.max_iterations_box.String);
%             if isnumeric(num)
%                 obj.max_iterations = num;
%             else
%                 obj.handles.max_iterations_box.String = obj.max_iterations;
%             end
%         end
        
        
    end
end
