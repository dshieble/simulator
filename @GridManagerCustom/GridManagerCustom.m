classdef GridManagerCustom < GridManagerAbstract
% Welcome! This is the basic class definition and constructor file. You don't need
% to do anything to this file in order to sketch up basic models.
    
    properties (Constant)
        %The tag properties, these characterize the class itself
        Name = 'Custom';
        Generational = 1;
        Param_1_Name = 'Parameter 1';
        Param_2_Name = 'Parameter 2';
        atCapacity = 0;
        plottingEnabled = 0;
    end
    
    methods (Access = public)
        
        function obj = GridManagerCustom(dim, Ninit, mutation_manager, plot_grid, plottingParams, spatial_on, b, d)
            obj@GridManagerAbstract(dim, Ninit, mutation_manager, plot_grid, plottingParams, spatial_on, b, d);
        end
        
     end
end