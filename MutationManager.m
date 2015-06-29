%This class handles the mutations of elements in the matrix. When >1 loci
%are selected, this class also converts types to their binary allele
%strings via the converstion allele_n = nth bit of (num-1) (0 indexed)

classdef MutationManager < handle
    
    properties
        parameter_manager;
    end
    
    methods (Access = public)
        
        function obj = MutationManager(parameter_manager)
            obj.parameter_manager = parameter_manager;
        end
        
        %Elements in the matrix are represented as 
        function [matrix, c] = mutate(obj, grid_manager)
            matrix = grid_manager.matrix;
            c = [];
            for i = 1:numel(matrix)
                type = matrix(i)-1;
                new_type = 0;
                if type >= 0
                    if obj.parameter_manager.num_loci == 1
                        num = rand();
                        while num > 0
                            new_type = new_type + 1;
                            num = num - obj.parameter_manager.mutation_matrix(new_type, matrix(i));
                        end
                    else
                        for j = 0:(obj.parameter_manager.num_loci-1)
                            allele = obj.get_nth_allele(type, j);
                            num = rand();
                            new_allele = -1;
                            while num > 0
                                new_allele = new_allele + 1;
                                num = num - obj.parameter_manager.mutation_matrix(new_allele + 1, allele + 1);
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
            grid_manager.matrix = matrix;
        end
        
        
        function [val] = get_nth_allele(obj, x, n)
            val = bitand(bitshift(x,-n),1);
        end
        
    end

end