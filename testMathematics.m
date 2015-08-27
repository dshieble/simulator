
function testMathematics()
    % This file is the analytical testing wrapper for the population dynamics
    % simulator. The tests contained in this file examine whether the Models
    % produce the expected theoretical behavior.
    moranTest1();
    wrightTest1();
    wrightTest2();
    moranTest2();
    expTest();
    logTest();
end

function moranTest1()
    %Moran (No Mutation)
    %Propability of Fixation
    %Test the basic moran model with equal fitness values
    birthRate = [1 1];
    MM = MutationManager(0, [0.99 0.01; 0.01 0.99], 1, 0, 0);
    spatialOn = 0;
    edgesOn = randi(2) - 1;
    for matrixOn = 0:1
        popSize = 100;
        numRuns = 5*popSize;
        moranResult = zeros(1, numRuns);
        for i = 1:numRuns
            moranManager = GridManagerMoran(popSize, [(1) (popSize - 1)], MM, matrixOn, spatialOn, edgesOn, birthRate, 0);
            h = 0;
            while ~h
                [c, h] = moranManager.getNext();
            end
            moranResult(i) = find(moranManager.totalCount(:,end));
        end
        fprintf('For matrixOn = %d\n', matrixOn);
        fprintf('Moran (No Mutation): Fixation in %d out of %d runs.\n', sum(moranResult == 1), numRuns);
    end
end

function wrightTest1()
    %Wright (No Mutation)
    %Propability of Fixation
    %Test the basic wright model with equal fitness values
    fitness = [1 1];
    MM = MutationManager(0, [0.99 0.01; 0.01 0.99], 1, 0, 0);
    spatialOn = 0;
    edgesOn = randi(2) - 1;
    for matrixOn = 0:1
        popSize = 100;
        numRuns = 5*popSize;
        wrightResult = zeros(1, numRuns);
        for i = 1:numRuns
            wrightManager = GridManagerWright(popSize, [(1) (popSize - 1)], MM, matrixOn, spatialOn, edgesOn,  fitness, 0);
            h = 0;
            while ~h
                [c, h] = wrightManager.getNext();
            end
            wrightResult(i) = find(wrightManager.totalCount(:,end));
        end
        fprintf('For matrixOn = %d\n', matrixOn);
        fprintf('Wright-Fisher (No Mutation): Fixation in %d out of %d runs.\n', sum(wrightResult == 1), numRuns);
    end
end


function wrightTest2()
    %Wright-Fisher (Probability of Beneficial Mutation Fixation)
    %Test the wright fisher model with non-equal fitness values to test
    %fixation
    MM = MutationManager(0, [0.99 0.01; 0.01 0.99], 1, 0, 0);
    spatialOn = 0;
    edgesOn = randi(2) - 1;
    N = [36];%100, 400, 625];
    s = [0.005, 0.01, 0.05, 0.1];
    fitness = [1.005 1; 1.01 1; 1.05 1; 1.1 1];
    for matrixOn = 0:1
        wrightNumFix = [];
        for i = 1:length(s)
            f = fitness(i,:);
            for j = 1:length(N)
                pfix = (1-exp(-2.*s(i)))/(1-exp(-2.*N(j).*s(i)));
                count = 0;
                for k = 1:round(100/pfix)
                    wrightManager = GridManagerWright(N(j), [(1) (N(j) - 1)], MM, matrixOn, spatialOn, edgesOn, f, 0);
                    h = 0;
                    while ~h
                        [c, h] = wrightManager.getNext();
                    end
                    count = count + (wrightManager.totalCount(1, wrightManager.timestep)>0);
                end
                wrightNumFix = [wrightNumFix count];
            end
        end
        fprintf('For matrixOn = %d\n', matrixOn);
        for i = 1:length(wrightNumFix)
            fprintf('Wright-Fisher (Probability of Beneficial Mutation Fixation): Fixation in %d out of 10/pfix runs for s = %1.2d.\n', wrightNumFix(i), s(i));
        end
    end
end



