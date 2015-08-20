function out = AutomatedSimulator(GridManagerClass, Ninit, p1, p2, varargin)
    % This file is an automated front end for the simulator program
    % mutating - 0
    % num_loci - 0
    % mutation_matrix - [0.99 0.01; 0.01 0.99]
    % recombination_number - 0
    % plot_grid - 0
    % totalPopSize - 2500
    % spatial_on - 1
    % edges_on - 1
    % max_iterations - 25
    % return - total_count, matrix, age_dist
    %TestInput - AutomatedSimulator('GridManagerLogistic', [1 1], [1 1], [0.01 0.01], 'total_pop_size', 900)
    %TestInput2 - AutomatedSimulator('GridManagerMoran', [450 450], [1 1], [0.01 0.01], 'total_pop_size', 900)

    %ErrorInputs
    %AutomatedSimulator('GridManagerLogistic', [1 1 1], [1 1], [0.01 0.01])
    %AutomatedSimulator('GridManagerLogistic', [1 1], [1 1], [0.01 0.01], 'mutating', 1, 'mutation_matrix', [.01 .01 .01; .08 .08 .08; .01 .01 .01]);
    %AutomatedSimulator('GridManagerLogistic', [1 1 1], [1 1], [0.01 0.01], 'num_loci', 0.1)

    p = inputParser;

    addRequired(p,'GridManagerClass',@(s) exist(s, 'file'));
    addRequired(p,'Ninit',@is_positive_integer);
    addRequired(p,'p1',@is_number);
    addRequired(p,'p2',@is_number);

    addParameter(p,'mutating', 0, @(x) x == 0 || x == 1);
    addParameter(p,'mutation_matrix', [], @(M) size(M,1) == size(M,2) && is_positive_number(M));
    addParameter(p,'num_loci', 0, @is_positive_integer);
    addParameter(p,'recombination_number', 0, @is_positive_integer);
    addParameter(p,'matrix_on', 0, @(x) x == 0 || x == 1);
    addParameter(p,'total_pop_size', 2500, @is_positive_integer);
    addParameter(p,'return_type', 'total_count', @(x) any(validatestring(x,{'total_count', 'matrix', 'age_dist'})));
    addParameter(p,'spatial_on', 0, @(x) x == 0 || x == 1);
    addParameter(p,'edges_on', 0, @(x) x == 0 || x == 1);
    addParameter(p,'max_iterations', 25,  @is_positive_integer);

    parse(p,GridManagerClass, Ninit, p1, p2, varargin{:})
    assert(length(p.Results.Ninit) == length(p.Results.p1) && length(p.Results.p1) == length(p.Results.p2), 'Lengths pf Ninit, p1 and p2 must be the same!');
    
    
    recombining = (p.Results.recombination_number > 0);
    if isempty(p.Results.mutation_matrix)
        mutation_matrix = generate_mutation_matrix(numel(p.Results.Ninit));
    else
        assert(length(p.Results.Ninit) == size(p.Results.mutation_matrix,1), 'The sides of mutation matrix are the incorrect length');
        mutation_matrix = p.Results.mutation_matrix;
    end
    
    MM = MutationManager(p.Results.mutating, mutation_matrix, p.Results.num_loci, recombining, p.Results.recombination_number);
    plottingParams = struct(); plottingParams.plot_type = 'total_count'; plottingParams.plot_log = 0;
    
    constructor = str2func(GridManagerClass);
    grid_manager = constructor(...
        p.Results.total_pop_size,...
        p.Results.Ninit,...
        MM,...
        p.Results.matrix_on,...
        plottingParams,...
        p.Results.spatial_on,...
        p.Results.edges_on,...
        p.Results.p1,...
        p.Results.p2);
    
    mat_cell = {};
    for iter = 1:p.Results.max_iterations
    	[matrix, c, t, halt] = grid_manager.get_next();
        if strcmp(p.Results.return_type, 'matrix')
            mat_cell{iter} = matrix;
        end
        if halt
            break;
        end
    end
    if iter >= p.Results.max_iterations
        fprintf('Max number of iterations, %d, reached. You can set this by setting the max_iterations parameter. \n', p.Results.max_iterations);
    end
    switch p.Results.return_type
        case 'total_count'
            out = grid_manager.total_count;
        case 'matrix'
        	out = mat_cell;
        case 'age_dist'
            out = []; %TODO: FLESH THIS OUT
    end


    function out = is_number(n)
        %verifies that input is a vector of numbers
        out = 1;
        if any(~isnumeric(n))
            out = 0;
        elseif any(isnan(n))
            out = 0;
        end
    end

    function out = is_positive_number(n)
        %verifies that input is a vector of positive numbers
        out = 1;
        if ~is_number(n)
            out = 0;
        elseif any(n < 0) %negative
            out = 0;
        end 
    end

    function out = is_positive_integer(n)
        %verifies that input is a vector of positive integers
        out = 1;
        if ~is_positive_number(n)
            out = 0;
        elseif any(round(n) ~= n) %non-integer
            out = 0;
        end 
    end

    function mm = generate_mutation_matrix(dim)
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
