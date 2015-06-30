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
        matrix;
        mutating;
        mutation_matrix;
        num_loci;
        logistic_saved;
        moran_saved;
        wright_saved;
    end
    
    methods (Access = public)
        
        function obj = ParameterManager(handles)
            obj.current_model = 1;
            obj.max_iterations = 10000;
            obj.max_types = 16;
            obj.num_types = 2;
            obj.handles = handles;
            obj.logistic = struct();
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
            %clean
            obj.logistic_saved = obj.logistic;
            obj.moran_saved = obj.moran;
            obj.wright_saved = obj.wright;
            obj.updateNumTypes();

        end
        
        %Updates the stored structs to the box values
        function updateStructs(obj)
            type = obj.handles.types_popup.Value;
            %logistic
            ninit_temp = str2double(obj.handles.init_pop_box.String);
            param_1_temp = str2double(obj.handles.param_1_box.String);
            param_2_temp = str2double(obj.handles.param_2_box.String);
            if obj.current_model <= 2 
                if ~isnan(ninit_temp)
                    obj.logistic.Ninit(type) = round(ninit_temp);
                end
                if ~isnan(param_1_temp)
                    obj.logistic.birth_rate(type) = param_1_temp;
                end
                if ~isnan(param_2_temp)
                    obj.logistic.death_rate(type) = param_2_temp;
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
                    obj.wright.birth_rate(type) = param_1_temp;
                end
            end
        end
        
        
        %Updates the number of types and then update the boxes to type 1
        function updateNumTypes(obj)
            num = min(obj.max_types, str2double(obj.handles.num_types_box.String));
            if ~isnan(num)
                %set the num types in the case of more than 1 loci
                num_l = str2double(obj.handles.loci_box.String);
                if ~isnan(num_l)
                    obj.num_loci = max(1,num_l);
                    if obj.mutating && (obj.num_loci > 1)
                        num = 2^obj.num_loci;
                    end
                end
                if obj.num_loci == 1
                    num_a = num;
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
                %adjust the stored values to be 100% of the all-zeros
                %genotype if in >1 loci case
                if (obj.mutating && (obj.num_loci > 1))
                    %TODO: replace defaults with inputted amounts
                    obj.updateStructs();
                    new_Ninit = [obj.matrix.edge_size^2  zeros(1,num - 1)];
                    obj.logistic.Ninit = [5 zeros(1,num - 1)];
                    obj.moran.Ninit = new_Ninit;
                    obj.wright.Ninit = new_Ninit;
                    obj.logistic.birth_rate = repmat(obj.logistic.birth_rate(1), 1, obj.num_types);
                    obj.logistic.death_rate = repmat(obj.logistic.death_rate(1), 1, obj.num_types);
                    obj.moran.birth_rate = repmat(obj.moran.birth_rate(1), 1, obj.num_types);
                    obj.wright.fitness = repmat(obj.wright.fitness(1), 1, obj.num_types);

                else
                    obj.logistic = obj.logistic_saved;
                    obj.moran = obj.moran_saved;
                    obj.wright = obj.wright_saved;
                    if num < obj.num_types
                        obj.handles.types_popup.String(num+1:end) = [];
                        %logistic
                        obj.logistic.birth_rate(num+1:end) = [];
                        obj.logistic.death_rate(num+1:end) = [];
                        obj.logistic.Ninit(num+1:end) = [];
                        %moran
                        obj.moran.birth_rate(num+1:end) = [];
                        obj.moran.Ninit(num+1:end) = [];
                        %wright
                        obj.wright.fitness(num+1:end) = [];
                        obj.wright.Ninit(num+1:end) = [];
                    elseif num >= obj.num_types
                        for i = obj.num_types:num
                            obj.handles.types_popup.String{i} = i;
                            %logistic 
                            obj.logistic.birth_rate(i) = obj.logistic.birth_rate_default;
                            obj.logistic.death_rate(i) = obj.logistic.death_rate_default;
                            obj.logistic.Ninit(i) = obj.logistic.Ninit_default;
                            %moran
                            obj.moran.birth_rate(i) = obj.moran.birth_rate_default;
                            obj.moran.Ninit(i) = obj.moran.Ninit_default;
                            %wright
                            obj.wright.fitness(i) = obj.wright.fitness_default;
                            obj.wright.Ninit(i) = obj.wright.Ninit_default;
                        end
                    end
                    obj.logistic_saved = obj.logistic;
                    obj.moran_saved = obj.moran;
                    obj.wright_saved = obj.wright;
                end
                obj.num_types = num;
                obj.handles.types_popup.Value = 1;
                obj.updateBoxes();
            end
            obj.handles.num_types_box.String = num2str(obj.num_types);
            obj.handles.num_loci_box.String = num2str(obj.num_loci);
        end
        
        %Updates the boxes to the stored struct values
        function updateBoxes(obj)
            type = obj.handles.types_popup.Value;
            if obj.current_model <= 2
                obj.handles.param_1_box.String = obj.logistic.birth_rate(type);
                obj.handles.param_2_box.String = obj.logistic.death_rate(type);
                obj.handles.init_pop_box.String = obj.logistic.Ninit(type);
            elseif obj.current_model == 3
                obj.handles.param_1_box.String = obj.moran.birth_rate(type);
                obj.handles.init_pop_box.String = obj.moran.Ninit(type);
            else
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
        end
        
        function updateMaxIterations(obj)
            num = str2double(obj.handles.max_iterations_box.String);
            if ~isnan(num)
                obj.max_iterations = num;
            else
                obj.handles.max_iterations_box.String = obj.max_iterations;
            end
        end
        
        
        
    end
end