%this class is an implementation of the GridManager class for the
%Exponential model
classdef GridManagerExp < GridManagerAbstract
    
    properties
        birth_rate;
        death_rate;
        use_exp; %if 1, use exponential model instead of logistic
    end
    
    methods (Access = public)
        
        function obj = GridManagerExp(dim, Ninit, mutation_manager, plot_grid, plottingParams, b, d)
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, plot_grid, plottingParams);
            obj.birth_rate = b';
            obj.death_rate = d';
            obj.plot_grid = plot_grid;
            obj.mutation_manager = mutation_manager;
            obj.update_params();
            obj.save_data.birth_rate = b;
            obj.save_data.death_rate = d;
        end
        
        %See GridManagerAbstract
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t, h] = get_next(obj)
            gen_vec = obj.total_count(:, obj.timestep);
            for i = 1:sum(gen_vec)
                if sum(gen_vec) == 0
                    break;
                end
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
                        if obj.plot_grid
                            %choose a cell of the chosen type, and fill the
                            %nearest cell to it with the chosen type
                            [a, b] = ind2sub(size(obj.matrix), obj.getRandomOfType(chosen_type));
                            obj.matrix(obj.get_nearest_free(a, b)) = chosen_type;
                        end
                    end
                else
                    gen_vec(chosen_type) = gen_vec(chosen_type) - 1;
                    if obj.plot_grid
                        obj.matrix(obj.getRandomOfType(chosen_type)) = 0;
                    end
                end
            end
            obj.total_count(:, obj.timestep + 1) = gen_vec;
            %then, include all computation updates
            h = (~sum(obj.total_count(:,obj.timestep)) || sum(obj.total_count(:,obj.timestep)) == numel(obj.matrix));
            [mat, changed, t] = obj.get_next_cleanup();
            h = h && ~obj.mutation_manager.mutating;
        end
        
            
        
        
        %See GridManagerAbstract
        function update_params(obj)
            for i = 1:obj.num_types
                obj.percent_count(i, obj.timestep) = obj.total_count(i, obj.timestep)./numel(obj.matrix);
                obj.mean_fitness(i, obj.timestep) = (obj.birth_rate(i)-obj.death_rate(i))*obj.percent_count(i, obj.timestep); 
            end
            obj.overall_mean_fitness(obj.timestep) = dot(obj.mean_fitness(:,obj.timestep), obj.total_count(:,obj.timestep));
        end

    end
end


