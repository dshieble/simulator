classdef GridManagerWright < GridManagerAbstract
    
    properties
        proportion_vec;
        fitness;
    end
    
    methods (Access = public)
        
        function obj = GridManagerWright(dim, Ninit, mutation_manager, plot_grid, plottingParams, f)
            assert(sum(Ninit)==dim.^2);
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, plot_grid, plottingParams);
            obj.fitness = f;
            obj.proportion_vec = [];
            obj.plot_grid = plot_grid;
            obj.mutation_manager = mutation_manager;
            obj.update_params();
        end
        
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t, h] = get_next(obj)
            %For each cell, replace it with a multinomially chosen type
            counts = zeros(1,length(obj.fitness));
            for i = 1:obj.num_types
                counts(i) = length(find(obj.matrix == i));
            end
            v = (obj.fitness.*counts);
            probs = v./sum(v);
            new_counts = mnrnd(numel(obj.matrix), probs);
            if obj.plot_grid 
                long_mat = [];
                for i = 1:obj.num_types
                    long_mat = [long_mat repmat(i,1,new_counts(i))];
                end
                long_mat = long_mat(randperm(length(long_mat)));
                obj.matrix = reshape(long_mat, size(obj.matrix,1), size(obj.matrix,2));
                h = obj.isHomogenous();
            else
                obj.total_count(:, obj.timestep + 1) = new_counts;
            	h = length(find(obj.total_count(:, obj.timestep + 1)>=numel(obj.matrix), 1));
            end
            [mat, changed, t] = obj.get_next_cleanup();
            h = h && ~obj.mutation_manager.mutating;
        end
        
        %used tic and toc - this does not need any speed up
        function update_params(obj)
            for i = 1:obj.num_types
                if obj.plot_grid
                    obj.total_count(i, obj.timestep) = length(find(obj.matrix == i));
                end
                obj.percent_count(i, obj.timestep) = obj.total_count(i, obj.timestep)./numel(obj.matrix);
                obj.mean_fitness(i, obj.timestep) = (obj.fitness(i))*obj.percent_count(i, obj.timestep); 
            end
            obj.overall_mean_fitness(obj.timestep) = dot(obj.mean_fitness(:,obj.timestep), obj.total_count(:,obj.timestep));
            obj.proportion_vec = [];
            if min(obj.total_count(:,obj.timestep)) < 100
                multiplier = 100;
            else 
                multiplier = 1;
            end
            for i = 1:obj.num_types
                obj.proportion_vec = [obj.proportion_vec repmat(i,1,round(obj.fitness(i)*multiplier*obj.total_count(i, obj.timestep)))];
            end
            
        end

    end
end