classdef MutationManager < handle
    
    properties
        parameter_manager;
    end
    
    methods (Access = public)
        
        function obj = MutationManager(parameter_manager)
            obj.parameter_manager = parameter_manager;
           
        end
        
        function matrix = mutate(obj, matrix)
            for i = 1:numel(matrix)
                allele = matrix(i);
                if allele ~= 0
                    num = rand();
                    new_allele = 0;
                    while num > 0
                        new_allele = new_allele + 1;
                        num = num - obj.parameter_manager.mutation_matrix(new_allele, allele);
                    end
                    matrix(i) = new_allele;
                end
            end

        end
    end

end