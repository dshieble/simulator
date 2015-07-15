%This class handles the mutations and recombinations of elements in the matrix. When >1 loci
%are selected, this class also converts types to their binary allele
%strings via the conversion allele_n = nth bit of (num-1) (0 indexed)

classdef MutationManager < handle
    
    properties
        num_loci;
        mutation_matrix;
        mutating;
        recombining;
    end
    
    methods (Access = public)
        
        function obj = MutationManager(parameter_manager)
            obj.num_loci = parameter_manager.num_loci;
            obj.mutation_matrix = parameter_manager.mutation_matrix;
            obj.mutating = parameter_manager.mutating;
            obj.recombining = parameter_manager.recombination;
        end
        
        %Accepts a grid_manager, updates the matrix and total_count
        %parameters of the grid_manager based on the mutation parameters
        function mutate(obj, grid_manager)
            matrix = grid_manager.matrix;
            if obj.mutating
                if grid_manager.plot_grid %Mutate each cell individually
                    for i = 1:numel(matrix)
                        type = matrix(i)-1;
                        new_type = 0;
                        if type >= 0
                            if obj.num_loci == 1 %choose new type with weighted random selection
                                num = rand();
                                while num > 0
                                    new_type = new_type + 1;
                                    num = num - obj.mutation_matrix(new_type, matrix(i));
                                end
                            else %mutate each allele seperately
                                for j = 0:(obj.num_loci-1)
                                    allele = obj.get_nth_allele(type, j);
                                    num = rand();
                                    new_allele = -1;
                                    while num > 0
                                        new_allele = new_allele + 1;
                                        num = num - obj.mutation_matrix(new_allele + 1, allele + 1);
                                    end
                                    new_type = new_type + new_allele*(2^j);
                                end
                                new_type = new_type + 1;
                            end
                            matrix(i) = new_type;
                        end
                    end
                    grid_manager.matrix = matrix;
                    for i = 1:grid_manager.num_types
                        grid_manager.total_count(i, grid_manager.timestep) = numel(find(grid_manager.matrix == i));
                    end
                else %non-plotting
                    gen_vec = zeros(1, grid_manager.num_types);
                    if obj.num_loci == 1
                        for i = 1:grid_manager.num_types
                            gen_vec = gen_vec + ...
                                mnrnd(grid_manager.total_count(i, grid_manager.timestep), obj.mutation_matrix(:,i));
                        end
                        
                    elseif obj.num_loci > 1 %currently written with the assumption that 2^num_loci is close to numel(population)
                        gen_vec = grid_manager.total_count(:, grid_manager.timestep);
                        for i = 1:grid_manager.num_types
                            for j = 1:grid_manager.total_count(i, grid_manager.timestep)
                                organism = i - 1;
                                for k = 1:log2(grid_manager.num_types)
                                    if bitget(organism, k) %if allele is 1
                                        obj.mutation_matrix(1,2)
                                        if rand() < obj.mutation_matrix(1,2)
                                            organism = bitset(organism, k,0);
                                        end
                                    else %if allele is 0
                                        if rand() < obj.mutation_matrix(2,1)
                                            obj.mutation_matrix(2,1)
                                            organism = bitset(organism, k, 1);
                                        end
                                    end
                                end
                                assert(organism<=grid_manager.num_types);
                                if i ~= organism + 1
                                end
                                gen_vec(i) = gen_vec(i) - 1;
                                gen_vec(organism + 1) = gen_vec(organism + 1) + 1;
                            end
                        end
                    end
                    grid_manager.total_count(:, grid_manager.timestep) = gen_vec;
                end
            end
        end
        
        %Performs a generational recombination
        function generational_recombination(obj, grid_manager)
            if obj.mutating && obj.recombining && obj.num_loci > 1
                if grid_manager.plot_grid
                    matrix = grid_manager.matrix;
                else
                    matrix = [];
                    for i = 1:grid_manager.num_types
                        matrix = [matrix repmat(i, 1, grid_manager.total_count(i, grid_manager.timestep))];
                    end
                    matrix = [matrix zeros(1,numel(grid_manager.matrix) - sum(grid_manager.total_count(:, grid_manager.timestep)))];
                end
                
                indices = 1:numel(matrix);
                indices = indices(matrix(:) > 0);
                indices = indices(randperm(numel(indices)));
                if mod(numel(indices),2) == 1
                    indices(end) = [];
                end
                for i = 1:2:numel(indices)
                    ind_1 = indices(i); ind_2 = indices(i+1);
                    
                    assert((matrix(ind_1)>0) && (matrix(ind_2)>0))
                    
                    num_1 = matrix(ind_1) - 1; num_2 = matrix(ind_2) - 1;
                    if num_1 ~= num_2
                        
                        new_num_1 = 0; new_num_2 = 0;
                        crossover = randi(obj.num_loci);
                        for bit = 1:obj.num_loci
                            if bit < crossover
                                new_num_1 = bitset(new_num_1, bit, bitget(num_2, bit));
                                new_num_2 = bitset(new_num_2, bit, bitget(num_1, bit));
                            else
                                new_num_1 = bitset(new_num_1, bit, bitget(num_1, bit));
                                new_num_2 = bitset(new_num_2, bit, bitget(num_2, bit));
                            end
                        end
                        %fprintf('1 - %s 2 - %s 1_new - %s 2_new - %s\n', dec2bin(num_1), dec2bin(num_2), dec2bin(new_num_1), dec2bin(new_num_2));
                    else
                        new_num_1 = num_1; new_num_2 = num_2;
                    end
                    matrix(ind_1) = new_num_1 + 1;
                    matrix(ind_2) = new_num_2 + 1;
                end
                if grid_manager.plot_grid
                    grid_manager.matrix = matrix;
                end
                for i = 1:grid_manager.num_types
                	grid_manager.total_count(i, grid_manager.timestep) = numel(find(matrix == i));
                end
            end
        end
        
        %get the nth allele in a type (whether nth bit of number is 0 or 1)
        function [val] = get_nth_allele(obj, x, n)
            val = bitand(bitshift(x,-n),1);
        end
        
    end

end