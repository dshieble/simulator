%This powerhouse of a class stores the parameters for each of the different
%models and updates the display based on these parameters. It serves as an
%interface between the backend and frontend. 

classdef ParameterManager < handle
    
    properties
        current_model;
        %max_iterations;
        max_types;
        num_types;
        handles;
        logistic;
        moran;
        wright;
        exp;
        matrix;
        mutating;
        mutation_matrix;
        num_loci;
        s;
        e;
        %function variables
        numOnes;
        lociBR;
        lociFitness;
        max_num_loci;
        recombination;
        recombination_number;
    end
    
    methods (Access = public)
        
        %Constructor method. This method initializes all of the instance
        %variables, particularly the seperate structs that store the
        %parameters for each model.
        function obj = ParameterManager(handles)
            obj.current_model = 1;
            %obj.max_iterations = 10;
            obj.max_types = 500;
            obj.num_types = 2;
            obj.handles = handles;
            obj.logistic = struct();
            obj.exp = struct();
            obj.moran = struct();
            obj.wright = struct();
            obj.matrix = struct();
            %logistic
            obj.logistic.Ninit_default = [5];
            obj.logistic.birth_rate_default = 1;
            obj.logistic.death_rate_default = [0.01];
            obj.logistic.Ninit = [obj.logistic.Ninit_default obj.logistic.Ninit_default];
            obj.logistic.birth_rate = [obj.logistic.birth_rate_default obj.logistic.birth_rate_default];
            obj.logistic.death_rate = [obj.logistic.death_rate_default obj.logistic.death_rate_default];
            %exp
            obj.exp.Ninit_default = [5];
            obj.exp.birth_rate_default = 1;
            obj.exp.death_rate_default = [0.01];
            obj.exp.Ninit = [obj.exp.Ninit_default obj.exp.Ninit_default];
            obj.exp.birth_rate = [obj.exp.birth_rate_default obj.exp.birth_rate_default];
            obj.exp.death_rate = [obj.exp.death_rate_default obj.exp.death_rate_default];
            %moran
            obj.moran.Ninit_default = [1250];
            obj.moran.birth_rate_default = 1;
            obj.moran.Ninit = [obj.moran.Ninit_default obj.moran.Ninit_default];
            obj.moran.birth_rate = [obj.moran.birth_rate_default obj.moran.birth_rate_default];
            %wright
            obj.wright.Ninit_default = [1250];
            obj.wright.fitness_default = 1;
            obj.wright.Ninit = [obj.wright.Ninit_default obj.wright.Ninit_default];
            obj.wright.fitness = [obj.wright.fitness_default obj.wright.fitness_default];
            %matrix
            obj.matrix.plotting = 1;
            obj.matrix.edge_size = 50;
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
            obj.lociBR = @(num) 1 + obj.s*(obj.numOnes(num - 1)^(1-obj.e));
            obj.lociFitness = @(num) exp(obj.s*(obj.numOnes(num - 1)^(1-obj.e)));
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
                if ~isnan(param_1_temp)
                    obj.s = param_1_temp;
                end
                if ~isnan(param_2_temp)
                    obj.e = param_2_temp;
                end
            elseif obj.current_model == 1
                if ~isnan(ninit_temp)
                    obj.logistic.Ninit(type) = round(ninit_temp);
                end
                if ~isnan(param_1_temp)
                    obj.logistic.birth_rate(type) = param_1_temp;
                end
                if ~isnan(param_2_temp)
                    obj.logistic.death_rate(type) = param_2_temp;
                end
            elseif obj.current_model == 2
                if ~isnan(ninit_temp)
                    obj.exp.Ninit(type) = round(ninit_temp);
                end
                if ~isnan(param_1_temp)
                    obj.exp.birth_rate(type) = param_1_temp;
                end
                if ~isnan(param_2_temp)
                    obj.exp.death_rate(type) = param_2_temp;
                end
            %moran
            elseif obj.current_model == 3         
                if ~isnan(ninit_temp)
                    obj.moran.Ninit(type) = round(ninit_temp);
                end
                if ~isnan(param_1_temp)
                    obj.moran.birth_rate(type) = param_1_temp;
                end
            elseif obj.current_model == 4       
                %wright
                if ~isnan(ninit_temp)
                    obj.wright.Ninit(type) = round(ninit_temp);
                end
                if ~isnan(param_1_temp)
                    obj.wright.fitness(type) = param_1_temp;
                end
            end
            obj.updateMatrixProperties();
        end
        
        
        %Updates the number of types and then update the boxes to type 1
        function updateNumTypes(obj)
            num = min(obj.max_types, str2double(obj.handles.num_types_box.String));
            if ~isnan(num)
                if num < obj.num_types
                    obj.handles.types_popup.String(num+1:end) = [];
                    %logistic
                    obj.logistic.birth_rate(num+1:end) = [];
                    obj.logistic.death_rate(num+1:end) = [];
                    obj.logistic.Ninit(num+1:end) = [];
                    %exp
                    obj.exp.birth_rate(num+1:end) = [];
                    obj.exp.death_rate(num+1:end) = [];
                    obj.exp.Ninit(num+1:end) = [];        
                    %moran
                    obj.moran.birth_rate(num+1:end) = [];
                    %wright
                    obj.wright.fitness(num+1:end) = [];
                elseif num > obj.num_types
                    for i = obj.num_types+1:num
                        obj.handles.types_popup.String{i} = i;
                        %logistic
                        obj.logistic.birth_rate(i) = obj.logistic.birth_rate_default;
                        obj.logistic.death_rate(i) = obj.logistic.death_rate_default;
                        obj.logistic.Ninit(i) = obj.logistic.Ninit_default;
                        %exp
                        obj.exp.birth_rate(i) = obj.logistic.birth_rate_default;
                        obj.exp.death_rate(i) = obj.logistic.death_rate_default;
                        obj.exp.Ninit(i) = obj.logistic.Ninit_default;             
                        %moran
                        obj.moran.birth_rate(i) = obj.moran.birth_rate_default;
                        %wright
                        obj.wright.fitness(i) = obj.wright.fitness_default;
                    end
                end
                %adjust birth and death rates accordingly
                if num ~= obj.num_types
                    tot = obj.matrix.edge_size.^2;
                    obj.moran.Ninit = zeros(1,num);
                    obj.wright.Ninit = zeros(1,num);
                    for i = 1:(num-1)
                        obj.moran.Ninit(i) = floor(tot/num);
                        obj.wright.Ninit(i) = floor(tot/num);
                    end
                    obj.moran.Ninit(num) = tot - sum(obj.moran.Ninit);
                    obj.wright.Ninit(num) = tot - sum(obj.wright.Ninit);
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
            if ~isnan(num_l)
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
                type = 1;
                obj.handles.num_types_box.String = 2;
                obj.handles.param_1_box.String = obj.s;
                obj.handles.param_2_box.String = obj.e;
                if obj.current_model <= 2
                    obj.handles.init_pop_box.String = 5;
                else
                    obj.handles.init_pop_box.String = obj.matrix.edge_size^2;
                end
                obj.handles.loci_box.String = obj.num_loci;
                
            else
                type = obj.handles.types_popup.Value;
                obj.handles.num_types_box.String = obj.num_types;
                if obj.current_model == 1
                    obj.handles.param_1_box.String = obj.logistic.birth_rate(type);
                    obj.handles.param_2_box.String = obj.logistic.death_rate(type);
                    obj.handles.init_pop_box.String = obj.logistic.Ninit(type);
                elseif obj.current_model == 2
                    obj.handles.param_1_box.String = obj.exp.birth_rate(type);
                    obj.handles.param_2_box.String = obj.exp.death_rate(type);
                    obj.handles.init_pop_box.String = obj.exp.Ninit(type);
                elseif obj.current_model == 3
                    obj.handles.param_1_box.String = obj.moran.birth_rate(type);
                    obj.handles.init_pop_box.String = obj.moran.Ninit(type);
                elseif obj.current_model == 4
                    obj.handles.param_1_box.String = obj.wright.fitness(type);
                    obj.handles.init_pop_box.String = obj.wright.Ninit(type);
                end
            end
                
        end
        
        %Updates the size of the matrix/population based on the input to the
        %population box string
        function noerror = updateMatrixProperties(obj)
            size_temp = str2double(obj.handles.population_box.String);
            noerror = 0;
            changed = 0;
            if ~isnan(size_temp)
                if round(sqrt(size_temp))^2 == size_temp && (size_temp <= 2500) && (size_temp >= 16)
                    if sqrt(size_temp) ~= obj.matrix.edge_size
                        changed = 1;
                    end
                    obj.matrix.edge_size = sqrt(size_temp);
                    noerror = 1;
                end
            end
            if changed
                tot = obj.matrix.edge_size.^2;
                obj.moran.Ninit = zeros(1,obj.num_types);
                obj.wright.Ninit = zeros(1,obj.num_types);
                for i = 1:(obj.num_types-1)
                    obj.moran.Ninit(i) = floor(tot/obj.num_types);
                    obj.wright.Ninit(i) = floor(tot/obj.num_types);
                end
                obj.moran.Ninit(obj.num_types) = tot - sum(obj.moran.Ninit);
                obj.wright.Ninit(obj.num_types) = tot - sum(obj.wright.Ninit);
            end
            obj.updateBoxes();
        end
        
        %Updates the maximum number of iterations for the non-plotting case
        %based on the input to the max_iterations box
