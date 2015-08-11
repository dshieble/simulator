function new_vec = get_next_vector(obj, old_vec, param1, param2, max_pop_size)
%In this file, you can implement a vector-based model. You are given access
%to the vector from the previous iteration and the parameters that you enter
%into the GUI, and you generate the vector for the current generation.

%% The Vector

% The vector in the model has n entries, where n is the number of different
% types. The ith element in the vector is the number of organisms of type
% i.


%% Inputs

% obj: You don't need to worry about this input.

% old_vec: This is the vector representing the previous generation. The
% matrix has max_pop_size entries, and is a square matrix. If 
% old_mat(i,i) == 0, then the (i,i)th cell of the matrix is empty. If 
% old_mat(i,i) == x, then the (i,i)th cell of the matrix is occupied by an
% organism of type x.

% param1: The is the first parameter for the model. You define this
% parameter in the GUI

% param2: The is the second parameter for the model. You define this
% parameter in the GUI

% max_pop_size: The is the number of elements in the matrix and the maximum
% size that the population can grow to. You define this parameter in the GUI

%% Outputs

% new_mat: This is the matrix for the current generation. Your model should
% create this vector.

%% Code
% Write your code here!

    new_vec = round(old_vec.*2.*rand(1,length(old_vec))); %delete this line
end
