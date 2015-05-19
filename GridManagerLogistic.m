classdef GridManagerLogistic < GridManagerAbstract
    
    properties
        birth_rate;
        death_rate;
    end
    
    methods (Access = public)
        
        function obj = GridManagerLogistic(dim, Ninit, b, d)
            obj@GridManagerAbstract(dim, Ninit);
            obj.birth_rate = b;
            obj.death_rate = d;
            obj.update_params();
        end
        
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t, h] = get_next(obj)
            if obj.timestep == 1
                old_mat = zeros(size(obj.matrix));
            else
                old_mat = obj.matrix;
            end
            obj.timestep = obj.timestep + 1;
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
            for i = 1:obj.num_types
                ind = find(obj.matrix == i);
                for j = ind'
                    if (rand() < obj.birth_rate(i))
                        f = obj.get_free();
                        if (f > 0)
                            obj.matrix(f) = i;
                        end
                    end
                end
            end
            
            %then, include all computation updates
            obj.update_params();
            obj.output = [obj.output; obj.matrix(:)'];
            mat = obj.matrix;
            changed = find(old_mat ~= obj.matrix);
            t = obj.timestep;
            h = isempty(find(mat > 0, 1)) || isempty(find(mat == 0, 1));
        end
        
        function update_params(obj)
            for i = 1:obj.num_types
                obj.total_count(i, obj.timestep) = length(find(obj.matrix == i));
                obj.percent_count(i, obj.timestep) = obj.total_count(i, obj.timestep)./numel(obj.matrix);
                obj.mean_fitness(i, obj.timestep) = (obj.birth_rate(i)-obj.death_rate(i))*obj.percent_count(i, obj.timestep); 
            end 
        end

    end
end