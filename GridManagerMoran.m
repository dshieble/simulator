classdef GridManagerMoran < GridManagerAbstract
%This class is the GridManager implementation for the Moran model

    properties (Constant)
        %The tag properties, these characterize the class itself
        Name = 'Moran';
        OverlappingGenerations = 1;
        ParamName1 = 'Malthusian';
        ParamName2 = '';
        ParamBounds1 = [0 1];
        ParamBounds2 = [-Inf Inf];
        atCapacity = 1;
        plottingEnabled = 1;
    end

    
    methods (Access = public)
        
        function obj = GridManagerMoran(dim, Ninit, mutationManager, matrixOn, spatialOn, edgesOn, b, d)
            obj@GridManagerAbstract(dim, Ninit, mutationManager, matrixOn, spatialOn, edgesOn, b, d);
        end
        
        % Represents one birth event   
        function reproductiveEvent(obj)
        	totRates = obj.totalCount(:, obj.timestep).*(obj.Param1);
            %choose a type to birth
            chosenType = obj.weightedSelection(totRates);
            %choose a type to kill - random choice of dead type, weighted by current counts 
            ind = 0;
            if obj.spatialOn && obj.matrixOn
                %If spatial structure is enabled, limit the choice of dead
                %organisms to those surrounding the "mother" organism of
                %chosenType
                [a, b] = ind2sub(size(obj.matrix), obj.getRandomOfType(chosenType));
                v = obj.getNeighborWeighted(a, b, zeros(1, obj.numTypes));
                ind = sub2ind(size(obj.matrix), v(1), v(2));
            elseif obj.matrixOn
                %choose a cell of the birthed type, and find the
                %nearest cell to it of the kill type and fill that cell
                %with the birthed type
                ind = randi(obj.maxSize);
            else %nonPlotting
                deadType = obj.weightedSelection(obj.totalCount(:, obj.timestep));
                obj.kill(0, deadType);
            end
            obj.birth(ind, chosenType);
        end
    end
  

end