classdef GridManagerAbstract < handle
    properties
        output;
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
    end
    methods (Access = public)
        function obj = GridManagerAbstract(dim, Ninit, mutation_manager, plot_grid)
            obj.matrix = zeros(dim);
            obj.old_matrix = obj.matrix;
            r = randperm(numel(obj.matrix));
            i = 1;
            for type = 1:length(Ninit)
                n = Ninit(type);
                obj.matrix(r(i:n+i-1)) = type;
                i = i + n;
            end
            [x, y] = meshgrid(1:dim,1:dim);
            
            obj.output = obj.matrix(:)';
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
        end
      
         %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t] = get_next_cleanup(obj)
            obj.timestep = obj.timestep + 1;
            obj.matrix = obj.mutation_manager.mutate(obj);
            if ~obj.plot_grid
                changed = (1:numel(obj.matrix))';
            else
                changed = find(obj.old_matrix ~= obj.matrix);
                obj.output = [obj.output; obj.matrix(:)'];
                obj.old_matrix = obj.matrix;
            end
            obj.generations = [obj.generations obj.timestep];
            obj.update_params();
            mat = obj.matrix;
            t = obj.timestep;
        end

                
        function ind = get_free(obj)
            free = find(obj.matrix == 0);
            if isempty(free)
                ind = 0;
            else       
                ind = free(randi(length(free)));
            end
        end

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
        
        function update_params(obj)
        end
            
    end
end