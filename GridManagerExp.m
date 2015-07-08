classdef GridManagerExp < GridManagerAbstract
    
    properties
        birth_rate;
        death_rate;
        use_exp; %if 1, use exponential model instead of logistic
    end
    
    methods (Access = public)
        
        function obj = GridManagerExp(dim, Ninit, mutation_manager, plot_grid, b, d)
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, plot_grid);
            obj.birth_rate = b';
            obj.death_rate = d';
            obj.plot_grid = plot_grid;
            obj.mutation_manager = mutation_manager;
            obj.update_params();
        end
        
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t, h] = get_next(obj)
            if obj.plot_grid 
                %kill
                for i = 1:obj.num_types
                    ind = find(obj.matrix == i);
                    for j = ind'
                        if (rand() < obj.death_rate(i))
                            obj.matrix(j) = 0;
                        end
                    end
                end

                %birth
                new = [];
                for i = 1:obj.num_types
                    ind = find(obj.matrix == i);
                    for j = ind'
                        if rand() < obj.birth_rate(i) && isempty(find(new == j, 1))
                            [a, b] = ind2sub(size(obj.matrix), j);
                            f = obj.get_nearest_free(a, b);
                            if (f > 0)
                                obj.matrix(f) = i;
                                new = [new f];
                            end
                        end
                    end
                end
            else
                gen_vec = obj.total_count(:, obj.timestep);
                for i = 1:numel(obj.matrix)
                    tot_rates = gen_vec.*(obj.birth_rate + obj.death_rate);
                    num = rand()*sum(tot_rates);
                    chosen_type = 0;
                    while num > 0
                        chosen_type = chosen_type + 1;
                        num = num - tot_rates(chosen_type);
                    end
                    if num + obj.birth_rate(chosen_type)*gen_vec(chosen_type) > 0
                        if sum(gen_vec) < numel(obj.matrix)
                            gen_vec(chosen_type) = gen_vec(chosen_type) + 1;
                        end
                    else
                    	gen_vec(chosen_type) = gen_vec(chosen_type) - 1;
                    end
                end
                obj.total_count(:, obj.timestep + 1) = gen_vec;
            end
            %then, include all computation updates
            h = (~sum(obj.total_count(:,obj.timestep)) || sum(obj.total_count(:,obj.timestep)) == numel(obj.matrix));
            [mat, changed, t] = obj.get_next_cleanup();
            h = h && ~obj.mutation_manager.mutating;
        end
        
        function update_params(obj)
            for i = 1:obj.num_types
                if obj.plot_grid
                    obj.total_count(i, obj.timestep) = length(find(obj.matrix == i));
                end
                obj.percent_count(i, obj.timestep) = obj.total_count(i, obj.timestep)./numel(obj.matrix);
                obj.mean_fitness(i, obj.timestep) = (obj.birth_rate(i)-obj.death_rate(i))*obj.percent_count(i, obj.timestep); 
            end
            obj.overall_mean_fitness(obj.timestep) = dot(obj.mean_fitness(:,obj.timestep), obj.total_count(:,obj.timestep));
        end

    end
end

