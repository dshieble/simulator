function out = AutomatedSimulator(GridManagerClass, Ninit, p1, p2, varargin)
    % This file is an automated front end for the simulator program
    % mutating - 0
    % numLoci - 0
    % mutationMatrix - [0.99 0.01; 0.01 0.99]
    % recombinationNumber - 0
    % matrixOn - 0
    % totalPopSize - 2500
    % spatialOn - 1
    % edgesOn - 1
    % maxIterations - 25
    % return - totalCount, matrix, ageDist
    
    %Example: 
    %AutomatedSimulator('GridManagerMoran', [450 450], [1 1], [0.01 0.01], 'totalPopSize', 900)
    p = inputParser;

    addRequired(p,'GridManagerClass',@(s) exist(s, 'file'));
    addRequired(p,'Ninit',@isPositiveInteger);
    addRequired(p,'p1',@isNumber);
    addRequired(p,'p2',@isNumber);

    addParameter(p,'mutating', 0, @(x) x == 0 || x == 1);
    addParameter(p,'mutationMatrix', [], @(M) size(M,1) == size(M,2) && isPositiveNumber(M));
    addParameter(p,'numLoci', 1, @isPositiveInteger);
    addParameter(p,'recombinationNumber', 0, @isPositiveNumber);
    addParameter(p,'matrixOn', 0, @(x) x == 0 || x == 1);
    addParameter(p,'totalPopSize', 2500, @isPositiveInteger);
    addParameter(p,'returnType', 'totalCount', @(x) any(validatestring(x,{'totalCount', 'matrix', 'ageDist'})));
    addParameter(p,'spatialOn', 0, @(x) x == 0 || x == 1);
    addParameter(p,'edgesOn', 0, @(x) x == 0 || x == 1);
    addParameter(p,'maxIterations', 25,  @isPositiveInteger);

    parse(p,GridManagerClass, Ninit, p1, p2, varargin{:})
    assert(length(p.Results.Ninit) == length(p.Results.p1) && length(p.Results.p1) == length(p.Results.p2), 'ASSERTION ERROR: Lengths of Ninit, p1 and p2 must be the same!');
    
    recombining = (p.Results.recombinationNumber > 0);
    if isempty(p.Results.mutationMatrix)
        if ~p.Results.mutating || p.Results.numLoci == 1
            mutationMatrix = generateMutationMatrix(numel(p.Results.Ninit));
        else
        	mutationMatrix = generateMutationMatrix(2);
        end
    else
        mutationMatrix = p.Results.mutationMatrix;
    end
    
    if p.Results.mutating && p.Results.numLoci > 1
        assert(2^p.Results.numLoci == length(p.Results.Ninit), 'ASSERTION ERROR: Number of Loci and Number of Types is not consistent.');
        assert(all(size(mutationMatrix) == [2 2]), 'ASSERTION ERROR: Mutation matrix must be 2x2 when numLoci > 2.');
    else
    	assert(length(p.Results.Ninit) == size(mutationMatrix,1), 'ASSERTION ERROR: The sides of mutation matrix are the incorrect length.');
    end
    assert(p.Results.matrixOn || ~strcmp(p.Results.returnType, 'ageDist'), 'ASSERTION ERROR: In order to track ages, we must turn the matrix on.');
    
    MM = MutationManager(p.Results.mutating, mutationMatrix, p.Results.numLoci, recombining, p.Results.recombinationNumber);
    
    constructor = str2func(GridManagerClass);
    gridManager = constructor(...
        p.Results.totalPopSize,...
        p.Results.Ninit,...
        MM,...
        p.Results.matrixOn,...
        p.Results.spatialOn,...
        p.Results.edgesOn,...
        p.Results.p1,...
        p.Results.p2);
    
    matCell = {};
    for iter = 1:p.Results.maxIterations
    	[c, halt] = gridManager.getNext();
        if strcmp(p.Results.returnType, 'matrix')
            matCell{iter} = gridManager.matrix;
        end
        if halt
            break;
        end
    end
    if iter >= p.Results.maxIterations
        fprintf('Max number of iterations, %d, reached. You can set this by setting the maxIterations parameter. \n', p.Results.maxIterations);
    end
    switch p.Results.returnType
        case 'totalCount'
            out = gridManager.totalCount;
        case 'matrix'
        	out = matCell;
        case 'ageDist'
            out = gridManager.ageStructure;
    end


    function out = isNumber(n)
        %verifies that input is a vector of numbers
        out = 1;
        if any(~isnumeric(n))
            out = 0;
        elseif any(isnan(n))
            out = 0;
        end
    end

    function out = isPositiveNumber(n)
        %verifies that input is a vector of positive numbers
        out = 1;
        if ~isNumber(n)
            out = 0;
        elseif any(n < 0) %negative
            out = 0;
        end 
    end

    function out = isPositiveInteger(n)
        %verifies that input is a vector of positive integers
        out = 1;
        if ~isPositiveNumber(n)
            out = 0;
        elseif any(round(n) ~= n) %non-integer
            out = 0;
        end 
    end

    function mm = generateMutationMatrix(dim)
        mm = zeros(dim);
        for i = 1:dim
            for j = 1:dim
                if i == j
                    mm(i,j) = 1 - 0.01*(dim-1);
                else
                    mm(i,j) = 0.01;
                end
            end
        end
    end

end
