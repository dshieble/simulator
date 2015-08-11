%% Directions For Making Models!

%% Step 1: Create the directory 

% Run the function New_Model('<ModelName>') without the <>. The input will be the model's
% name. Try to keep it under 10 characters with no spaces. Please do not
% edit the @GridManagerCustom folder

% This function will create a directory named @GridManager<ModelName>.


%% Step 2: Decide whether to implement a matrix model or a vector model.

% Navigate to the directory you just created by selecting it though matlab or running the
% command cd('@GridManager<ModelName>') where <ModelName> is the name of
% the model


%% Vector Models:
% The vector in the model has n entries, where n is the number of different
% types. The ith element in the vector is the number of organisms of type
% i.

% If you would like to implement a vector model, open the file
% get_next_vector and follow the instructions

%%  Matrix Models: 

% The matrix in the model is square. If the (i,i)th element in the matrix is 
% 0, then the (i,i)th position is considered unoccupied. If the (i,i)th 
% element in the matrix is equal to x, then the (i,i)th square is considered 
% occupied by an organism of type x.

% If you would like to implement a matrix model, first open the file 
% GridManager<ModelName> and change the line that says 

% plottingEnabled = 0;
% to
% plottingEnabled = 1;

% Then open the file get_next_matrix and follow the instructions



