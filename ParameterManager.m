classdef ParameterManager < handle
    
    properties
        num_types;
        handles;
        logistic;
        moran;
        wright;
    end
    
    methods (Access = public)
        
        function obj = ParameterManager(handles)
            obj.num_types = 2;
            obj.handles = handles;
            obj.logistic = struct();
            obj.moran = struct();
            obj.wright = struct();
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


        
        function updateNumTypes(obj)
            num = str2double(obj.handles.num_types_box.String);
            if ~isnan(num)
                if num <= obj.num_types
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
                elseif num > obj.num_types
                    for i = obj.num_types+1:num
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
                obj.num_types = num;
                obj.handles.types_popup.Value = 1;
                obj.updateBoxes();
            end
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
        
    end
end