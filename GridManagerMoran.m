classdef GridManagerMoran < GridManagerAbstract
    
    properties
        proportion_vec;
        birth_rate;
    end
    
    methods (Access = public)
        
        function obj = GridManagerMoran(dim, Ninit, b)
            assert(sum(Ninit)==dim.^2);
            obj@GridManagerAbstract(dim, Ninit);
            obj.birth_rate = b;
            obj.proportion_vec = [];
            for i = 1:length(b)
                obj.proportion_vec = [obj.proportion_vec repmat(i,1,round(b(i)*100))];
            end
            obj.update_params();
        end
        
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t, h] = get_next(obj)
            %pick a cell at random, kill it, then pick a type in proportion
            %to birth rate and replace killed cell with that type
            obj.timestep = obj.timestep + 1;
            n = size(obj.matrix, 1);
            c = randi(n,1,2);
            changed = sub2ind(size(obj.matrix),c(1),c(2));
            index = randi(length(obj.proportion_vec));
            obj.matrix(changed) = obj.proportion_vec(index);
            %then, include all computation updates
            obj.update_params();
            obj.output = [obj.output; obj.matrix(:)'];
            mat = obj.matrix;
            t = obj.timestep;
            h = obj.isHomogenous();
            if obj.timestep <= 2
                changed = (1:numel(obj.matrix))';
            end
        end
        
        function update_params(obj)
            for i = 1:obj.num_types
                obj.total_count(i, obj.timestep) = length(find(obj.matrix == i));
                obj.percent_count(i, obj.timestep) = obj.total_count(i, obj.timestep)./numel(obj.matrix);
                obj.mean_fitness(i, obj.timestep) = (obj.birth_rate(i))*obj.percent_count(i, obj.timestep); 
            end 
        end

    end
end