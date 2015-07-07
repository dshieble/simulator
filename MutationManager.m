%do plot_grid stuff





%This class handles the mutations of elements in the matrix. When >1 loci
%are selected, this class also converts types to their binary allele
%strings via the converstion allele_n = nth bit of (num-1) (0 indexed)

classdef MutationManager < handle
    
    properties
        num_loci;
        mutation_matrix;
        mutating;
    end
    
    methods (Access = public)
        
        function obj = MutationManager(parameter_manager)
            obj.num_loci = parameter_manager.num_loci;
            obj.mutation_matrix = parameter_manager.mutation_matrix;
            obj.mutating = parameter_manager.mutating;
        end
        
        %Elements in the matrix are represented as
        function matrix = mutate(obj, grid_manager)
            matrix = grid_manager.matrix;
            if obj.mutating
                if grid_manager.plot_grid
                    for i = 1:numel(matrix)
                        type = matrix(i)-1;
                        new_type = 0;
                        if type >= 0
                            if obj.num_loci == 1
                                num = rand();
                                while num > 0
                                    new_type = new_type + 1;
                                    num = num - obj.mutation_matrix(new_type, matrix(i));
                                end
                            else
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
                            if type ~= new_type
                                matrix(i) = new_type;
                            end
                        end
                    end
                else %non-plotting
                    gen_vec = zeros(1, grid_manager.num_types);
                    if obj.num_loci == 1
                        for i = 1:grid_manager.num_types
                            gen_vec = gen_vec + ...
                                mnrnd(grid_manager.total_count(i, grid_manager.timestep), obj.mutation_matrix(:,i));
                        end
                        
                    elseif obj.num_loci > 1 %currently written with the assumption that 2^num_loci is close to numel(population)
                        %TODO: 1 -> 0 and 2 -> 1 in the mutation matrix
                        gen_vec = grid_manager.total_count(:, grid_manager.timestep);
                        for i = 1:grid_manager.num_types
                            for j = 1:grid_manager.total_count(i, grid_manager.timestep)
                                organism = i - 1;
                                for k = 1:log2(grid_manager.num_types)
                                    if bitget(organism, k) %if allele is 1
                                        if rand() < obj.mutation_matrix(1,2)
                                            organism = bitset(organism, k,0);
                                        end
                                    else %if allele is 0
                                        if rand() < obj.mutation_matrix(2,1)
                                            organism = bitset(organism, k, 1);
                                        end
                                    end
                                end
                                assert(organism<=grid_manager.num_types);
                                gen_vec(i) = gen_vec(i) - 1;
                                gen_vec(organism + 1) = gen_vec(organism + 1) + 1;
                            end
                        end
                    end
                    grid_manager.total_count(:, grid_manager.timestep) = gen_vec;
                end
            end
        end
        
        
        function [val] = get_nth_allele(obj, x, n)
            val = bitand(bitshift(x,-n),1);
        end
        
    end

end