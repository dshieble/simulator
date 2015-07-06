classdef ParameterManager < handle
    
    properties
        current_model;
        max_iterations;
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
        multiple_loci;
    end
    
    methods (Access = public)
        
        function obj = ParameterManager(handles)
            obj.current_model = 1;
            obj.max_iterations = 10;
            obj.max_types = 16;
            obj.num_types = 2;
            obj.handles = handles;
            obj.logistic = struct();
            obj.exp = struct();
            obj.moran = struct();
            obj.wright = struct();
            obj.matrix = struct();
            %logistic
            obj.logistic.Ninit_default = [5];
            obj.logistic.birth_rate_default = [0.5];
            obj.logistic.death_rate_default = [0.01];
            obj.logistic.Ninit = [obj.logistic.Ninit_default obj.logistic.Ninit_default];
            obj.logistic.birth_rate = [obj.logistic.birth_rate_default obj.logistic.birth_rate_default];
            obj.logistic.death_rate = [obj.logistic.death_rate_default obj.logistic.death_rate_default];
            %exp
            obj.exp.Ninit_default = [5];
            obj.exp.birth_rate_default = [0.5];
            obj.exp.death_rate_default = [0.01];
            obj.exp.Ninit = [obj.exp.Ninit_default obj.exp.Ninit_default];
            obj.exp.birth_rate = [obj.exp.birth_rate_default obj.exp.birth_rate_default];
            obj.exp.death_rate = [obj.exp.death_rate_default obj.exp.death_rate_default];
            %moran
            obj.moran.Ninit_default = [1250];
            obj.moran.birth_rate_default = [0.5];
            obj.moran.Ninit = [obj.moran.Ninit_default obj.moran.Ninit_default];
            obj.moran.birth_rate = [obj.moran.birth_rate_default obj.moran.birth_rate_default];
            %wright
            obj.wright.Ninit_default = [1250];
            obj.wright.fitness_default = [0.5];
            obj.wright.Ninit = [obj.wright.Ninit_default obj.wright.Ninit_default];
            obj.wright.fitness = [obj.wright.fitness_default obj.wright.fitness_default];
            %matrix
            obj.matrix.plotting = 1;
            obj.matrix.edge_size = 50;
            %mutations
            obj.mutating = 0;
            obj.mutation_matrix = [0.99 0.01; 0.01 0.99];
            obj.num_loci = 1;
            %multipl loci params
            obj.multiple_loci = struct();
            obj.multiple_loci.logistic = struct();
            obj.multiple_loci.exp = struct();
            obj.multiple_loci.moran = struct();
            obj.multiple_loci.wright = struct();
            obj.multiple_loci.logistic.Ninit = obj.logistic.Ninit_default;
            obj.multiple_loci.logistic.birth_rate = obj.logistic.birth_rate_default;
            obj.multiple_loci.logistic.death_rate = obj.logistic.death_rate_default;
            obj.multiple_loci.exp.Ninit = obj.logistic.Ninit_default;
            obj.multiple_loci.exp.birth_rate = obj.logistic.birth_rate_default;
            obj.multiple_loci.exp.death_rate = obj.logistic.death_rate_default;
            obj.multiple_loci.moran.Ninit = obj.matrix.edge_size.^2;
            obj.multiple_loci.moran.birth_rate = obj.moran.birth_rate_default;
            obj.multiple_loci.wright.Ninit = obj.matrix.edge_size.^2;
            obj.multiple_loci.wright.fitness = obj.wright.fitness_default;
            obj.updateNumTypes();

        end
        
        %Updates the stored structs to the box values
        function updateStructs(obj)
            type = obj.handles.types_popup.Value;
            %logistic
            ninit_temp = str2double(obj.handles.init_pop_box.String);
            param_1_temp = str2double(obj.handles.param_1_box.String);
            param_2_temp = str2double(obj.handles.param_2_box.String);
            if obj.current_model == 1
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
                    obj.moran.Ninit(num+1:end) = [];
                    %wright
                    obj.wright.fitness(num+1:end) = [];
                    obj.wright.Ninit(num+1:end) = [];
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
                        obj.moran.Ninit(i) = obj.moran.Ninit_default;
                        %wright
                        obj.wright.fitness(i) = obj.wright.fitness_default;
                        obj.wright.Ninit(i) = obj.wright.Ninit_default;
                    end
                end
                obj.num_types = num;
                obj.handles.types_popup.Value = 1;
                obj.updateBoxes();
            end
            obj.handles.num_types_box.String = num2str(obj.num_types);
            obj.updateMultipleLoci();
        end
        
        function updateMultipleLoci(obj) 
            %set the num types in the case of more than 1 loci
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
        
        %Updates the num_loci == 1 boxes to the stored struct values
        function updateBoxes(obj)
            type = obj.handles.types_popup.Value;
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
        
        function noerror = updateMatrixProperties(obj)
            size_temp = str2double(obj.handles.population_box.String);
            noerror = 0;
            if ~isnan(size_temp)
                if round(sqrt(size_temp))^2 == size_temp && size_temp <= 2500 && size_temp >= 16
                    obj.matrix.edge_size = sqrt(size_temp);
                    noerror = 1;
                end
            end
            obj.multiple_loci.moran.Ninit = obj.matrix.edge_size.^2;
            obj.multiple_loci.wright.Ninit = obj.matrix.edge_size.^2;
        end
        
        function updateMaxIterations(obj)
            num = str2double(obj.handles.max_iterations_box.String);
            if ~isnan(num)
                obj.max_iterations = num;
            else
                obj.handles.max_iterations_box.String = obj.max_iterations;
            end
        end
        
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
                    out = [getfield(getfield(obj.multiple_loci,model),'Ninit') zeros(1, 2^obj.num_loci - 1)];
                else
                    out = repmat(getfield(getfield(obj.multiple_loci, model),param), 1, 2^obj.num_loci);
                end
            else
                out = getfield(getfield(obj, model),param);
            end
        end

        function out = verifySizeOk(obj, model)
            out = 1;
            if obj.num_loci == 1 || ~obj.mutating
                if sum(getfield(getfield(obj, model), 'Ninit')) ~= (obj.matrix.edge_size^2)
                    out = 0;
                end
            end
        end

    end
end
