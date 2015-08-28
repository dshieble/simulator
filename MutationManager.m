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
        
        %Basic Constructor for the MutationManager class
        function obj = MutationManager(mutating, mutationMatrix, numLoci, recombination, recombinationNumber)
            obj.mutating =  mutating;
            obj.mutationMatrix =  mutationMatrix;
            obj.numLoci = numLoci;
            obj.recombining = recombination;
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
        function atomicMutation(obj, gridManager, ind, oldType)
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
                gridManager.mutate(ind, oldType, newType)
            end
        end
        


            
        
        
        %Performs a generational recombination
        function recombination(obj, gridManager)
            if obj.mutating && obj.recombining && obj.numLoci > 1
                if gridManager.matrixOn
                    matrix = gridManager.matrix;
                else
                    matrix = [];
                    for i = 1:gridManager.numTypes
                        matrix = [matrix repmat(i, 1, gridManager.totalCount(i, gridManager.timestep))];
                    end
                    matrix = [matrix zeros(1,numel(gridManager.matrix) - sum(gridManager.totalCount(:, gridManager.timestep)))];
                end
                
                indices = 1:numel(matrix);
                indices = indices(matrix(:) > 0);
                indices = indices(randperm(numel(indices)));
                if mod(numel(indices),2) == 1
                    indices(end) = [];
                end
                for i = 1:2:numel(indices)
                    if rand() < obj.recombinationNumber
                        ind1 = indices(i); ind2 = indices(i+1);
                        assert((matrix(ind1)>0) && (matrix(ind2)>0))
                        num1 = matrix(ind1) - 1; 
                        num2 = matrix(ind2) - 1;
                        if num1 ~= num2
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
                        else
                            newNum1 = num1; newNum2 = num2;
                        end
                        %Change the fake Matrix as well as the actual
                        %gridManager matrix
                        matrix(ind1) = newNum1 + 1;
                        matrix(ind2) = newNum2 + 1;
                        if gridManager.matrixOn
                            gridManager.mutateMatrix(ind1, newNum1 + 1);
                            gridManager.mutateMatrix(ind2, newNum2 + 1);
                        end
                    end
                end
                tempVec = zeros(1,gridManager.numTypes);
                for i = 1:gridManager.numTypes
                    tempVec(i) = numel(find(gridManager.matrix == i));
                end
                gridManager.setTotalCount(tempVec);
            end
        end
        
        %get the nth allele in a type (whether nth bit of number is 0 or 1)
        function [val] = getNthAllele(obj, x, n)
            val = bitand(bitshift(x,-n),1);
        end
        
    end

end