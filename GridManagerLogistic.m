classdef GridManagerLogistic < GridManagerAbstract
%This class is an implementation of the GridManager class for the Logistic
%model
    
    properties (Constant) %See GridManagerAbstract for description
        Name = 'Logistic';
        OverlappingGenerations = 1;
        ParamName1 = 'Birth Rate';
        ParamName2 = 'Death Rate';
        atCapacity = 0;
        plottingEnabled = 1;
    end
    
    methods (Access = public)
        
        function obj = GridManagerLogistic(dim, Ninit, mutation_manager, matrixOn, spatialOn, edgesOn, b, d)
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, matrixOn, spatialOn, edgesOn, b, d);
        end
        
        %See GridManagerAbstract
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        function [mat, changed, t, h] = getNext(obj)
            tempVec = obj.totalCount(:, obj.timestep);
            for i = 1:sum(tempVec)
                if sum(tempVec) <= 0
                    break;
                end
                totRates = tempVec.*(obj.Param1 + obj.Param2);
                if min(totRates) < 0
                    totRates = totRates + abs(min(totRates));
                end

                num = rand()*sum(totRates);
                chosenType = 0;
                while num > 0
                    chosenType = chosenType + 1;
                    num = num - totRates(chosenType);
                end

                if num + obj.Param1(chosenType)*tempVec(chosenType) > 0 && sum(tempVec) < obj.maxSize
                    if rand() <= 1-(sum(tempVec)/obj.maxSize)
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
                                deadType = obj.matrix(ind);
                                if deadType ~= 0
                                	tempVec(deadType) = tempVec(deadType) - 1;
                                end
                                obj.changeMatrix(ind, chosenType);
                            else
                                %Change a free cell to the chosen type
                                obj.changeMatrix(obj.getFree(), chosenType);
                            end
                        end
                        tempVec(chosenType) = tempVec(chosenType) + 1;
                    end
                else
                    if obj.matrixOn && tempVec(chosenType) > 0
                        obj.changeMatrix(obj.getRandomOfType(chosenType), 0);
                    end
                    tempVec(chosenType) = max(0, tempVec(chosenType) - 1);
                end
            end
            %then, include all computation updates
            obj.totalCount(:, obj.timestep + 1) = tempVec;
            [mat, changed, t, h] = obj.getNextCleanup();
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
end