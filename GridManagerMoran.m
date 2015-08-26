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
                chosenType = obj.weightedSelection(totRates);
                tempVec(chosenType) = tempVec(chosenType) + 1;
                %choose a type to kill - random choice of dead type, weighted by current counts 
                %If spatial structure is enabled, limit the choice of dead
                %organisms to those surrounding the "mother" organism of
                %chosenType
                if obj.spatialOn && obj.matrixOn
                    [a, b] = ind2sub(size(obj.matrix), obj.getRandomOfType(chosenType));
                    v = obj.getNeighborWeighted(a, b, zeros(1, obj.numTypes));
                    deadType = obj.matrix(v(1), v(2));
                    ind = sub2ind(size(obj.matrix), v(1), v(2));
                    obj.changeMatrix(ind, chosenType);
                elseif obj.matrixOn
                    %choose a cell of the birthed type, and find the
                    %nearest cell to it of the kill type and fill that cell
                    %with the birthed type
                    deadType = obj.weightedSelection(tempVec);
                    ind = obj.getRandomOfType(deadType);
                    assert(ind > 0, 'ERROR: getRandomOfType returned -1');
                    obj.changeMatrix(ind, chosenType);
                else %nonPlotting
                	deadType = obj.weightedSelection(tempVec);
                end
                tempVec(deadType) = tempVec(deadType) - 1;
                
            end
            obj.totalCount(:, obj.timestep + 1) = tempVec;
            [mat, changed, t, h] = obj.getNextCleanup();
        end
        

    end
  

end