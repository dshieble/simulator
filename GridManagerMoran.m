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
        
                
        function obj = GridManagerMoran(dim, Ninit, mutationManager, matrixOn, spatialOn, edgesOn, b, d)
            obj@GridManagerAbstract(dim, Ninit, mutationManager, matrixOn, spatialOn, edgesOn, b, d);
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
                totRates = tempVec.*(obj.Param1);
                %choose a type to birth
                num = rand()*sum(totRates);
                chosenType = 0;
                while num > 0
                    chosenType = chosenType + 1;
                    num = num - totRates(chosenType);
                end
                tempVec(chosenType) = tempVec(chosenType) + 1;
                %choose a type to kill
                deadNum = rand()*sum(tempVec);
                deadType = 0;
                while deadNum > 0
                    deadType = deadType + 1;
                    deadNum = deadNum - tempVec(deadType);
                end
                tempVec(deadType) = tempVec(deadType) - 1;
                %Render the birth and death on the matrix
                if obj.matrixOn
                    %choose a cell of the birthed type, and find the
                    %nearest cell to it of the kill type and fill that cell
                    %with the birthed type
                    if obj.spatialOn && (deadType ~= chosenType)
                        [a, b] = ind2sub(size(obj.matrix), obj.getRandomOfType(chosenType));
                        ind = obj.getNearestOfType(a, b, deadType);
                        assert(ind > 0, sprintf('ERROR: getNearestOfType is returning %d', ind));
                        obj.changeMatrix(ind, chosenType);
                    else %if dead type and chosen type are equal, then we just reset the age of a random organism of that type. 
                        ind = obj.getRandomOfType(deadType);
                        assert(ind > 0, 'ERROR: getRandomOfType returned -1');
                        obj.changeMatrix(ind, chosenType);
                    end
                end
            end
            obj.totalCount(:, obj.timestep + 1) = tempVec;
            [mat, changed, t, h] = obj.getNextCleanup();
        end
        

    end
  

end