classdef GridManagerExp < GridManagerAbstract
%This class is an implementation of the GridManager class for the
%Exponential model
    properties (Constant)
        %The tag properties, these characterize the class itself
        Name = 'Exponential';
        Generational = 1;
        Param_1_Name = 'Birth Rate';
        Param_2_Name = 'Death Rate';
        atCapacity = 0;
        plottingEnabled = 1;
    end
    
    properties
    end
    
    methods (Access = public)
        
        function obj = GridManagerExp(dim, Ninit, mutation_manager, plot_grid, plottingParams, spatial_on, edges_on, b, d)
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, plot_grid, plottingParams, spatial_on, edges_on, b, d);
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
                    if sum(gen_vec) < obj.max_size
                        gen_vec(chosen_type) = gen_vec(chosen_type) + 1;
                        if obj.plot_grid
                            %choose a cell of the chosen type, and fill the
                            %nearest cell to it with the chosen type
                            if obj.spatial_on
                                [a, b] = ind2sub(size(obj.matrix), obj.getRandomOfType(chosen_type));
                                obj.changeMatrix(obj.get_nearest_free(a, b), chosen_type);
                            else
                                obj.changeMatrix(obj.get_free(), chosen_type);   
                            end
                        end
                    end
                else
                    if obj.plot_grid && gen_vec(chosen_type) > 0
                        obj.changeMatrix(obj.getRandomOfType(chosen_type), 0);
                    end
                    gen_vec(chosen_type) = max(0, gen_vec(chosen_type) - 1);
                end
            end
            obj.total_count(:, obj.timestep + 1) = gen_vec;
            %then, include all computation updates
            [mat, changed, t, h] = obj.get_next_cleanup();
        end
        
            
        
        
        %Overriden method to account for fact that fitness is determined by
        %difference between birth and death rates here
        function update_params(obj)
            update_params@GridManagerAbstract(obj);
            for i = 1:obj.num_types
                obj.mean_fitness(i, obj.timestep) = (obj.Param1(i)-obj.Param2(i))*obj.percent_count(i, obj.timestep); 
            end
        end

    end
end