function moranTest2()
    %Moran (Probability of Beneficial Mutation) 
    %Test the Moran model with non-equal fitness values to test
    %fixation
    MM = MutationManager(0, [0.99 0.01; 0.01 0.99], 1, 0, 0);
    spatialOn = 0;
    edgesOn = randi(2) - 1;
    N = [36];
    r = [1.005 1.01 1.05 1.1];
    br = [1.005 1; 1.01 1; 1.05 1; 1.1 1];
    for matrixOn = 0:1
        moranNumFix = [];
        for i = 1:length(br)
            b = br(i,:);
            for j = 1:length(N)
                pfix = (1-(1/r(i)))/(1-(1/(r(i)^N(j))));
                count = 0;
                for k = 1:round(10/pfix)
                    moranManager = GridManagerMoran(N(j), [(1) (N(j) - 1)], MM, matrixOn, spatialOn, edgesOn, b, 0);
                    h = 0;
                    while ~h
                        [c, h] = moranManager.getNext();
                    end
                    count = count + (moranManager.totalCount(1, moranManager.timestep)>0);
                end
                moranNumFix = [moranNumFix count];
            end
        end
        fprintf('For matrixOn = %d\n', matrixOn);
        for j = 1:length(moranNumFix)
            fprintf('Moran (Probability of Beneficial Mutation Fixation): Fixation in %d out of 10/pfix runs for s = %d.\n', moranNumFix(j), r(j));
        end
    end
end



function expTest()
    %Tests the GridManagerExp class to ensure that growth is handled
    %properly
    MM = MutationManager(0, [0.99 0.01; 0.01 0.99], 1, 0, 0);
    spatialOn = 0;
    edgesOn = randi(2) - 1;
    Ninit = [1 0];
    Ntot = 400;
    birth = [1 1];
    death = [0.01 0.01];
    counts = cell(1,100);
    for matrixOn = 0:1
        for i = 1:100
            expManager = GridManagerExp(Ntot, Ninit, MM, matrixOn, spatialOn, edgesOn, birth, death);
            h = 0;
            counts{i} = [];
            t = 1;
            while ~h && t<30
                [c, h] = expManager.getNext();
                t = expManager.timestep;
                counts{i} = [counts{i} sum(expManager.totalCount(:,t))];
            end
        end
        figure;
        subplot(2,1,1)
        r = birth(1) - death(1);
        t = 1:10;
        T = exp(r.*t.*log(2));
        T(T>Ntot) = Ntot;
        plot(T);
        title(sprintf('Exponential Theoretical for matrixOn = %d', matrixOn));
    
        subplot(2,1,2)
        for j = 1:100
            plot(counts{j});
            hold on;
        end
        title(sprintf('Exponential Experimental for matrixOn = %d', matrixOn));
    end
end

function logTest()
    %Tests the GridManagerLog class to ensure that growth is handled
    %properly
    MM = MutationManager(0, [0.99 0.01; 0.01 0.99], 1, 0, 0);
    spatialOn = 0;
    edgesOn = randi(2) - 1;
    Ninit = [1 0];
    Ntot = 225;
    birth = [1 1];
    death = [0.01 0.01];
    num_lines = 100;
    counts = cell(1,num_lines);
    num_iter = 10;
    for matrixOn = 0:1
        for i = 1:num_lines
            logManager = GridManagerLogistic(Ntot, Ninit, MM, matrixOn, spatialOn, edgesOn, birth, death);
            h = 0;
            counts{i} = [];
            t = 1;
            for iter = 1:num_iter %doesn't terminate right now
                [c, h] = logManager.getNext();
                t = logManager.timestep;
                counts{i} = [counts{i} sum(logManager.totalCount(:,t))];
            end
        end
        figure;
        subplot(2,1,1)
        r = birth(1) - death(1);
        t = 1:num_iter;
        T = Ntot*exp(r.*t.*log(2))./(Ntot+exp(r.*t.*log(2)) - 1);
        T(T>Ntot) = Ntot;
        plot(T);
        title(sprintf('Logistic Theoretical for matrixOn = %d', matrixOn));

        subplot(2,1,2)
        for j = 1:num_lines
            plot(counts{j});
            hold on;
        end
        title(sprintf('Logistic Experimental for matrixOn = %d', matrixOn));

    end
end
