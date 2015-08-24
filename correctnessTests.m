%TODO: Make tests for automated simulator (error tests)
%TODO: Make another test file for the analytical tests

% runtests('correctnessTests.m')
function tests = correctnessTests
    tests = functiontests(localfunctions);
end

function testGridManagerAbstract(testCase)
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
    verifyEqual(testCase,gridManager.matrix(gridManager.getOfType(2)), 2);
    verifyEqual(testCase,gridManager.matrix(gridManager.getOfType(5)), 5);
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
    verifyEqual(testCase,gridManager.isHomogenous(), 0);

    gridManager.resetMatrix(ones(5));    
    verifyEqual(testCase,gridManager.isHomogenous(), 0);

end

function testAutomatedSimulator(testCase)
end

function testGUICallbacks(testCase)
    
end

