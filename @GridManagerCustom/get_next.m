function [mat, changed, t, h] = get_next(obj)
%TODO: Change the instructions and logic to account for the new matrix
%rules
%TODO: Change the logic so that plot_grid is automatically enabled whenever
%we use the matrix method, even if the grid is not being plotted

%This is the get_next wrapper method that performs the necessary updates
%and makes the necessary calls by interacting directly with the
%user-defined get_next_matrix or get_next_vector functions
    if obj.plottingEnabled
        mat = obj.get_next_matrix(obj.matrix, obj.Param1, obj.Param2, numel(obj.matrix));
        for i = 1:obj.num_types
            obj.total_count(i, obj.timestep + 1) = length(find(mat == i));
        end
        obj.matrix = mat;
    else
    	obj.total_count(:, obj.timestep + 1) = obj.get_next_vector(obj.total_count(:, obj.timestep)', obj.Param1, obj.Param2, numel(obj.matrix))';
    end
    %Error Checking
    if sum(obj.total_count(:, obj.timestep + 1)) > numel(obj.matrix)
        fprintf('ERROR: On iteration %d, the number of elements in the new_vec was larger than the max_pop_size\n', obj.timestep + 1);
    elseif max(obj.matrix) > obj.num_types
        fprintf('ERROR: There is a cell in the matrix of type %d, but there are only %d types in this model\n', max(obj.matrix), obj.num_types)
    elseif any(any(round(obj.matrix) ~= obj.matrix)) || ...
            any(any(round(obj.total_count(:, obj.timestep + 1)) ~= obj.total_count(:, obj.timestep + 1)))
        fprintf('ERROR: All elements in the returned matrix or vector must be integers\n');
    end
    try 
        [mat, changed, t, h] = obj.get_next_cleanup();
    catch e
        fprintf('ERROR: Error during mutation and cleanup\n');
        throw(e);
    end
end
