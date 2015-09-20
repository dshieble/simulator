classdef MutationManager < handle
%This class handles the mutations and recombinations of elements in the matrix. When >1 loci
%are selected, this class also converts types to their binary allele
%strings via the conversion alleleN = nth bit of (num-1) (0 indexed).

%The mutation methods in this class are called once every generation

    properties (SetAccess = private)
        mutating; %Whether or not mutation is enabled
        mutationMatrix; %A matrix that stores the transition probabilities. 
        numLoci; %The number of loci in each genotype
        recombining; %Whether or not recombination is enabled 
        recombinationNumber; %The recombination probability.
    end
    
    methods (Access = public)
        %% mutation
        
        %Basic Constructor for the MutationManager class
        function obj = MutationManager(mutating, mutationMatrix, numLoci, recombination, recombinationNumber)
            obj.mutating =  mutating;
            obj.mutationMatrix =  mutationMatrix;
            obj.numLoci = numLoci;
            obj.recombining = recombination && obj.numLoci > 1;
            obj.recombinationNumber = recombinationNumber;
            assert(all(sum(obj.mutationMatrix)-1 < 10e3), 'ASSERTION ERROR: Columns of Mutation Matrix must sum to 1.');
            if obj.numLoci > 1 && obj.mutating
            	assert(all(size(obj.mutationMatrix) == [2 2]), 'ASSERTION ERROR: If numLoci > 1, Mutation Matrix must be 2x2');
            end

        end

        
        %Accepts a gridManager, updates the matrix and totalCount
        %parameters of the gridManager based on the mutation parameters
        function mutateGeneration(obj, gridManager)
            if obj.mutating
                if gridManager.matrixOn %plotting
                    for index = 1:numel(gridManager.matrix)
                        obj.atomicMutation(gridManager, index, gridManager.matrix(index));
                    end
                else %non-plotting
                    for type = 1:gridManager.numTypes
                        for o = 1:gridManager.totalCount(type, gridManager.timestep)
                            obj.atomicMutation(gridManager, 0, type);
                        end
                    end
                end
            end
        end
        
        %Performs an atomic mutation
        function out = atomicMutation(obj, gridManager, ind, oldType)
            out = oldType;
            if obj.mutating
                newType = 0;
                if obj.numLoci == 1 %choose new type with weighted random selection
                    num = rand();
                    while num > 0
                        newType = newType + 1;
                        num = num - obj.mutationMatrix(newType, oldType);
                    end
                else %mutate each allele seperately
                    for i = 0:(obj.numLoci-1)
                        allele = obj.getNthAllele(oldType - 1, i);
                        num = rand();
                        newAllele = -1;
                        while num > 0
                            newAllele = newAllele + 1;
                            num = num - obj.mutationMatrix(newAllele + 1, allele + 1);
                        end
                        newType = newType + newAllele*(2^i);
                    end
                    newType = newType + 1;
                end
                gridManager.mutate(ind, oldType, newType);
                out = newType;
            end
        end
        
        
        %% recombination
        
        %Performs a generational recombination
        function recombineGeneration(obj, gridManager)
            if obj.mutating && obj.recombining
                if gridManager.matrixOn %plotting
                    for index = 1:numel(gridManager.matrix)
                        obj.atomicRecombination(gridManager, index, gridManager.matrix(index));
                    end
                else %non-plotting
                    for type = 1:gridManager.numTypes
                        for o = 1:gridManager.totalCount(type, gridManager.timestep)
                            obj.atomicRecombination(gridManager, 0, type);
                        end
                    end
                end
            end
        end
        
        
        
        %Performs an atomic recombination by selecting a sister cell/sister
        %type and recombining the two
        function out = atomicRecombination(obj, gridManager, ind, oldType)
            out = oldType;
            if obj.mutating && obj.recombining && (rand() < obj.recombinationNumber)
                if gridManager.matrixOn && gridManager.spatialOn %limit possible recombination targets to neighbors
                    [a, b] = ind2sub(size(gridManager.matrix), ind);
                    neighbors = gridManager.getNeighbors(a, b);
                    for i = 1:size(neighbors,2)
                        %remove all unoccupied neighbors
                        if gridManager.matrix(neighbors(1,i), neighbors(2,i)) == 0
                            neighbors = [neighbors(:,1:i-1) neighbors(:,i+1:end)];
                        end
                        if isempty(neighbors)
                            return; %abort if no non-0 neighbors
                        end
                        neighbor = neighbors(:, randi(size(neighbors,2)));
                        otherType = gridManager.matrix(neighbor(1), neighbor(2));
                    end
                else
                	otherType = gridManager.weightedSelection(gridManager.totalCount(:,end));
                end
                newType = obj.recombine(oldType, otherType);
                gridManager.mutate(ind, oldType, newType);
                out = newType;
            end
        end
        
        %Computes the type of the offspring by performing a recombination
        %between the parentType and the otherType
        function type = recombine(obj, parentType, otherType)
            num1 = parentType - 1; 
            num2 = otherType - 1;
            newNum1 = 0; newNum2 = 0;
            crossover = randi(obj.numLoci);
            for bit = 1:obj.numLoci
                if bit < crossover
                    %crossover!
                    newNum1 = bitset(newNum1, bit, bitget(num2, bit));
                    newNum2 = bitset(newNum2, bit, bitget(num1, bit));
                else
                    newNum1 = bitset(newNum1, bit, bitget(num1, bit));
                    newNum2 = bitset(newNum2, bit, bitget(num2, bit));
                end
            end
            if rand() < 0.5
                type = newNum1 + 1;
                otherType = newNum2 + 1;
            else
                type = newNum2 + 1;
                otherType = newNum1 + 1;
            end
        end

            
          
        %get the nth allele in a type (whether nth bit of number is 0 or 1)
        function [val] = getNthAllele(obj, x, n)
            val = bitand(bitshift(x,-n),1);
        end
        
    end

end