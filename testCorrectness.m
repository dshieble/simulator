%TODO: Make another test file for the analytical tests
%TODO: Test GUI Callbacks


% runtests('correctnessTests.m')
function tests = testCorrectness
    tests = functiontests(localfunctions);
end

function testGridManagerAbstract(testCase)
    %Tests the matrix methods of the GridManagerAbstract class
    %GridManagerAbstract(maxSize, Ninit, mutationManager, matrixOn, spatialOn, edgesOn, p1, p2)

    MM = MutationManager(0, [0.99 0.01; 0.01 0.99], 1, 0, 0);
    mat = [2     0     3     4     4;...
           4     0     4     0     4;...
           5     0     5     4     4;...
           2     1     4     1     2;...
           0     1     5     4     3];
    %edges on
    gridManager = GridManagerLogistic(25, [1 0 0 0 0], MM, 1, 1, 1, ones(1,5), zeros(1,5));
    gridManager.resetMatrix(mat);
    
    verifyEqual(testCase,gridManager.matrix(gridManager.getFree), 0);
    verifyEqual(testCase,gridManager.matrix(gridManager.getRandomOfType(2)), 2);
    verifyEqual(testCase,gridManager.matrix(gridManager.getRandomOfType(5)), 5);
    verifyEqual(testCase,gridManager.getRandomOfType(6), -1);
    verifyEqual(testCase,gridManager.matrixDistance(7, 15), 4);
    verifyEqual(testCase,gridManager.getCenter(), 13);
    
    verifyEqual(testCase,gridManager.getNearestOfType(1,1,3), 11);
    verifyEqual(testCase,gridManager.getNearestOfType(2,1,4), 12);
    verifyEqual(testCase,gridManager.getNearestFree(5,3), 5);

    gridManager = GridManagerLogistic(25, [1 0 0 0 0], MM, 1, 1, 0, ones(1,5), zeros(1,5));
    gridManager.resetMatrix(mat);    
    verifyEqual(testCase,gridManager.getNearestOfType(2,1,4), 22);
    verifyEqual(testCase,gridManager.matrixDistance(7, 15), 3);
    verifyEqual(testCase,gridManager.isHomogenous(), false);

    gridManager.resetMatrix(ones(5));    
    verifyEqual(testCase,gridManager.isHomogenous(), false);

end


