%This file is a testing wrapper for the population dynamics simulater

%Non-Petri Dish Section


%% Section 1 - Propability of Fixation for Wright Fisher and Moran
pop_size = 100;
PM_fake = struct();
PM_fake.mutating = 0;
PM_fake.mutation_matrix = [0.99 0.01; 0.01 0.99];
PM_fake.num_loci = 1;
MM = MutationManager(PM_fake);
plot_grid = 0;
plottingParams = struct(); plottingParams.plot_type = 'total_count'; plottingParams.plot_log = 0;

%% Test 1 -> Moran (No Mutation)
% birth_rate = [1 1];
% num_runs = 10*pop_size;
% moran_result = zeros(1, num_runs);
% for i = 1:num_runs
%     moran_manager = GridManagerMoran(sqrt(pop_size), [(1) (pop_size - 1)], MM, plot_grid, plottingParams, birth_rate);
%     h = 0;
%     while ~h
%         [~, ~, t, h] = moran_manager.get_next();
%     end
%     moran_result(i) = moran_manager.matrix(1);
% end
% fprintf('Moran (No Mutation): Fixation in %d out of %d runs.\n', sum(moran_result == 1), num_runs);
% 
% %% Test 2 -> Wright-Fisher (No Mutation)
% fitness = [1 1];
% num_runs = 10*pop_size;
% wright_result = zeros(1,num_runs);
% for i = 1:num_runs
%     wright_manager = GridManagerWright(sqrt(pop_size), [(1) (pop_size - 1)], MM, plot_grid, plottingParams, fitness);
%     h = 0;
%     while ~h
%         [~, ~, ~, h] = wright_manager.get_next();
%     end
%     wright_result(i) = wright_manager.matrix(1);
% end
% fprintf('Wright-Fisher (No Mutation): Fixation in %d out of %d runs.\n', sum(wright_result == 1), num_runs);
% 
%% Test 3 -> Wright-Fisher (Probability of Beneficial Mutation Fixation)
%simulating 100 replicates of N = 2500 will take a very long time
% N = [25, 49, 100];%, 400, 625];
% s = [0.005, 0.01, 0.05, 0.1];
% fitness = [1.005 1; 1.01 1; 1.05 1; 1.1 1];
% wright_num_fix = [];
% for i = 1:length(s)
%     f = fitness(i,:);
%     for j = 1:length(N)
%         pfix = (1-exp(-2.*s(i)))/(1-exp(-2.*N(j).*s(i)))
%         count = 0;
%         for k = 1:round(100/pfix)
%         	wright_manager = GridManagerWright(sqrt(N(j)), [(1) (N(j) - 1)], MM, plot_grid, plottingParams, f);
%             h = 0;
%             while ~h
%                 [~, ~, ~, h] = wright_manager.get_next();
%             end
%             count = count + (wright_manager.matrix(1) == 1);
%         end
%         wright_num_fix = [wright_num_fix count];
%     end
% end

%% Test 4 -> Moran (Probability of Beneficial Mutation)
%simulating 100 replicates of N = 2500 will take a very long time
% N = [25];%, 400, 625];
% r = [1.005 1.01 1.05 1.1];
% br = [1.005 1; 1.01 1; 1.05 1; 1.1 1];
% moran_num_fix = [];
% for i = 1:length(br)
%     b = br(i,:);
%     for j = 1:length(N)
%         pfix = (1-(1/r(i)))/(1-(1/(r(i)^N(j))))
%         count = 0;
%         for k = 1:round(100/pfix)
%         	moran_manager = GridManagerMoran(sqrt(N(j)), [(1) (N(j) - 1)], MM, plot_grid, plottingParams, b);
%             h = 0;
%             while ~h
%                 [~, ~, ~, h] = moran_manager.get_next();
%             end
%             count = count + (moran_manager.matrix(1) == 1);
%         end
%         moran_num_fix = [moran_num_fix count];
%     end
% end

%% Test 5 -> Exponential
Ninit = [1 0];
N_tot = 900;
birth = [.5 .5];
death = [0.01 0.01];
counts = cell(1,100);
for i = 1:100
    exp_manager = GridManagerExp(sqrt(N_tot), Ninit, MM, plot_grid, plottingParams, birth, death);
    h = 0;
    counts{i} = [];
    t = 1;
    while ~h
        [~, ~, t, h] = exp_manager.get_next();
        counts{i} = [counts{i} sum(exp_manager.total_count(:,t))];
    end
end
figure;
for j = 1:100
    plot(counts{j});
    hold on;
end

%% Test 6 -> Logistic
% Ninit = [1 0];
% N_tot = 900;
% birth = [1 1];
% death = [0.01 0.01];
% counts = cell(1,100);
% for i = 1:100
%     log_manager = GridManagerLogistic(sqrt(N_tot), Ninit, MM, plot_grid, plottingParams, birth, death);
%     h = 0;
%     counts{i} = [];
%     t = 1;
%     while sum(log_manager.total_count(:,t)) < 0.85*N_tot
%         [~, ~, t, h] = log_manager.get_next();
%         counts{i} = [counts{i} sum(log_manager.total_count(:,t))];
%     end
% end
% figure;
% for j = 1:100
%     plot(counts{j});
%     hold on;
% end
% figure;

