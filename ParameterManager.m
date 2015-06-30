classdef ParameterManager < handle
    
    properties
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
    end
    
    methods (Access = public)
        
        function obj = ParameterManager(handles)
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
            obj.updateNumTypes();

        end
        
        function updateStructs(obj)
            type = obj.handles.types_popup.Value;
            %logistic
            Ninit_temp_logistic = str2double(obj.handles.init_pop_box_logistic.String);
            birth_rate_temp_logistic = str2double(obj.handles.birth_rate_box_logistic.String);
            death_rate_temp_logistic = str2double(obj.handles.death_rate_box_logistic.String);
            if ~isnan(Ninit_temp_logistic)
                obj.logistic.Ninit(type) = round(Ninit_temp_logistic);
            end
            if ~isnan(birth_rate_temp_logistic)
                obj.logistic.birth_rate(type) = birth_rate_temp_logistic;
            end
            if ~isnan(death_rate_temp_logistic)
                obj.logistic.death_rate(type) = death_rate_temp_logistic;
            end
            %moran
            Ninit_temp_moran = str2double(obj.handles.init_pop_box_moran.String);
            birth_rate_temp_moran = str2double(obj.handles.birth_rate_box_moran.String);
            if ~isnan(Ninit_temp_moran)
                obj.moran.Ninit(type) = round(Ninit_temp_moran);
            end
            if ~isnan(birth_rate_temp_moran)
                obj.moran.birth_rate(type) = birth_rate_temp_moran;
            end
            %wright
            Ninit_temp_wright = str2double(obj.handles.init_pop_box_wright.String);
            fitness_temp_wright = str2double(obj.handles.fitness_box_wright.String);
            if ~isnan(Ninit_temp_moran)
                obj.wright.Ninit(type) = round(Ninit_temp_wright);
            end
            if ~isnan(birth_rate_temp_moran)
                obj.wright.birth_rate(type) = fitness_temp_wright;
            end
        end
        
        
        %Check that the inputs for num_types and num_loci are valid, and
        %change the other boxes if they are
        
        %make underlying number of types set to the true number of types
        %change defaults to be the defaults provided for the loci>1 case
        %hide the num_types box by a mask that shows num_alles:2
        
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
                    new_Ninit = [obj.matrix.edge_size^2  zeros(1,num - 1)];
                    obj.logistic.Ninit = new_Ninit;
                    obj.logistic.birth_rate = repmat(obj.logistic.birth_rate_default,1,num);
                    obj.logistic.death_rate = repmat(obj.logistic.death_rate_default,1,num);
                    obj.moran.Ninit = new_Ninit;
                    obj.moran.birth_rate = repmat(obj.moran.birth_rate_default,1,num);
                    obj.wright.Ninit = new_Ninit;
                    obj.wright.fitness = repmat(obj.wright.fitness_default,1,num);
                else
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
                        for i = 1:num
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
                end
                obj.num_types = num;
                obj.handles.types_popup.Value = 1;
                obj.updateBoxes();
            end
            obj.handles.num_types_box.String = num2str(obj.num_types);
            obj.handles.num_loci_box.String = num2str(obj.num_loci);
        end
        
        function updateBoxes(obj)
            type = obj.handles.types_popup.Value;
            if obj.handles.logistic_button.Value
                obj.handles.birth_rate_box_logistic.String = obj.logistic.birth_rate(type);
                obj.handles.init_pop_box_logistic.String = obj.logistic.Ninit(type);
                obj.handles.death_rate_box_logistic.String = obj.logistic.death_rate(type);
            elseif obj.handles.moran_button.Value
                obj.handles.birth_rate_box_moran.String = obj.moran.birth_rate(type);
                obj.handles.init_pop_box_moran.String = obj.moran.Ninit(type);
            else
                obj.handles.fitness_box_wright.String = obj.wright.fitness(type);
                obj.handles.init_pop_box_wright.String = obj.wright.Ninit(type);
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
        
        
    end
end