function testAutomatedSimulator(testCase)
    %Tests that the automated simulator runs without error
	AutomatedSimulator('GridManagerLogistic', [1 1], [1 1], [0.01 0.01], 'totalPopSize', 900);
    AutomatedSimulator('GridManagerMoran', [25 200], [1 1], [0.01 0.01], 'totalPopSize', 225);
	AutomatedSimulator('GridManagerExp', [1 1 0 1 0], [1 1 0 0 0], [0.01 0.01 0.1 0.01 0.01], 'totalPopSize', 101);
    AutomatedSimulator('GridManagerWright', [12 4], [1 1], [0.01 0.01], 'totalPopSize', 16);
    %Spatial
    AutomatedSimulator('GridManagerWright', [4 4 4 4], [1 1 1 1], [0 0 0 0], 'totalPopSize', 16, 'matrixOn', 1, 'spatialOn', 1, 'edgesOn', 1);
    AutomatedSimulator('GridManagerMoran', [4 4 4 4], [1 1 1 1], [0 0 0 0], 'totalPopSize', 16, 'matrixOn', 1, 'spatialOn', 1, 'edgesOn', 1);
    AutomatedSimulator('GridManagerLogistic', [4 0 0 0], [1 1 1 1], [0 0 0 0], 'totalPopSize', 16, 'matrixOn', 1, 'spatialOn', 1, 'edgesOn', 1);
    AutomatedSimulator('GridManagerExp', [4 0 0 0], [1 1 1 1], [0 0 0 0], 'totalPopSize', 16, 'matrixOn', 1, 'spatialOn', 1, 'edgesOn', 1);
    %No Edges
    AutomatedSimulator('GridManagerMoran', [5 5 10 5], [1 1 1 1], [0 0 0 0], 'totalPopSize', 25, 'matrixOn', 1, 'spatialOn', 1, 'edgesOn', 0);
    AutomatedSimulator('GridManagerLogistic', [4 0 0 0], [1 1 1 1], [0 0 0 0], 'totalPopSize', 16, 'matrixOn', 1, 'spatialOn', 1, 'edgesOn', 0);
    AutomatedSimulator('GridManagerExp', [4 0 0 0], [1 1 1 1], [0 0 0 0], 'totalPopSize', 16, 'matrixOn', 1, 'spatialOn', 1, 'edgesOn', 0);
    %Mutation
    AutomatedSimulator('GridManagerExp', [1 1 0 1 0], [1 1 0 0 0], [0.01 0.01 0.1 0.01 0.01], 'totalPopSize', 101, 'mutating', 1);
    AutomatedSimulator('GridManagerLogistic', [1 1 0 1 0], [1 1 0 0 0], [0.01 0.01 0.1 0.01 0.01], 'totalPopSize', 101, 'mutating', 1, 'mutationMatrix', ones(5)/5);
    AutomatedSimulator('GridManagerWright', [100 0 0 0], [1 1 0 0], [0 0 0 0], 'matrixOn', 1, 'totalPopSize', 100, 'mutating', 1, 'numLoci', 2);
    AutomatedSimulator('GridManagerMoran', [303 0 0 0], [1 1 0 0], [0 0 0 0], 'totalPopSize', 303, 'mutating', 1, 'numLoci', 2, 'mutationMatrix', ones(2)./2);
    %Recombination
    AutomatedSimulator('GridManagerExp', [1 1 0 1 0], [1 1 0 0 0], [0.01 0.01 0.1 0.01 0.01], 'totalPopSize', 101, 'mutating', 1, 'Recombination', 1);
    AutomatedSimulator('GridManagerLogistic', [1 1 0 1 0], [1 1 0 0 0], [0.01 0.01 0.1 0.01 0.01], 'totalPopSize', 101, 'mutating', 1, 'mutationMatrix', ones(5)/5,  'Recombination', 1, 'RecombinationNumber', 0.3);
    AutomatedSimulator('GridManagerWright', [100 0 0 0], [1 1 0 0], [0 0 0 0], 'matrixOn', 1, 'totalPopSize', 100, 'mutating', 1, 'numLoci', 2,  'Recombination', 1);
    AutomatedSimulator('GridManagerMoran', [303 0 0 0], [1 1 0 0], [0 0 0 0], 'totalPopSize', 303, 'mutating', 1, 'numLoci', 2, 'mutationMatrix', ones(2)./2,  'Recombination', 1, 'RecombinationNumber', 0.7);
    %Age Distribution
    AutomatedSimulator('GridManagerLogistic', [1 1], [1 1], [0.01 0.01], 'totalPopSize', 100, 'returnType', 'ageDist', 'matrixOn', 1);
    AutomatedSimulator('GridManagerMoran', [100 0], [1 1], [0.01 0.01], 'totalPopSize', 100, 'returnType', 'ageDist', 'matrixOn', 1);
    AutomatedSimulator('GridManagerWright', [0 0 6 30], [1 1 0 1], [0 0 0 0], 'totalPopSize', 36, 'returnType', 'ageDist', 'mutating', 1, 'matrixOn', 1, 'numLoci', 2);
    AutomatedSimulator('GridManagerExp', [1 1], [1 1], [0.01 0.01], 'totalPopSize', 100, 'returnType', 'ageDist', 'matrixOn', 1);
    
    %Expected Error Tests
    caughtError = @(e) ~isempty(strfind(e.message, 'ASSERTION ERROR')) || ~isempty(strfind(e.identifier, 'InputParser'));
    try 
        AutomatedSimulator('GridManagerLogistic', [1 1 1], [1 1], [0.01 0.01])
    catch e1
    	verifyEqual(testCase,caughtError(e1), true);
    end
    try 
        AutomatedSimulator('GridManagerExponential', [1 1], [1 1], [0.01 0.01], 'mutating', 1, 'mutationMatrix', [.01 .01 .01; .08 .08 .08; .01 .01 .01]);
    catch e2
    	verifyEqual(testCase,caughtError(e2), true);
    end
    try 
        AutomatedSimulator('GridManagerMoran', [1 1 1], [1 1], [0.01 0.01], 'numLoci', 0.1)
    catch e3
    	verifyEqual(testCase,caughtError(e3), true);
    end
    try 
        AutomatedSimulator('GridManagerWright', [1 1], [1 1], [0.01 0.01], 'numLoci', 0.1)
    catch e4
    	verifyEqual(testCase,caughtError(e4), true);
    end
    try 
        AutomatedSimulator('GridManagerWright', [1 1 0 1 0], [1 1 0 0 0], [0.01 0.01 0.1 0.01 0.01], 'totalPopSize', 101, 'mutating', 1, 'mutationMatrix', rand(5));
    catch e5
    	verifyEqual(testCase,caughtError(e5), true);
    end
    try 
        AutomatedSimulator('GridManagerWright', [100 0 0 0], [1 1 0 0], [0 0 0 0], 'matrixOn', 1, 'totalPopSize', 100, 'mutating', 1, 'numLoci', 2, 'mutationMatrix', rand(4));
    catch e6
    	verifyEqual(testCase,caughtError(e6), true);
    end
    try 
        AutomatedSimulator('GridManagerLogistic', [1 1], [1 1], [0.01 0.01], 'totalPopSize', 100, 'returnType', 'ageDist')
    catch e7
    	verifyEqual(testCase,caughtError(e7), true);
    end
end

function testGUICallbacks(testCase)
    
end

