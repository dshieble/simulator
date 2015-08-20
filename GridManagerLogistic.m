classdef GridManagerLogistic < GridManagerAbstract
%This class is an implementation of the GridManager class for the Logistic
%model
    
    properties (Constant)
        %The tag properties, these characterize the class itself
        Name = 'Logistic';
        Generational = 1;
        Param_1_Name = 'Birth Rate';
        Param_2_Name = 'Death Rate';
        atCapacity = 0;
        plottingEnabled = 1;
    end
    
    properties
    end
    
    methods (Access = public)
        
        function obj = GridManagerLogistic(dim, Ninit, mutation_manager, plot_grid, plottingParams, spatial_on, edges_on, b, d)
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, plot_grid, plottingParams, spatial_on, edges_on, b, d);
        end
        
        %See GridManagerAbstract'
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t, h] = get_next(obj)
            gen_vec = obj.total_count(:, obj.timestep);
            for i = 1:sum(gen_vec)
                if sum(gen_vec) <= 0
                    break;
                end
                tot_rates = gen_vec.*(obj.Param1 + obj.Param2);
                if min(tot_rates) < 0
                    tot_rates = tot_rates + abs(min(tot_rates));
                end
                num = rand()*sum(tot_rates);
                chosen_type = 0;
                while num > 0
                    chosen_type = chosen_type + 1;
                    num = num - tot_rates(chosen_type);
                end

                if num + obj.Param1(chosen_type)*gen_vec(chosen_type) > 0
                    if rand() <= 1-(sum(gen_vec)/obj.max_size)
                        if sum(gen_vec) < obj.max_size
                            if obj.plot_grid
                                %choose a cell of the chosen type, and fill the
                                %nearest cell to it with the chosen type
                                if obj.spatial_on
                                    [a, b] = ind2sub(size(obj.matrix), obj.getRandomOfType(chosen_type));
                                    obj.matrix(obj.get_nearest_free(a, b)) = chosen_type;
                                else
                                	obj.matrix(obj.get_free()) = chosen_type;
                                end
                            end
                            gen_vec(chosen_type) = gen_vec(chosen_type) + 1;
                        end
                    end
                else
                    if obj.plot_grid && gen_vec(chosen_type) > 0
                        obj.matrix(obj.getRandomOfType(chosen_type)) = 0;
                    end
                    gen_vec(chosen_type) = max(0, gen_vec(chosen_type) - 1);
                end
            end
            %then, include all computation updates
            obj.total_count(:, obj.timestep + 1) = gen_vec;
            [mat, changed, t, h] = obj.get_next_cleanup();
        end
        
        %Overriden method to account for fact that fitness is determined by
        %difference between birth and death rates here
        function update_params(obj)
            for i = 1:obj.num_types
                obj.percent_count(i, obj.timestep) = obj.total_count(i, obj.timestep)./obj.max_size;
                obj.mean_fitness(i, obj.timestep) = (obj.Param1(i)-obj.Param2(i))*obj.percent_count(i, obj.timestep); 
            end
            obj.overall_mean_fitness(obj.timestep) = dot(obj.mean_fitness(:,obj.timestep), obj.total_count(:,obj.timestep));
            if obj.Generational
                obj.age_structure{obj.timestep} = hist(obj.age_matrix(:), max(obj.age_matrix(:)))./obj.max_size;
            end
        end

    end
end