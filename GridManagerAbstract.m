classdef (Abstract) GridManagerAbstract < handle
%This class is the parent class of the 4 grid managers. It contains methods
%that are used by all of its child classes, as well as the instance
%variables used across all classes. 

%The GridManager class stores the matrix/counts of each species, and
%contains a method getNext that advances the matrix/counts to the next
%generation, based on the model that the GridManager's implementation is based
%on
    properties (Abstract, Constant)  %The tag properties, these characterize the class itself
        Name; %The name of the model
        OverlappingGenerations; %Whether the generations overlap. This is 1 for Moran, 0 for Wright-Fisher
        ParamName1; %Name of first parameter, e.g. birth_rate
        ParamName2; %Name of second parameter, e.g. birth_rate
        atCapacity; %Whether or not the model requires that the total population is always constant and at capacity. 1 for moran, 0 for logistic
        plottingEnabled; %Whether or not the model supports a matrixOn (show petri dish) mode
    end 
    
    properties (SetAccess = private)
        maxSize; %The maximum possible population size
        mutationManager; %A pointer to the mutation manager class that handles mutating each type to other types
        matrixOn; %Determines whether the matrix model or vector model is used
        spatialOn; %Determines whether the spatial structure is considered. Functionality is determined by child classes.
        edgesOn; %Determines whether the edges are considered when searching for the closest square of a type. If 0, the matrix is actually a torus
        Param1; %The first parameter for the model. Typically birth rate or fitness.
        Param2; %The second parameter for the model. Typically death rate. Not all models have 2 parameters. 
        matrix; %Stores the location of each organism
        oldMatrix; %Stores the matrix from the previous iteration
        ageMatrix; %stores how old each organism in the matrix is 
        ageStructure; %cell array, each cell is a timestep storing a vector that stores the frequency of each age
        saveData; %The data that is exported to a .mat file when the user presses save
        timestep; %The number of steps since the beginning of the simulation
        numTypes; %The number of different types in the simulation
        colors; %The vector of each type's color

    end
    
    properties (SetAccess = protected)
        %The Population Parameters. Updated in updateParams. 
        totalCount; %Stores the counts of each type in each generation. matrix of dimensions num types x timestep
        percentCount; %Stores the percent counts of each type in each generation. matrix of dimensions num types x timestep
        overallMeanFitness; %Stores the overall fitness of each type in each generation. vector of length timestep
    end
    
    methods (Access = public)
        %The constructor method. This function initializes the matrix and
        %the plotting parameters, as well as other useful variables like
        %the color variable. The final 2 inputs are the Param1 and the
        %Param2 inputs
        function obj = GridManagerAbstract(maxSize, Ninit, mutationManager, matrixOn, spatialOn, edgesOn, p1, p2)
            assert(~matrixOn || floor(sqrt(maxSize))^2 == maxSize)
            assert((obj.atCapacity && sum(Ninit)==maxSize) || (~obj.atCapacity && sum(Ninit) <= maxSize), 'ASSERTION ERROR: Incorrect initial populations');
            obj.Param1 = p1';
            obj.Param2 = p2';
            obj.spatialOn = spatialOn;
            obj.matrixOn = matrixOn;
            obj.edgesOn = edgesOn;
            if obj.matrixOn
                obj.matrix = zeros(sqrt(maxSize));
                obj.ageMatrix = zeros(sqrt(maxSize)) - 1;
            else
                obj.matrix = [];
                obj.ageMatrix = [];
            end
            obj.oldMatrix = obj.matrix;
            obj.maxSize = maxSize;
            obj.timestep = 1;
            obj.numTypes = length(Ninit);
            obj.totalCount = Ninit';
            
            
            if obj.matrixOn
                if (sum(Ninit) == obj.maxSize) || ~spatialOn %static population models, random placement
                    r = randperm(numel(obj.matrix));
                    i = 1;
                    for type = 1:length(Ninit)
                        n = Ninit(type);
                        obj.changeMatrix(r(i:n+i-1), type);
                        i = i + n;
                    end
                else %non-static models, place founding cells in center
                    origVec = [];
                    for type = 1:length(Ninit)
                        origVec = [origVec repmat(type,1,Ninit(type))];
                    end
                    origVec = origVec(randperm(length(origVec)));
                    ind = obj.getCenter();
                    for i = 1:length(origVec)
                        obj.changeMatrix(ind, origVec(i));
                        [a, b] = ind2sub(size(obj.matrix), ind);
                        ind = obj.getNearestFree(a,b);
                    end
                end
            end
           

            %when there are more than 10 types, colors become randomized
            obj.colors = [1 0 0; ...
                0 1 0; ...
                0 0 1; ...
                1 1 0; ...
                1 0 1;...
                0 1 1; ...
                1 0.5 0.5; ...
                0.5 1 0.5; ...
                1 0.5 0.5;...
                0.5 0.5 0.5; ...
                0.25 0.25 1; ...
                1 .25 .25;...
                .25 1 .25;
                .5 .25 0; ...
                .25 0 .5; ...
                0 .25 .5; ...
                .15 .15 .15;];
            obj.percentCount = [];
            obj.overallMeanFitness = [];
            obj.ageStructure = {[]};
            obj.mutationManager = mutationManager;
            obj.saveData = struct('Param1', p1, 'Param2', p2);
            obj.updateParams();
        end
      
        %This function is called at the end of getNext by all of the child
        %classes. It instantiates the output variables and increments the
        %timestep. 
        %
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not the model should halt
        function [mat, changed, t, h] = getNextCleanup(obj)
            obj.timestep = obj.timestep + 1;
            obj.mutationManager.mutate(obj);
            obj.mutationManager.recombination(obj);
            if ~obj.matrixOn
                changed = [];
            else
                changed = find(obj.oldMatrix ~= obj.matrix);
                obj.oldMatrix = obj.matrix;
            end
            obj.updateParams();
            obj.saveData.totalCount = obj.totalCount;
            obj.saveData.totalCount = obj.totalCount;
            obj.saveData.ageStructure = obj.ageStructure;
            mat = obj.matrix;
            t = obj.timestep;
            h = max(obj.totalCount(:, obj.timestep))>=obj.maxSize;
            h = h && ~obj.mutationManager.mutating || (sum(obj.totalCount(:, obj.timestep)) == 0);
        end

        
        %Returns a free square in the matrix
        function ind = getFree(obj)
            assert(obj.matrixOn == 1)
            free = find(obj.matrix == 0);
            if isempty(free)
                ind = randi(obj.maxSize);
            else       
                ind = free(randi(length(free)));
            end
        end

        %Returns the nearest square in the matrix of type t        
        function ind = getNearestOfType(obj, x, y, t)
            assert(obj.matrixOn == 1);
            indices = find(obj.matrix == t);
            base = sub2ind(size(obj.matrix), x, y);
            indices = indices(indices ~= base);
            if isempty(indices)
                ind = 0;
                return;
            end
            dists = matrixDistance(obj, repmat(base,1,length(indices))', indices);
            [~,i] = min(dists);
            ind = indices(i);
        end
        
        %Returns the manhattan distance between 2 cells in the matrix. Uses wrapping
        %if ~obj.edges
        function d = matrixDistance(obj, base, ind)
            assert(obj.matrixOn == 1);
            [a_1, b_1] = ind2sub(size(obj.matrix), base);
            [a_2, b_2] = ind2sub(size(obj.matrix), ind);
            wd = abs(a_1 - a_2);
            hd = abs(b_1 - b_2);
            if ~obj.edgesOn %wrappping
                wd = min(wd, size(obj.matrix,1) - wd);
                hd = min(hd, size(obj.matrix,2) - hd);
            end
            d = hd + wd;
        end
        

        
        %Returns the nearest free square in the matrix
        function ind = getNearestFree(obj, i, j)
            assert(obj.matrixOn == 1);
            ind = getNearestOfType(obj, i, j, 0);
        end
        
        %Returns the non-diagonal neighboring squares of i,j
        % indices(1,:) = row
        % indices(2,:) = column
        %     4
        %   1 x 3
        %     2
        function indices = getNeighbors(obj, i, j)
            assert(obj.matrixOn == 1);
            s = sqrt(obj.maxSize);
            %unchanged
            indices(1,1) = i;
            indices(1,3) = i;
            indices(2,2) = j;
            indices(2,4) = j;
            %changed
            indices(2,1) = j - 1;
            indices(2,3) = j + 1;
            indices(1,2) = i + 1;
            indices(1,4) = i - 1;
            if ~obj.edgesOn
            	indices(2,1) = mod(indices(2,1) - 1, s) + 1;
                indices(2,3) = mod(indices(2,3) - 1, s) + 1;
                indices(1,2) = mod(indices(1,2) - 1, s) + 1;
                indices(1,4) = mod(indices(1,4) - 1, s) + 1;
            else
                remove = [];
                if indices(2,1) <= 0 || indices(2,1) > s
                    remove = [remove 1];
                end
                if indices(2,3) <= 0 || indices(2,3) > s
                    remove = [remove 3];
                end
                if indices(1,2) <= 0 || indices(1,2) > s
                    remove = [remove 2];
                end
                if indices(1,4) <= 0 || indices(1,4) > s
                    remove = [remove 4];
                end
                indices(:,remove) = [];
            end
            assert(length(indices) >= 2 && length(indices) <= 4, 'ERROR: Number of Neighbors is incorrect');
        end
        
        %Get the neighbors of the input cell. If any neighbor is
        %free, select it. Otherwise, randomly select a
        %neighbor weighted by typeWeighting. 0 cells are always chosen if
        %possible
        %typeWeighting - a vector of length numTypes that assigns a weight
        %to the chance of killing each type
        function RowCol = getNeighborWeighted(obj, a, b, typeWeighting)
            neighbors = obj.getNeighbors(a, b);
            neighbors = neighbors(:, randperm(length(neighbors))); %prevent preferential treatment
            weights = zeros(1, length(neighbors));
            for w = 1:length(weights)
                t = obj.matrix(neighbors(1,w), neighbors(2,w));
                if t == 0
                    RowCol = [neighbors(1,w), neighbors(2,w)];
                    return;
                else
                    weights(w) = typeWeighting(t);
                end
            end
            index = obj.weightedSelection(weights);
            RowCol = [neighbors(1,index), neighbors(2,index)];
        end

        %Gets the center cell in the matrix
        function ind = getCenter(obj)
        	assert(obj.matrixOn == 1);
            a = ceil(size(obj.matrix, 1)/2);
            ind = sub2ind(size(obj.matrix),a,a);
        end
        
        %Gets the ith color from the color matrix
        function c = getColor(obj,i)
            c = obj.colors(i,:);
        end

        %returns 1 if there is only one species
        function h = isHomogenous(obj)
            h = (max(obj.totalCount(:, obj.timestep)) == obj.maxSize);
        end
        
        %Returns a random cell of the chosen type
        function out = getRandomOfType(obj, type)
            assert(obj.matrixOn == 1)
            ofType = find(obj.matrix == type);
            if isempty(ofType)
                out = -1;
            else
            	out = ofType(randi(numel(ofType)));
            end
        end
                
        %Returns an index in the vector vec, weighted by the contents of
        %vec
        function [ind, num] = weightedSelection(obj, vec)
            vec = vec + min(vec);
            if sum(vec) == 0
                ind = randi(length(vec));
                return;
            end
            num = rand()*sum(vec);
            ind = 0;
            while num > 0
                ind = ind + 1;
                num = num - vec(ind);
            end
        end
        
        
        %Returns a random type from among the valid types for this matrix
        function type = getRandomType(obj)
            type = randi(obj.num_types);
        end
       
        %Changes an element in the matrix and resets the age
        function changeMatrix(obj, ind, new)
            assert(obj.matrixOn == 1);
            assert(numel(new) == 1);
            assert((new >= 0) && (new <= obj.numTypes) && (round(new) == new), 'ERROR: New type must be an integer between 0 and numTypes');
            obj.matrix(ind) = new;
            if new > 0
                obj.ageMatrix(ind) = 0;
            else
                obj.ageMatrix(ind) = -1;
            end
        end
        
        %Mutates an element in the matrix (changes it without changing its
        %age)
        function mutateMatrix(obj, ind, new)
            assert(obj.matrixOn == 1);
            assert(numel(new) == 1);
            assert(obj.matrix(ind) ~= 0, 'ERROR: Cannot mutate an element that is currently zero');
            assert(new ~= 0, 'ERROR: Cannot mutate an element to become zero');
            assert(new >= 0 && new <= obj.numTypes && round(new) == new, 'ERROR: New type must be an integer between 0 and numTypes');
            obj.matrix(ind) = new;
        end
        
        %Resets the matrix to the input
        function resetMatrix(obj, newMat)
            assert(obj.matrixOn == 1);
            assert(all(size(obj.matrix) == size(newMat)), 'ERROR: Dimensions of newMat are wrong');
            assert(all(newMat(:) >= 0) && all(newMat(:) <= obj.numTypes) && all(round(newMat(:)) == newMat(:)), 'ERROR: newMat has invalid elements');
            obj.matrix = newMat;
            obj.ageMatrix = zeros(sqrt(obj.maxSize));
            obj.ageMatrix(newMat == 0) = -1;
        end
        
        %Sets the total count variable
        function setTotalCount(obj, new)
            assert(sum(new) <= obj.maxSize);
            assert(all(new >= 0));
            obj.totalCount(:, obj.timestep) = new;
        end
                    
        %Updates the totalCount, the percentCount, the overallMeanFitness and
        %the ageMatrix/ageStructure properties
        function updateParams(obj)
            meanFitness = zeros(1,obj.numTypes);
            for i = 1:obj.numTypes
                obj.percentCount(i, obj.timestep) = obj.totalCount(i, obj.timestep)./numel(obj.matrix);
                meanFitness(i) = (obj.Param1(i))*obj.percentCount(i, obj.timestep); 
            end
            obj.overallMeanFitness(obj.timestep) = dot(meanFitness, obj.totalCount(:,obj.timestep));
            if obj.OverlappingGenerations && obj.matrixOn
                obj.ageMatrix(obj.ageMatrix ~= -1) = obj.ageMatrix(obj.ageMatrix ~= -1) + 1;
                ages = obj.ageMatrix(obj.ageMatrix ~= -1);
                obj.ageStructure{obj.timestep} = hist(ages, max(ages))./length(ages);
            end            
        end
        
        
        
    end
    
    
    
    methods (Abstract)        
        %A method implemented by all of the child GridManager class.
        %This method updates obj.totalCount for the new timestep, and, if
        %matrixOn is enabled, also updates the GridManager's petri dish
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        [mat, changed, t, h] = getNext(obj)
    end
    
    
end