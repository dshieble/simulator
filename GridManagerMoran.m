classdef GridManagerMoran < GridManagerAbstract
%This class is the GridManager implementation for the Moran model

    properties (Constant)
        %The tag properties, these characterize the class itself
        Name = 'Moran'
        Generational = 1;
        Param_1_Name = 'Birth Rate';
        Param_2_Name = '';
        atCapacity = 1;
        plottingEnabled = 1;

    end
    
    properties
    end
    
    methods (Access = public)
        
        function obj = GridManagerMoran(dim, Ninit, mutation_manager, plot_grid, plottingParams, spatial_on, b, n)
            assert(sum(Ninit)==dim.^2);
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, plot_grid, plottingParams, spatial_on, b, n);
        end
        
        %See GridManagerAbstract
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t, h] = get_next(obj)
            %pick a cell at random, kill it, then pick a type in proportion
            %to birth rate and replace killed cell with that type
            gen_vec = obj.total_count(:, obj.timestep);
            for i = 1:numel(obj.matrix)
                tot_rates = gen_vec.*(obj.Param1);
                %choose a type to birth
                num = rand()*sum(tot_rates);
                chosen_type = 0;
                while num > 0
                    chosen_type = chosen_type + 1;
                    num = num - tot_rates(chosen_type);
                end
                gen_vec(chosen_type) = gen_vec(chosen_type) + 1;
                %choose a type to kill
                dead_num = rand()*sum(gen_vec);
                dead_type = 0;
                while dead_num > 0
                    dead_type = dead_type + 1;
                    dead_num = dead_num - gen_vec(dead_type);
                end
                gen_vec(dead_type) = gen_vec(dead_type) - 1;
                %Render the birth and death on the matrix
                if obj.plot_grid
                    %choose a cell of the birthed type, and find the
                    %nearest cell to it of the kill type and fill that cell
                    %with the birthed type
                    if obj.spatial_on
                        [a, b] = ind2sub(size(obj.matrix), obj.getRandomOfType(chosen_type));
                        obj.matrix(obj.get_nearest_of_type(a, b, dead_type)) = chosen_type;
                    else
                        obj.matrix(obj.get_of_type(dead_type)) = chosen_type;
                    end
                end
            end
            obj.total_count(:, obj.timestep + 1) = gen_vec;
            [mat, changed, t, h] = obj.get_next_cleanup();
        end
        

    end
  

end