%         function updateMaxIterations(obj)
%             num = str2double(obj.handles.max_iterations_box.String);
%             if ~isnan(num)
%                 obj.max_iterations = num;
%             else
%                 obj.handles.max_iterations_box.String = obj.max_iterations;
%             end
%         end
        
        %Provides an interface for accessing parameters that does not
        %require the user to know whether the num_loci > 1
        function out = getField(obj, model, param)
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
                    if obj.current_model <= 2
                        out = [5 zeros(1, 2^obj.num_loci - 1)];
                    else
                    	out = [obj.matrix.edge_size^2 zeros(1, 2^obj.num_loci - 1)];
                    end
                else
                    if strcmp(param, 'death_rate')
                        out = repmat(obj.logistic.death_rate_default,1,2^obj.num_loci);
                    else
                        out = zeros(1,2^obj.num_loci);
                        for i = 1:2^obj.num_loci
                            if obj.current_model <= 3
                                out(i) = obj.lociBR(i); 
                            else
                                out(i) = obj.lociFitness(i);
                            end
                        end
                    end
                end
            else
                out = getfield(getfield(obj, model),param);
            end
        end

        %For the num_loci<1 case, verifies that the sum of the Ninits for 
        % all species is the original populaiton size 
        function out = verifySizeOk(obj)
            out = 1;
            if (obj.num_loci == 1 || ~obj.mutating)
                if obj.current_model == 1
                    if sum(obj.logistic.Ninit) > (obj.matrix.edge_size^2)
                        out = 0;
                    end
                elseif obj.current_model == 2
                    if sum(obj.exp.Ninit) > (obj.matrix.edge_size^2)
                        out = 0;
                    end
                elseif obj.current_model == 3
                    if sum(obj.moran.Ninit) ~= (obj.matrix.edge_size^2)
                        out = 0;
                    end
                elseif obj.current_model == 4
                    if sum(obj.wright.Ninit) ~= (obj.matrix.edge_size^2)
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
        
        %Returns the name of the current model
        function out = getModelName(obj)
            names = {'Logistic', 'Exponential', 'Moran', 'Wright-Fisher'};
            out = names{obj.current_model};
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
        
    end
end
