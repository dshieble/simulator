classdef (Abstract) GridManagerLogExpAbstract < GridManagerAbstract
%This abstract class stores the code that is the same between the logistic
%and exponential models
    
    methods (Access = public)
        
        %Basic inherited constructor
        function obj = GridManagerLogExpAbstract(dim, Ninit, mutation_manager, matrixOn, spatialOn, edgesOn, b, d)
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, matrixOn, spatialOn, edgesOn, b, d);
        end      
        
        % Represents one birth event   
        function reproductiveEvent(obj)
            %perform death events
            while max(obj.totalCount(:, obj.timestep)) > 0
                birthRates = obj.getBirthRates();
                totRates = obj.totalCount(:, obj.timestep).*(birthRates + obj.Param2);
                chosenType = obj.weightedSelection(totRates);
                death = (rand()*(obj.Param1(chosenType)+obj.Param2(chosenType))) < obj.Param2(chosenType);
                if sum(obj.totalCount(:, obj.timestep)) < obj.maxSize && ~death
                    %no death event, abort
                    break;
                else
                    %perform death event
                    if obj.totalCount(chosenType, obj.timestep) > 0
                        ind = 0;
                        if obj.matrixOn
                            ind = obj.getRandomOfType(chosenType);
                        end
                        obj.kill(ind, chosenType)
                    end
               end
            end
            if max(obj.totalCount(:, obj.timestep)) == 0
                %everyone's dead, abort mission
                return
            end
            %perform birth events
            ind = 0;
            if obj.matrixOn
                %Choose a cell of the chosen type, get the
                %neighbors of that cell. If any neighbor is
                %free, select. Otherwise, randomly select a
                %neighbor weighted by death rate. Replace the
                %neighbor cell with the chosen type
                if obj.spatialOn
                    [a, b] = ind2sub(size(obj.matrix), obj.getRandomOfType(chosenType));
                    v = obj.getNeighborWeighted(a, b, obj.Param2);
                    ind = sub2ind(size(obj.matrix), v(1), v(2));
                else
                    %Change a free cell to the chosen type
                    ind = obj.getFree();
                end
            end
            obj.birth(ind, chosenType);
        end
        
        
        %Overriden method to account for fact that fitness is determined by
        %difference between birth and death rates here
        function updateParams(obj)
            updateParams@GridManagerAbstract(obj);
            meanFitness = zeros(1,obj.numTypes);
            for i = 1:obj.numTypes
                meanFitness(i) = (obj.Param1(i)-obj.Param2(i))*obj.percentCount(i, obj.timestep); 
            end
            obj.overallMeanFitness(obj.timestep) = dot(meanFitness, obj.totalCount(:,obj.timestep));
        end

    end
    
    methods (Abstract)        
        %Gets the birth rate for an iteration
        birthRates = getBirthRates(obj)
    end
    
        
end


