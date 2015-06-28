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
                num = rand();
                new_allele = 0;
                while num > 0
                    new_allele = new_allele + 1;
                    obj.parameter_manager.mutation_matrix
                    num = num - obj.parameter_manager.mutation_matrix(new_allele, allele);
                end
                matrix(i) = new_allele;
            end

        end
    end

end