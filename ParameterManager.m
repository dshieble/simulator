classdef ParameterManager < handle
%This powerhouse of a class stores the parameters for each of the different
%models and updates the display based on these parameters. It serves as an
%interface between the backend and frontend. 

    properties (Constant)
        maxTypes = 500; %The maximum possible number of different types 
        maxPopSize = 25000; %The maximum possible total population size (petri dish off)
        maxPlottingPopSize = 2500; %The maximum possible total population size (petri dish on)
        maxNumLoci = 15; %Maximum possible number of loci
    end

    properties (SetAccess = private)
    	matrixOn; %Determines whether the matrix model or vector model is used
        initialFrequencies; %Frequency of each genotype at inception
        handles; %Struct that stores pointers to the graphics objects
        classConstants; %Struct that stores the Constant properties of the currently used GridManager classes
        popSize; %The current total population size
        modelParameters; %The current parameters (Ninit, birth_rate, death_rate, fitness) of each type in each model
        numTypes; %The number of different types in the current model. NOT UPDATED BASED ON numLoci

        %Mutation 
        mutating; %Whether or not mutation is currently enabled.
        mutationMatrix; %The matrix that stores the current mutation transition probabilities
        recombining; %Whether or not recombination is enabled 
        recombinationNumber; %The recombination probability.
        
        %Multiple Loci
        s; %A parameter for determining the type parameters in the numLoci > 1 case
        numLoci; %The number of loci in each genotype
        e; %A parameter for determining the type parameters in the numLoci > 1 case
        
        %Non-Mutation Basic Parameters
        spatialOn; %Determines whether the spatial structure is considered.
        edgesOn; %Determines whether the edges are considered when searching for the closest square of a type. 
        currentModel; %The number of the current model

    end
    
    methods (Access = public)
        
        %Constructor method. This method initializes all of the instance
        %variables, particularly the seperate structs that store the
        %parameters for each model.
        function obj = ParameterManager(handles, classConstants)
            obj.classConstants = classConstants;
            obj.currentModel = 1;
            obj.setMatrixOn(handles.matrixOn_button.Value);
            obj.spatialOn = 1;
            obj.edgesOn = 1;
            %numerical parameters
            obj.popSize = 2500;
            obj.numTypes = 2;
            
            obj.handles = handles;
            obj.modelParameters = struct(...
                'Ninit_default', repmat({[]},1,length(obj.classConstants)),...
                'Param1_default', repmat({[]},1,length(obj.classConstants)),...
                'Param2_default', repmat({[]},1,length(obj.classConstants)),...
                'Ninit', repmat({[]},1,length(obj.classConstants)));
            for i = 1:length(obj.classConstants)
                if obj.classConstants(i).atCapacity
                    obj.modelParameters(i).Ninit_default = 1250;
                else
                    obj.modelParameters(i).Ninit_default = 1;
                end
                obj.modelParameters(i).Param1_default = 1;
                obj.modelParameters(i).Param2_default = 0.01;
                obj.modelParameters(i).Ninit = repmat(obj.modelParameters(i).Ninit_default,1, 2);
                obj.modelParameters(i).Param1 = repmat(obj.modelParameters(i).Param1_default,1, 2);
                obj.modelParameters(i).Param2 = repmat(obj.modelParameters(i).Param2_default,1, 2);
            end
            %mutations
            obj.mutating = 0;
            obj.mutationMatrix = [0.99 0.01; 0.01 0.99];
            obj.initialFrequencies = [1 0];
            obj.numLoci = 1;
            obj.recombining = 0;
            obj.recombinationNumber = 1;

            %multiple loci params
            obj.s = -0.5;
            obj.e = 0;

            %cleanup
            obj.updateNumTypes();
        end
        

        function updateBasicParameters(obj)
            %Updates the mutation/recombination and basic parameters to the
            %input values
            obj.mutating = obj.handles.genetics_button.Value;
            obj.recombining = obj.handles.recombination_check.Value;
            obj.spatialOn = obj.handles.spatial_structure_check.Value;
            obj.edgesOn = ~obj.handles.remove_edges_check.Value;
            obj.recombinationNumber = obj.handles.recombination_box.Value;

            %current model
            if obj.handles.model1_button.Value
                obj.currentModel = 1;
            elseif obj.handles.model2_button.Value
            	obj.currentModel = 2;
            elseif obj.handles.model3_button.Value
            	obj.currentModel = 3;
            elseif obj.handles.model4_button.Value
                obj.currentModel = 4;
            end
        end
            
        
        function message = updateStructs(obj)
            %Updates the stored parameters to the box values
            message = '';
            type = obj.handles.types_popup.Value;
            %logistic
            ninit_temp = str2double(obj.handles.init_pop_box.String);
            param_1_temp = str2double(obj.handles.param_1_box.String);
            param_2_temp = str2double(obj.handles.param_2_box.String);
            if param_1_temp < obj.classConstants(obj.currentModel).ParamBounds1(1) || ...
               param_1_temp > obj.classConstants(obj.currentModel).ParamBounds1(2)
                message = sprintf('ERROR: %s must be betwen %d and %d',obj.classConstants(obj.currentModel).ParamName1, obj.classConstants(obj.currentModel).ParamBounds1(1),obj.classConstants(obj.currentModel).ParamBounds1(2));
            elseif param_2_temp < obj.classConstants(obj.currentModel).ParamBounds2(1) || ...
                   param_2_temp > obj.classConstants(obj.currentModel).ParamBounds2(2)
                message = sprintf('ERROR: %s must be betwen %d and %d',obj.classConstants(obj.currentModel).ParamName2, obj.classConstants(obj.currentModel).ParamBounds2(1),obj.classConstants(obj.currentModel).ParamBounds2(2));            
            end
            if obj.mutating && obj.numLoci > 1
                if isnumeric(param_1_temp)
                    obj.s = param_1_temp;
                end
                if isnumeric(param_2_temp)
                    obj.e = param_2_temp;
                end
            else
                if isnumeric(ninit_temp)
                    obj.modelParameters(obj.currentModel).Ninit(type) = round(ninit_temp);
                end
                if isnumeric(param_1_temp) && isempty(message)
                    obj.modelParameters(obj.currentModel).Param1(type) = param_1_temp;
                end
                if isnumeric(param_2_temp) && isempty(message)
                    obj.modelParameters(obj.currentModel).Param2(type) = param_2_temp;
                end
            end
            obj.updateMatrixProperties();
        end
        
        
        function updateNumTypes(obj)
            %Updates the number of types and then update the boxes to type 1
            num = min(obj.maxTypes, str2double(obj.handles.num_types_box.String));
            if isnumeric(num)
                if num < obj.numTypes && num > 0
                    obj.handles.types_popup.String(num+1:end) = [];
                    for model = 1:length(obj.classConstants)
                        obj.modelParameters(model).Ninit(num+1:end) = [];
                        obj.modelParameters(model).Param1(num+1:end) = [];
                        obj.modelParameters(model).Param2(num+1:end) = [];
                    end
                elseif num > obj.numTypes && num > 0
                    for i = obj.numTypes+1:num
                        obj.handles.types_popup.String{i} = i;
                        for model = 1:length(obj.classConstants)
                            obj.modelParameters(model).Ninit(i) = obj.modelParameters(model).Ninit_default;
                            obj.modelParameters(model).Param1(i) = obj.modelParameters(model).Param1_default;
                            obj.modelParameters(model).Param2(i) = obj.modelParameters(model).Param2_default;
                        end
                    end
                end
                %adjust birth and death rates accordingly
                if num ~= obj.numTypes
                    for i = 1:length(obj.classConstants)
                        if obj.classConstants(i).atCapacity
                        	obj.modelParameters(i).Ninit = zeros(1,num);
                            for j = 1:(num-1)
                                obj.modelParameters(i).Ninit(j) = floor(obj.popSize/num);
                                obj.modelParameters(i).Ninit(j) = floor(obj.popSize/num);
                            end
                            obj.modelParameters(i).Ninit(num) = obj.popSize - sum(obj.modelParameters(i).Ninit);
                        end
                    end
                end
                obj.numTypes = num;
                obj.handles.types_popup.Value = 1;
                obj.updateBoxes();
            end
            obj.handles.num_types_box.String = num2str(obj.numTypes);
            obj.updateMultipleLoci();
        end
        

        function message = updateMultipleLoci(obj) 
        	%Updates the numLoci box and resets the default
            %frequencies vector
            message = '';
            numLociTemp = str2double(obj.handles.loci_box.String);
            if isnumeric(numLociTemp) && ~isnan(numLociTemp) && (numLociTemp<=obj.maxNumLoci) &&...
                    (round(numLociTemp) == numLociTemp) && (numLociTemp > 0)
                obj.numLoci = max(1,numLociTemp);
            else
                message = sprintf('Number of Loci must be a positive integer less than %d', obj.maxNumLoci + 1); 
                return;
            end
            if obj.numLoci == 1
                num_a = obj.numTypes;
            else
                num_a = 2;
            end
            %reinitialize mutation matrix
            obj.mutationMatrix = zeros(num_a);
            for i = 1:num_a
                for j = 1:num_a
                    if i == j
                        obj.mutationMatrix(i,j) = 1 - 0.01*(num_a-1);
                    else
                        obj.mutationMatrix(i,j) = 0.01;
                    end
                end
            end  
            obj.handles.numLoci_box.String = num2str(obj.numLoci);
            obj.initialFrequencies = [1 zeros(1,2.^obj.numLoci - 1)];
        end
        

        function updateBoxes(obj)
        	%Updates the boxes to the stored struct values (sister function of
            %updateStructs)
            type = obj.handles.types_popup.Value;
            if obj.numLoci > 1 && obj.mutating
                obj.handles.num_types_box.String = sprintf('%d', 2^obj.numLoci);
                obj.handles.param_1_box.String = obj.s;
                obj.handles.param_2_box.String = obj.e;
                if ~obj.classConstants(obj.currentModel).atCapacity
                    obj.handles.init_pop_box.String = 1;
                else
                    obj.handles.init_pop_box.String = obj.popSize;
                end
                obj.handles.loci_box.String = obj.numLoci;
            else
                obj.handles.num_types_box.String = obj.numTypes;
                obj.handles.param_1_box.String = obj.modelParameters(obj.currentModel).Param1(type);
                obj.handles.param_2_box.String = obj.modelParameters(obj.currentModel).Param2(type);
                obj.handles.init_pop_box.String = obj.modelParameters(obj.currentModel).Ninit(type);
            end
                
        end
        

        function noerror = updateMatrixProperties(obj)
        	%Updates the size of the matrix/population based on the input to the
            %population box string
            size_temp = str2double(obj.handles.population_box.String);
            noerror = 0;
            changed = 0;
            if isnumeric(size_temp)
                %asserting that if plotting is enabled, the size is less
                %than 2500 and square.
                if (size_temp >= 16) && ...
                    ((~obj.matrixOn && size_temp <= obj.maxPopSize) || (round(sqrt(size_temp))^2 == size_temp && (size_temp <= 2500)))
                    if size_temp ~= obj.popSize
                        changed = 1;
                    end
                    obj.popSize = size_temp;
                    noerror = 1;
                end
            end
            if changed
                for i = 1:length(obj.classConstants)
                    if obj.classConstants(i).atCapacity
                        obj.modelParameters(i).Ninit = zeros(1,obj.numTypes);
                        for j = 1:(obj.numTypes-1)
                            obj.modelParameters(i).Ninit(j) = floor(obj.popSize/obj.numTypes);
                            obj.modelParameters(i).Ninit(j) = floor(obj.popSize/obj.numTypes);
                        end
                        obj.modelParameters(i).Ninit(obj.numTypes) = obj.popSize - sum(obj.modelParameters(i).Ninit);
                    end
                end
            end
            obj.updateBoxes();
        end
       
        

        function out = getField(obj, param)
        	%Provides an interface for accessing parameters that does not
            %require the user to know whether the numLoci > 1, or what the
            %current model is
            model = obj.currentModel;
            if strcmp(param,'numTypes')
                if ~obj.mutating || obj.numLoci == 1
                    out = obj.numTypes;
                    return;
                else
                    out = 2^obj.numLoci;
                    return;
                end
            end
            if obj.numLoci > 1 && obj.mutating
                if strcmp(param, 'Ninit')                    
                    if ~obj.classConstants(model).atCapacity
                        out = [obj.modelParameters(model).Ninit_default zeros(1, 2^obj.numLoci - 1)];
                    else
                        tail = floor(obj.popSize.*obj.initialFrequencies(2:end));
                        assert(sum(tail) <= obj.popSize);
                        assert(length(obj.initialFrequencies) == 2^obj.numLoci);
                        out = [obj.popSize - sum(tail) tail]; %some rounding to ensure that sum of types adds to popSize
                    end
                elseif strcmp(param, 'Param2')
                	out = repmat(obj.modelParameters(model).Param2_default,1,2^obj.numLoci);
                elseif strcmp(param, 'Param1')
                    out = zeros(1,2^obj.numLoci);
                    for i = 1:2^obj.numLoci
                        if obj.classConstants(model).OverlappingGenerations
                            out(i) = obj.lociParam1OverlappingGenerations(i); 
                        else
                            out(i) = obj.lociParam1NonOverlappingGenerations(i);
                        end
                    end
                else
                    error('Incorrect input to getField')
                end
            else
                out = getfield(obj.modelParameters(model), param);
            end
        end


        function out = verifySizeOk(obj)
            %For the numLoci<1 case, verifies that the sum of the Ninits for 
            % all species is the original populaiton size 
            out = 1;
            if (obj.numLoci == 1 || ~obj.mutating)
                if obj.classConstants(obj.currentModel).atCapacity
                    if sum(obj.modelParameters(obj.currentModel).Ninit) ~= obj.popSize
                        out = 0;
                    end
                else
                    if sum(obj.modelParameters(obj.currentModel).Ninit) > obj.popSize
                        out = 0;
                    end
                end
            end
        end
        
        function ok = verifyAllBoxesClean(obj)
            %Verifies that the input to all boxes is numerical
            ok = ~(isnan(str2double(obj.handles.param_1_box.String)) || ...
               isnan(str2double(obj.handles.param_2_box.String)) || ...
               isnan(str2double(obj.handles.init_pop_box.String)) || ...
               isnan(str2double(obj.handles.num_types_box.String)) || ...
               isnan(str2double(obj.handles.population_box.String)));
        end


        function out = getNumTypes(obj)
        	%returns the current number of types, regardless of whether
            %numLoci > 1 or not
            if obj.mutating && obj.numLoci > 1
                out = 2^obj.numLoci;
            else
                out = obj.numTypes;
            end
        end
        

        function setMatrixOn(obj, input)
        	%Sets the matrixOn variable. I might add some interesting logic
            %here
            obj.matrixOn = input;
        end
        
        function setMutationMatrix(obj, m)       
            %Sets the mutationMatrix variable.
            obj.mutationMatrix = m;
        end
        
        function setInitialFrequencies(obj, df)
            %sets the initialFrequencies variable.
            obj.initialFrequencies = df;
        end
        
        function out = numOnes(obj,x) 
            %number of one bits in input number x
            out = sum(bitget(x,1:ceil(log2(x))+1));
        end
        

        function out = lociParam1OverlappingGenerations(obj,num) 
        	%A function that computes the first model parameter based on the
            %number of 1s for OverlappingGenerations models (Logistic, Moren,
            %Exp, etc)
            out = 1 + obj.s*(obj.numOnes(num - 1)^(1-obj.e));
        end
        

        function out = lociParam1NonOverlappingGenerations(obj,num)
        	%A function that computes the first model parameter based on the
            %number of 1s for NonOverlappingGenerations models (Wright-Fisher)
            out = exp(obj.s*(obj.numOnes(num - 1)^(1-obj.e)));
        end

        
        
    end
end
