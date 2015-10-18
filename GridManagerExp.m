classdef GridManagerExp < GridManagerLogExpAbstract
%This class is an implementation of the GridManager class for the
%Exponential model
%The meat of this class is in the GridManagerLogExpAbstract file

    properties (Constant)
        Name = 'Exponential';
        OverlappingGenerations = 1;
        ParamName1 = 'Birth Rate';
        ParamName2 = 'Death Rate';
        ParamBounds1 = [0 inf];
        ParamBounds2 = [0 inf];
        atCapacity = 0;
        plottingEnabled = 1;
    end
    
    methods (Access = public)
        
        function obj = GridManagerExp(dim, Ninit, mutation_manager, matrixOn, spatialOn, edgesOn, b, d)
            obj@GridManagerLogExpAbstract(dim, Ninit, mutation_manager, matrixOn, spatialOn, edgesOn, b, d);
        end

        function isSuccess = isSuccess(obj)
        	isSuccess = 1;
        end
    end
end


