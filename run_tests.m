%This file is a testing wrapper for the population dynamics simulater

%% Section 1 - Propability of Fixation for Wright Fisher and Moran
%Initialize some basic variables that are helpful for making GridManagers
pop_size = 100;
edges_on = 1; 
spatial_on = 0;
PM_fake = struct(); %A struct that performs the same function as a parameter manager
PM_fake.mutating = 0;
PM_fake.mutation_matrix = [0.99 0.01; 0.01 0.99];
PM_fake.num_loci = 1;
PM_fake.recombination = 0;
PM_fake.recombination_number = 0;
MM = MutationManager(PM_fake); %make a mutation manager with the fake parameter_manager
plot_grid = 0;
plottingParams = struct(); plottingParams.plot_type = 'total_count'; plottingParams.plot_log = 0;

%% Test 1 -> Moran (No Mutation)
%Test the basic moran model with equal fitness values
birth_rate = [1 1];
num_runs = 10*pop_size;
moran_result = zeros(1, num_runs);
for plot_grid = 0:1
    for i = 1:num_runs
        moran_manager = GridManagerMoran(pop_size, [(1) (pop_size - 1)], MM, plot_grid, plottingParams, spatial_on, edges_on, birth_rate, 0);
        h = 0;
        while ~h
            [~, ~, t, h] = moran_manager.get_next();
        end
        
        moran_result(i) = find(moran_manager.total_count(:,end));
    end
    fprintf('Moran (No Mutation): Fixation in %d out of %d runs.\n', sum(moran_result == 1), num_runs);
end

%% Test 2 -> Wright-Fisher (No Mutation)
%test the basic Wright Fisher model with equal fitness values
fitness = [1 1];
num_runs = 10*pop_size;
wright_result = zeros(1,num_runs);
for plot_grid = 0:1
    for i = 1:num_runs
        wright_manager = GridManagerWright(pop_size, [(1) (pop_size - 1)], MM, plot_grid, plottingParams, spatial_on, edges_on,  fitness, 0);
        h = 0;
        while ~h
            [~, ~, ~, h] = wright_manager.get_next();
        end
        wright_result(i) = find(wright_manager.total_count(:,end));
    end
    fprintf('Wright-Fisher (No Mutation): Fixation in %d out of %d runs.\n', sum(wright_result == 1), num_runs);
end

%% Test 3 -> Wright-Fisher (Probability of Beneficial Mutation Fixation)
%Test the wright fisher model with non-equal fitness values to test
%fixation

% %simulating 100 replicates of N = 2500 will take a very very very long time
N = [36];%100, 400, 625];
s = [0.005, 0.01, 0.05, 0.1];
fitness = [1.005 1; 1.01 1; 1.05 1; 1.1 1];
for plot_grid = 0:1
    wright_num_fix = [];
    for i = 1:length(s)
        f = fitness(i,:);
        for j = 1:length(N)
            pfix = (1-exp(-2.*s(i)))/(1-exp(-2.*N(j).*s(i)));
            count = 0;
            for k = 1:round(100/pfix)
                wright_manager = GridManagerWright(N(j), [(1) (N(j) - 1)], MM, plot_grid, plottingParams, spatial_on, edges_on, f, 0);
                h = 0;
                while ~h
                    [~, ~, ~, h] = wright_manager.get_next();
                end
                count = count + (wright_manager.total_count(1, wright_manager.timestep)>0);
            end
            wright_num_fix = [wright_num_fix count];
        end
    end
    for i = 1:length(wright_num_fix)
        fprintf('Wright-Fisher (Probability of Beneficial Mutation Fixation): Fixation in %d out of pfix/100 runs for s = %1.2d.\n', wright_num_fix(i), s(i));
    end
end
%% Test 4 -> Moran (Probability of Beneficial Mutation) 
%Test the Moran model with non-equal fitness values to test
%fixation

% %simulating 100 replicates of N = 2500 will take a very long time
N = [36];%100, 400, 625];
r = [1.005 1.01 1.05 1.1];
br = [1.005 1; 1.01 1; 1.05 1; 1.1 1];
for plot_grid = 0:1
    moran_num_fix = [];
    for i = 1:length(br)
        b = br(i,:);
        for j = 1:length(N)
            pfix = (1-(1/r(i)))/(1-(1/(r(i)^N(j))));
            count = 0;
            for k = 1:round(100/pfix)
                moran_manager = GridManagerMoran(N(j), [(1) (N(j) - 1)], MM, plot_grid, plottingParams, spatial_on, edges_on, b, 0);
                h = 0;
                while ~h
                    [~, ~, ~, h] = moran_manager.get_next();
                end
                count = count + (moran_manager.total_count(1, moran_manager.timestep)>0);
            end
            moran_num_fix = [moran_num_fix count];
        end
    end

    for j = 1:length(moran_num_fix)
        fprintf('Moran (Probability of Beneficial Mutation Fixation): Fixation in %d out of pfix/100 runs for s = %d.\n', moran_num_fix(j), r(j));
    end
end
%% Test 5 -> Exponential
% Test and plot the exponential model

Ninit = [1 0];
N_tot = 900;
birth = [1 1];
death = [0.01 0.01];
counts = cell(1,100);
for plot_grid = 0:1
    for i = 1:100
        exp_manager = GridManagerExp(N_tot, Ninit, MM, plot_grid, plottingParams, spatial_on, edges_on, birth, death);
        h = 0;
        counts{i} = [];
        t = 1;
        while ~h && t<30
            [~, ~, t, h] = exp_manager.get_next();
            counts{i} = [counts{i} sum(exp_manager.total_count(:,t))];
        end
    end
    figure;
    subplot(2,1,1)
    r = birth(1) - death(1);
    t = 1:10;
    T = exp(r.*t.*log(2));
    T(T>N_tot) = N_tot;
    plot(T);
    title('Exponential Theoretical');

    subplot(2,1,2)
    for j = 1:100
        plot(counts{j});
        hold on;
    end
    title('Exponential Experimental');
end

%% Test 6 -> Logistic
% Test and plot the logistic model

Ninit = [1 0];
N_tot = 225;
birth = [1 1];
death = [0.01 0.01];
num_lines = 100;
counts = cell(1,num_lines);
num_iter = 10;
for plot_grid = 0:1
    for i = 1:num_lines
        log_manager = GridManagerLogistic(N_tot, Ninit, MM, plot_grid, plottingParams, spatial_on, edges_on, birth, death);
        h = 0;
        counts{i} = [];
        t = 1;
        for iter = 1:num_iter %doesn't terminate right now
            [~, ~, t, h] = log_manager.get_next();
            counts{i} = [counts{i} sum(log_manager.total_count(:,t))];
        end
    end
    figure;
    subplot(2,1,1)
    r = birth(1) - death(1);
    t = 1:num_iter;
    T = N_tot*exp(r.*t.*log(2))./(N_tot+exp(r.*t.*log(2)) - 1);
    T(T>N_tot) = N_tot;
    plot(T);
    title('Logistic Theoretical');

    subplot(2,1,2)
    for j = 1:num_lines
        plot(counts{j});
        hold on;
    end
    title('Logistic Experimental');
end
