%Th Grid Manager for both the exponential and the logistic models

classdef GridManagerLogistic < GridManagerAbstract
    
    properties
        birth_rate;
        death_rate;
        use_exp; %if 1, use exponential model instead of logistic
    end
    
    methods (Access = public)
        
        function obj = GridManagerLogistic(dim, Ninit, b, d, plot_grid, use_exp)
            obj@GridManagerAbstract(dim, Ninit);
            obj.birth_rate = b';
            obj.death_rate = d';
            obj.plot_grid = plot_grid;
            obj.use_exp = use_exp;
            obj.update_params();
        end
        
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t, h] = get_next(obj)
            if obj.plot_grid 
                if obj.timestep == 1
                    old_mat = zeros(size(obj.matrix));
                else
                    old_mat = obj.matrix;
                end
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
                            if obj.use_exp
                                f = obj.get_nearest_free(a, b);
                            else
                                f = randi(numel(obj.matrix));
                                if obj.matrix(f) ~= 0
                                    f = 0;
                                end
                            end
                            if (f > 0)
                                obj.matrix(f) = i;
                                new = [new f];
                            end
                        end
                    end
                end
                mat = obj.matrix;
                obj.output = [obj.output; obj.matrix(:)'];
                if obj.timestep <= 2
                    changed = (1:numel(obj.matrix))';
                else
                	changed = find(obj.old_matrix ~= obj.matrix);
                end
                obj.old_matrix = obj.matrix;
            else
                obj.total_count(:, obj.timestep + 1) = obj.total_count(:, obj.timestep);
                changed = (1:numel(obj.matrix))';
                mat = [];
                tot_rates = obj.total_count(:,obj.timestep + 1).*(obj.birth_rate + obj.death_rate);
                num = rand()*sum(tot_rates);
                chosen_type = 0;
                while num > 0
                    chosen_type = chosen_type + 1;
                    num = num - tot_rates(chosen_type);
                end
                if num + obj.birth_rate(chosen_type)*obj.total_count(chosen_type, obj.timestep + 1) > 0
                    obj.total_count(chosen_type, obj.timestep + 1) = obj.total_count(chosen_type, obj.timestep + 1) + 1;
                else
                    obj.total_count(chosen_type, obj.timestep + 1) = obj.total_count(chosen_type, obj.timestep + 1) - 1;
                end
                %obj.generations = [obj.generations obj.timestep];%(obj.generations(end) + 1/sum(obj.total_count(:, obj.timestep)))];
            end
            %then, include all computation updates
            obj.timestep = obj.timestep + 1;
            obj.generations = [obj.generations obj.timestep];
            obj.update_params();
            h = ~sum(obj.total_count(:,obj.timestep)) || sum(obj.total_count(:,obj.timestep)) == numel(obj.matrix);
            t = obj.timestep;
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