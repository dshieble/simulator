%%
pop_size = 25;
birth_rate = [1 1];
plottingParams = struct(); plottingParams.plot_type = 'total_count'; plottingParams.plot_log = 0;
MM = MutationManager(0, [0.99 0.01; 0.01 0.99], 1, 0, 0);
m = GridManagerLogistic(pop_size, [1], MM, 1, plottingParams, 1, 1, birth_rate, 0);
m.matrix =      ...
 [2     0     3     4     4;...
 4     0     4     0     4;...
 5     0     5     4     4;...
 2     1     4     0     2;...
 1     0     5     4     3];
%%
assert(m.get_nearest_of_type(1,1,3) == 11)
assert(m.get_nearest_of_type(2,1,4) == 12)
m.edges_on = 0;
assert(m.get_nearest_of_type(2,1,4) == 22)


%assert(m.get_nearest_free_to_type(2, 1, 1) == 6)
m.edges_on = 1;
assert(m.get_nearest_free(5,3) == 19 || m.get_nearest_free(5,3) == 10)
