classdef (Abstract) GridManagerAbstract < handle
%This class is the parent class of the 4 grid managers. It contains methods
%that are used by all of its child classes, as well as the instance
%variables used across all classes. 

%The GridManager class stores the matrix/counts of each species, and
%contains a method get_next that advances the matrix/counts to the next
%generation, based on the model that the GridManager's implementation is based
%on
   
    
    properties
        save_data;
        matrix;
        timestep;
        num_types;
        total_count; %num types x timestep matrix
        percent_count;
        colors;
        mean_fitness;
        overall_mean_fitness;
        plot_grid;
        generations;
        old_matrix;
        mutation_manager; 
        plottingParams;
        spatial_on;
        Param1;
        Param2;
    end
    methods (Access = public)
        %The constructor method. This function initializes the matrix and
        %the plotting parameters, as well as other useful variables like
        %the color variable. The final 2 inputs are the Param1 and the
        %Param2 inputs
        function obj = GridManagerAbstract(dim, Ninit, mutation_manager, plot_grid, plottingParams, spatial_on, p1, p2)
            obj.Param1 = p1';
            obj.Param2 = p2';
            obj.matrix = zeros(dim);
            obj.old_matrix = obj.matrix;
            if (sum(Ninit) == numel(obj.matrix)) || ~spatial_on
                r = randperm(numel(obj.matrix));
                i = 1;
                for type = 1:length(Ninit)
                    n = Ninit(type);
                    obj.matrix(r(i:n+i-1)) = type;
                    i = i + n;
                end
            else
                for type = 1:length(Ninit)
                    ind = obj.get_free();
                    obj.matrix(ind) = type;
                    for j = 2:length(Ninit(type))
                        obj.matrix(obj.get_nearest_free(ind)) = type;
                    end
                end
            end
            
            
            obj.timestep = 1;
            
            obj.num_types = length(Ninit);
            %when there are more than 10 types, colors become randomized
            obj.colors = [1 0 0; ...
                0 1 0; ...
                0 0 1; ...
                1 1 0; ...
                1 0 1;...
                0 1 1; ...
                1 0.5 0.5; ...
                0.5 1 0.5; ...
                1 0.5 0.5;...
                0.5 0.5 0.5; ...
                0.25 0.25 1; ...
                1 .25 .25;...
                .25 1 .25;
                .5 .25 0; ...
                .25 0 .5; ...
                0 .25 .5; ...
                .15 .15 .15;];
            obj.total_count = Ninit';
            obj.percent_count = [];
            obj.mean_fitness = [];
            obj.overall_mean_fitness = [];
            obj.generations = [1];
            obj.plot_grid = plot_grid;
            obj.mutation_manager = mutation_manager;
            obj.plottingParams = plottingParams;
            obj.spatial_on = spatial_on;
            obj.save_data = struct('Param1', p1, 'Param2', p2);
            obj.update_params();
        end
      
        %This function is called at the end of get_next by all of the child
        %classes. It instantiates the output variables and increments the
        %timestep. 
        %
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        function [mat, changed, t, h] = get_next_cleanup(obj)
            obj.timestep = obj.timestep + 1;
            obj.mutation_manager.mutate(obj);
            obj.mutation_manager.generational_recombination(obj);
            if ~obj.plot_grid
                changed = (1:numel(obj.matrix))';
            else
                changed = find(obj.old_matrix ~= obj.matrix);
                obj.old_matrix = obj.matrix;
            end
            obj.generations = [obj.generations obj.timestep];
            obj.update_params();
            obj.save_data.total_count = obj.total_count;
            mat = obj.matrix;
            t = obj.timestep;
            h = max(obj.total_count(:, obj.timestep))>=numel(obj.matrix);
            h = h && ~obj.mutation_manager.mutating;
        end

        %Returns a square in the matrix of type t
        function ind = get_of_type(obj, t)
            typed = find(obj.matrix == t);
            if isempty(typed)
                ind = randi(numel(obj.matrix));
            else       
                ind = typed(randi(length(typed)));
            end
        end
        
        %Returns a free square in the matrix
        function ind = get_free(obj)
            free = find(obj.matrix == 0);
            if isempty(free)
                ind = randi(numel(obj.matrix));
            else       
                ind = free(randi(length(free)));
            end
        end

        %Returns the nearest square in the matrix of type t
        function ind = get_nearest_of_type(obj, i, j, t)
            ofType = find(obj.matrix == t);
            [x, y] = ind2sub(size(obj.matrix, 1), ofType);
            m = inf;
            a = 0; b = 0;
            for k = 1:length(x)
                d = abs(x(k)-i) + abs(y(k) - j);
                if d < m
                    m = d;
                    a = x(k);
                    b = y(k);
                end
            end 
            if a == 0 || b == 0
                ind = 0;
            else
                ind = sub2ind(size(obj.matrix),a,b);
            end
            assert(obj.matrix(ind) == t);
        end
        
        %Returns the nearest free square in the matrix
        function ind = get_nearest_free(obj, i, j)
            free = find(obj.matrix == 0);
            [x, y] = ind2sub(size(obj.matrix, 1), free);
            m = inf;
            a = 0; b = 0;
            for k = 1:length(x)
                d = abs(x(k)-i) + abs(y(k) - j);
                if d < m
                    m = d;
                    a = x(k);
                    b = y(k);
                end
            end 
            if a == 0 || b == 0
                ind = 0;
            else
                ind = sub2ind(size(obj.matrix),a,b);
            end
        end

        %Gets the ith color from the color matrix
        function c = get_color(obj,i)
            c = obj.colors(i,:);
        end

        %returns 1 if there is only one species
        function h = isHomogenous(obj)
            found = 0;
            h = 1;
            for i = 1:size(obj.matrix, 1)
                if ~isempty(find(obj.matrix == i, 1))
                    found = found + 1;
                end
                if found >= 2 
                    h = 0;
                    break;
                end
            end
        end
        
        %Returns a random cell of the chosen type
        function out = getRandomOfType(obj, type)
            ofType = find(obj.matrix == type);
            out = ofType(randi(numel(ofType)));
        end
            
        %Updates the total_count, the percent_count and the mean_fitness
        %variables for plotting. 
        function update_params(obj)
            for i = 1:obj.num_types
                obj.percent_count(i, obj.timestep) = obj.total_count(i, obj.timestep)./numel(obj.matrix);
                obj.mean_fitness(i, obj.timestep) = (obj.Param1(i))*obj.percent_count(i, obj.timestep); 
            end
            obj.overall_mean_fitness(obj.timestep) = dot(obj.mean_fitness(:,obj.timestep), obj.total_count(:,obj.timestep));
        end
        
        
    end
    
    methods (Abstract)        
        %A method implemented by all of the child GridManager class.
        %This method updates obj.total_count for the new timestep, and, if
        %plot_grid is enabled, also updates the GridManager's petri dish
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        [mat, changed, t, h] = get_next(obj)
    end
    
    
end