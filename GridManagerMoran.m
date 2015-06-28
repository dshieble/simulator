classdef GridManagerMoran < GridManagerAbstract
    
    properties
        proportion_vec;
        birth_rate;
    end
    
    methods (Access = public)
        
        function obj = GridManagerMoran(dim, Ninit, b, plot_grid)
            assert(sum(Ninit)==dim.^2);
            obj@GridManagerAbstract(dim, Ninit);
            obj.birth_rate = b';
            obj.proportion_vec = [];
            obj.plot_grid = plot_grid;
            obj.update_params();
        end
        
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t, h] = get_next(obj)
            %pick a cell at random, kill it, then pick a type in proportion
            %to birth rate and replace killed cell with that type
            if obj.plot_grid
                n = size(obj.matrix, 1);
                c = randi(n,1,2);
                changed = sub2ind(size(obj.matrix),c(1),c(2));
                index = randi(length(obj.proportion_vec));
                obj.matrix(changed) = obj.proportion_vec(index);
                %then, include all computation updates
                obj.output = [obj.output; obj.matrix(:)'];
                mat = obj.matrix;
                h = obj.isHomogenous();
                if obj.timestep <= 2 || ~obj.plot_grid
                    changed = (1:numel(obj.matrix))';
                end
            else
                obj.total_count(:, obj.timestep + 1) = obj.total_count(:, obj.timestep);
                changed = (1:numel(obj.matrix))';
                mat = [];
                tot_rates = obj.total_count(:,obj.timestep + 1).*(obj.birth_rate);
                num = rand()*sum(tot_rates);
                chosen_type = 0;
                while num > 0
                    chosen_type = chosen_type + 1;
                    num = num - tot_rates(chosen_type);
                end
                dead_type = randi([1 obj.num_types]);
                %birth one
                obj.total_count(chosen_type, obj.timestep + 1) = obj.total_count(chosen_type, obj.timestep + 1) + 1;
                %kill one
                obj.total_count(dead_type, obj.timestep + 1)    = obj.total_count(dead_type  , obj.timestep + 1) - 1;
                h = length(find(obj.total_count(:, obj.timestep + 1)>=numel(obj.matrix), 1));
                %obj.total_count(:, obj.timestep + 1)
            end
            obj.timestep = obj.timestep + 1;
            t = obj.timestep; 
            obj.generations = [obj.generations obj.generations(end) + (1/numel(obj.matrix))];
            obj.update_params();
        end
        
        %used tic and toc - this does not need any speed up
        function update_params(obj)
            for i = 1:obj.num_types
                if obj.plot_grid
                    obj.total_count(i, obj.timestep) = length(find(obj.matrix == i));
                end
                obj.percent_count(i, obj.timestep) = obj.total_count(i, obj.timestep)./numel(obj.matrix);
                obj.mean_fitness(i, obj.timestep) = (obj.birth_rate(i))*obj.percent_count(i, obj.timestep); 
            end
            obj.overall_mean_fitness(obj.timestep) = dot(obj.mean_fitness(:,obj.timestep), obj.total_count(:,obj.timestep));
            obj.proportion_vec = [];
            if min(obj.total_count(:,obj.timestep)) < 100
                multiplier = 100;
            else 
                multiplier = 1;
            end
            for i = 1:obj.num_types
                obj.proportion_vec = [obj.proportion_vec repmat(i,1,round(obj.birth_rate(i)*multiplier*obj.total_count(i, obj.timestep)))];
            end
        end

    end
end