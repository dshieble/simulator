classdef GridManagerMoran < GridManagerAbstract
%This class is the GridManager implementation for the Moran model

    properties (Constant)
        %The tag properties, these characterize the class itself
        Name = 'Moran';
        OverlappingGenerations = 1;
        ParamName1 = 'Birth Rate';
        ParamName2 = '';
        atCapacity = 1;
        plottingEnabled = 1;
    end
    
    properties
    end
    
    methods (Access = public)
        
                
        function obj = GridManagerMoran(dim, Ninit, mutation_manager, matrixOn, spatialOn, edgesOn, b, d)
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, matrixOn, spatialOn, edgesOn, b, d);
        end
        
        
        %See GridManagerAbstract
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t, h] = getNext(obj)
            %pick a cell at random, kill it, then pick a type in proportion
            %to birth rate and replace killed cell with that type
            tempVec = obj.totalCount(:, obj.timestep);
            for i = 1:obj.maxSize
                tot_rates = tempVec.*(obj.Param1);
                %choose a type to birth
                num = rand()*sum(tot_rates);
                chosenType = 0;
                while num > 0
                    chosenType = chosenType + 1;
                    num = num - tot_rates(chosenType);
                end
                tempVec(chosenType) = tempVec(chosenType) + 1;
                %choose a type to kill
                dead_num = rand()*sum(tempVec);
                dead_type = 0;
                while dead_num > 0
                    dead_type = dead_type + 1;
                    dead_num = dead_num - tempVec(dead_type);
                end
                tempVec(dead_type) = tempVec(dead_type) - 1;
                %Render the birth and death on the matrix
                if obj.matrixOn
                    %choose a cell of the birthed type, and find the
                    %nearest cell to it of the kill type and fill that cell
                    %with the birthed type
                    if obj.spatialOn && (dead_type ~= chosenType)
                        [a, b] = ind2sub(size(obj.matrix), obj.getRandomOfType(chosenType));
                        ind = obj.getNearestOfType(a, b, dead_type);
                        assert(ind > 0, sprintf('ERROR: getNearestOfType is returning %d', ind));
                        obj.changeMatrix(ind, chosenType);
                    else %if dead type and chosen type are equal, then we just reset the age of a random organism of that type. 
                        obj.changeMatrix(obj.getOfType(dead_type), chosenType);
                    end
                end
            end
            obj.totalCount(:, obj.timestep + 1) = tempVec;
            [mat, changed, t, h] = obj.getNextCleanup();
        end
        

    end
  

end