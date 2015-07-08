%get_nearest_free
% g = GridManagerLogistic(7, 0, 0, 0, 1, 0, 0);
% g.matrix = [1 1 1 1 1 1 1; 1 1 1 0 0 0 1; 1 1 1 1 1 1 0; 1 1 0 1 1 0 1; 1 1 1 1 1 0 0; 1 1 0 1 1 0 1; 1 1 1 1 1 0 0];
% assert (g.get_nearest_free(3,3) == 18);
% assert (g.get_nearest_free(6,5) == 41);
