classdef GridManagerWright < GridManagerAbstract
%This class is the GridManager implementation for the Wright-Fisher model

   properties (Constant)
        %The tag properties, these characterize the class itself
        Name = 'Wright-Fisher';
        OverlappingGenerations = 0;
        Param_1_Name = 'Fitness';
        Param_2_Name = '';
        atCapacity = 1;
        plottingEnabled = 1;
    end
    
    properties
        proportion_vec;
    end
    
    methods (Access = public)
        
        function obj = GridManagerWright(dim, Ninit, mutation_manager, plot_grid, plottingParams, spatial_on, edges_on, b, d)
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, plot_grid, plottingParams, spatial_on, edges_on, b, d);
        end
        
        %See GridManagerAbstract
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t, h] = get_next(obj)
            %For each cell, replace it with a multinomially chosen type where 
            %probabilities are determined based on Param1 and current count.
            %Updates are based on the obj.total_count parameter
            counts = obj.total_count(:, obj.timestep);
            v = (obj.Param1.*counts);
            probs = v./sum(v);
            new_counts = mnrnd(obj.max_size, probs);
            if obj.plot_grid 
                long_mat = [];
                for i = 1:obj.num_types
                    long_mat = [long_mat repmat(i,1,new_counts(i))];
                end
                long_mat = long_mat(randperm(length(long_mat)));
                assert(numel(long_mat) == obj.max_size);
                obj.resetMatrix(reshape(long_mat, size(obj.matrix,1), size(obj.matrix,2)));
            end
            obj.total_count(:, obj.timestep + 1) = new_counts;
            [mat, changed, t, h] = obj.get_next_cleanup();
        end
       

    end
end