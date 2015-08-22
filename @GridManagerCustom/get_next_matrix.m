function [new_mat] = get_next_matrix(obj, old_mat, param1, param2, max_pop_size)
%TODO: Possibly implement functionality to allow for age matrix input and
%output as well
%TODO: Change the description and structure here to account for the new
%matrix model

%In this file, you can implement a matrix-based model. You are given access
%to the matrix from the previous iteration and the parameters that you enter
%into the GUI, and you generate the matrix for the current generation.

%% The Matrix

% The matrix in the model has max_pop_size entries, and is square. If the
% (i,i)th element in the matrix is 0, then the (i,i)th position is
% considered unoccupied. If the (i,i)th element in the matrix is equal to x,
% then the (i,i)th square is considered occupied by an organism of type x.

% TIP: If you want to know how many elements in the matrix are occupied by
% an organism of type x, try the command: find(old_mat == x)


%% Inputs

% obj: You don't need to worry about this input.

% old_mat: This is the matrix representing the previous generation. 

% param1: The is the first parameter for the model. You define this
% parameter in the GUI

% param2: The is the second parameter for the model. You define this
% parameter in the GUI

% max_pop_size: The is the number of elements in the matrix and the maximum
% size that the population can grow to. You define this parameter in the GUI

%% Outputs

% new_mat: This is the matrix for the current generation. You model should
% create this matrix.

%% Code
% Write your code here!
    new_mat = old_mat*round(rand(size(old_mat)));
end
