classdef GridManagerWright < GridManagerAbstract
%This class is the GridManager implementation for the Wright-Fisher model

   properties (Constant)
        %The tag properties, these characterize the class itself
        Name = 'Wright-Fisher';
        OverlappingGenerations = 0;
        ParamName1 = 'Fitness';
        ParamName2 = '';
        atCapacity = 1;
        plottingEnabled = 1;
    end
    
    properties
        proportion_vec;
    end
    
    methods (Access = public)
        
        function obj = GridManagerWright(dim, Ninit, mutation_manager, matrixOn, spatialOn, edgesOn, b, d)
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, matrixOn, spatialOn, edgesOn, b, d);
        end
        
        %See GridManagerAbstract
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [changed, h] = getNext(obj)
            %For each cell, replace it with a multinomially chosen type where 
            %probabilities are determined based on Param1 and current count.
            %Updates are based on the obj.totalCount parameter
            counts = obj.totalCount(:, obj.timestep);
            v = (obj.Param1.*counts);
            probs = v./sum(v);
            new_counts = mnrnd(obj.maxSize, probs);
            if obj.matrixOn 
                long_mat = [];
                for i = 1:obj.numTypes
                    long_mat = [long_mat repmat(i,1,new_counts(i))];
                end
                long_mat = long_mat(randperm(length(long_mat)));
                assert(numel(long_mat) == obj.maxSize);
                obj.resetMatrix(reshape(long_mat, size(obj.matrix,1), size(obj.matrix,2)));
            end
            obj.totalCount(:, obj.timestep + 1) = new_counts;
            [changed, h] = obj.getNextCleanup();
        end
       

    end
end