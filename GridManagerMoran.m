%This class is the GridManager implementation for the Moran model
classdef GridManagerMoran < GridManagerAbstract
    
    properties
        proportion_vec;
        birth_rate;
    end
    
    methods (Access = public)
        
        function obj = GridManagerMoran(dim, Ninit, mutation_manager, plot_grid, plottingParams, b)
            assert(sum(Ninit)==dim.^2);
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, plot_grid, plottingParams);
            obj.birth_rate = b';
            obj.proportion_vec = [];
            obj.update_params();
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
            if obj.plot_grid
                for i = 1:numel(obj.matrix)
                    tot_rates = gen_vec.*(obj.birth_rate);
                    num = rand()*sum(tot_rates);
                    chosen_type = 0;
                    while num > 0
                        chosen_type = chosen_type + 1;
                        num = num - tot_rates(chosen_type);
                    end
                    dead_cell = randi(numel(obj.matrix),1,2);
                    obj.matrix(dead_cell) = chosen_type;
                end
                h = obj.isHomogenous();
            else
                for i = 1:numel(obj.matrix)
                    tot_rates = gen_vec.*(obj.birth_rate);
                    num = rand()*sum(tot_rates);
                    chosen_type = 0;
                    while num > 0
                        chosen_type = chosen_type + 1;
                        num = num - tot_rates(chosen_type);
                    end
                    t = 1:obj.num_types;
                    t = t(gen_vec > 0);
                    %chosen dead type with probability proportional to the
                    %number of cells
                    dead_num = rand()*sum(gen_vec);
                    dead_type = 0;
                    while dead_num > 0
                        dead_type = dead_type + 1;
                        dead_num = dead_num - gen_vec(dead_type);
                    end
                    %birth one
                    gen_vec(chosen_type) = gen_vec(chosen_type) + 1;
                    %kill one
                    gen_vec(dead_type) = gen_vec(dead_type) - 1;
                end
                obj.total_count(:, obj.timestep + 1) = gen_vec;
                h = length(find(obj.total_count(:, obj.timestep + 1)>=numel(obj.matrix), 1));
            end
            [mat, changed, t] = obj.get_next_cleanup();
            h = h && ~obj.mutation_manager.mutating;
        end
        
        %See GridManagerAbstract
        function update_params(obj)
            for i = 1:obj.num_types
                if obj.plot_grid
                    obj.total_count(i, obj.timestep) = length(find(obj.matrix == i));
                end
                obj.percent_count(i, obj.timestep) = obj.total_count(i, obj.timestep)./numel(obj.matrix);
                obj.mean_fitness(i, obj.timestep) = (obj.birth_rate(i))*obj.percent_count(i, obj.timestep); 
            end
            obj.overall_mean_fitness(obj.timestep) = dot(obj.mean_fitness(:,obj.timestep), obj.total_count(:,obj.timestep));
        end

    end
end