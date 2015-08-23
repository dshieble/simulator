classdef (Abstract) GridManagerAbstract < handle
%This class is the parent class of the 4 grid managers. It contains methods
%that are used by all of its child classes, as well as the instance
%variables used across all classes. 

%The GridManager class stores the matrix/counts of each species, and
%contains a method get_next that advances the matrix/counts to the next
%generation, based on the model that the GridManager's implementation is based
%on
    properties (Abstract, Constant)  %The tag properties, these characterize the class itself
        Name; %The name of the model
        OverlappingGenerations; %Whether the generations overlap. This is 1 for Moran, 0 for Wright-Fisher
        Param_1_Name; %Name of first parameter, e.g. birth_rate
        Param_2_Name; %Name of second parameter, e.g. birth_rate
        atCapacity; %Whether or not the model requires that the total population is always constant and at capacity. 1 for moran, 0 for logistic
        plottingEnabled; %Whether or not the model supports a matrixOn (show petri dish) mode
    end 
    
    properties (SetAccess = private)
        max_size; %The maximum possible population size
        mutation_manager; %A pointer to the mutation manager class that handles mutating each type to other types
        matrixOn; %Determines whether the matrix model or vector model is used
        spatialOn; %Determines whether the spatial structure is considered. Functionality is determined by child classes.
        edgesOn; %Determines whether the edges are considered when searching for the closest square of a type. If 0, the matrix is actually a torus
        Param1; %The first parameter for the model. Typically birth rate or fitness.
        Param2; %The second parameter for the model. Typically death rate. Not all models have 2 parameters. 
        matrix; %Stores the location of each organism
        old_matrix; %Stores the matrix from the previous iteration
        age_matrix; %stores how old each organism in the matrix is 
        age_structure; %cell array, each cell is a timestep storing a vector that stores the frequency of each age
        save_data; %The data that is exported to a .mat file when the user presses save
        timestep; %The number of steps since the beginning of the simulation
        num_types; %The number of different types in the simulation
        colors; %The vector of each type's color

    end
    
    properties (SetAccess = protected)
        %The Population Parameters. Updated in update_params. 
        total_count; %Stores the counts of each type in each generation. matrix of dimensions num types x timestep
        percent_count; %Stores the percent counts of each type in each generation. matrix of dimensions num types x timestep
        overall_mean_fitness; %Stores the overall fitness of each type in each generation. vector of length timestep
    end
    
    methods (Access = public)
        %The constructor method. This function initializes the matrix and
        %the plotting parameters, as well as other useful variables like
        %the color variable. The final 2 inputs are the Param1 and the
        %Param2 inputs
        function obj = GridManagerAbstract(max_size, Ninit, mutation_manager, matrixOn, spatialOn, edgesOn, p1, p2)
            assert(~matrixOn || floor(sqrt(max_size))^2 == max_size)
            assert(~obj.atCapacity || sum(Ninit)==max_size);
            
            obj.Param1 = p1';
            obj.Param2 = p2';
            obj.spatialOn = spatialOn;
            obj.matrixOn = matrixOn;
            obj.edgesOn = edgesOn;
            if obj.matrixOn
                obj.matrix = zeros(sqrt(max_size));
                obj.age_matrix = zeros(sqrt(max_size)) - 1;
            else
                obj.matrix = [];
                obj.age_matrix = [];
            end
            obj.old_matrix = obj.matrix;
            obj.max_size = max_size;
            if obj.matrixOn
                if (sum(Ninit) == obj.max_size) || ~spatialOn %static population models, random placement
                    r = randperm(numel(obj.matrix));
                    i = 1;
                    for type = 1:length(Ninit)
                        n = Ninit(type);
                        obj.changeMatrix(r(i:n+i-1), type);
                        i = i + n;
                    end
                else %non-static models, place founding cells in center
                    org_vec = [];
                    for type = 1:length(Ninit)
                        org_vec = [org_vec repmat(type,1,Ninit(type))];
                    end
                    org_vec = org_vec(randperm(length(org_vec)));
                    ind = obj.get_center();
                    for i = 1:length(org_vec)
                        obj.changeMatrix(ind, org_vec(i));
                        [a, b] = ind2sub(size(obj.matrix), ind);
                        ind = obj.get_nearest_free(a,b);
                    end
                end
            end
            
            obj.timestep = 1;
            obj.num_types = length(Ninit);
            %when there are more than 10 types, colors become randomized
            obj.colors = [1 0 0; ...
                0 1 0; ...
                0 0 1; ...
                1 1 0; ...
                1 0 1;...
                0 1 1; ...
                1 0.5 0.5; ...
                0.5 1 0.5; ...
                1 0.5 0.5;...
                0.5 0.5 0.5; ...
                0.25 0.25 1; ...
                1 .25 .25;...
                .25 1 .25;
                .5 .25 0; ...
                .25 0 .5; ...
                0 .25 .5; ...
                .15 .15 .15;];
            obj.total_count = Ninit';
            obj.percent_count = [];
            obj.overall_mean_fitness = [];
            obj.age_structure = {[]};
            obj.mutation_manager = mutation_manager;
            obj.save_data = struct('Param1', p1, 'Param2', p2);
            obj.update_params();
        end
      
        %This function is called at the end of get_next by all of the child
        %classes. It instantiates the output variables and increments the
        %timestep. 
        %
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not the model should halt
        function [mat, changed, t, h] = get_next_cleanup(obj)
            obj.timestep = obj.timestep + 1;
            obj.mutation_manager.mutate(obj);
            obj.mutation_manager.recombination(obj);
            if ~obj.matrixOn
                changed = [];
            else
                changed = find(obj.old_matrix ~= obj.matrix);
                obj.old_matrix = obj.matrix;
            end
            obj.update_params();
            obj.save_data.total_count = obj.total_count;
            obj.save_data.total_count = obj.total_count;
            obj.save_data.age_structure = obj.age_structure;
            mat = obj.matrix;
            t = obj.timestep;
            h = max(obj.total_count(:, obj.timestep))>=obj.max_size;
            h = h && ~obj.mutation_manager.mutating || (sum(obj.total_count(:, obj.timestep)) == 0);
        end

        %Returns a square in the matrix of type t
        function ind = get_of_type(obj, t)
            assert(obj.matrixOn == 1)
            typed = find(obj.matrix == t);
            if isempty(typed)
                ind = randi(obj.max_size);
            else
                ind = typed(randi(length(typed)));
            end
        end
        
        %Returns a free square in the matrix
        function ind = get_free(obj)
            assert(obj.matrixOn == 1)
            free = find(obj.matrix == 0);
            if isempty(free)
                ind = randi(obj.max_size);
            else       
                ind = free(randi(length(free)));
            end
        end

        %Returns the nearest square in the matrix of type t        
        function ind = get_nearest_of_type(obj, x, y, t)
            assert(obj.matrixOn == 1);
            indices = find(obj.matrix == t);
            base = sub2ind(size(obj.matrix), x, y);
            indices = indices(indices ~= base);
            if isempty(indices)
                ind = 0;
                return;
            end
            dists = matrix_distance(obj, repmat(base,1,length(indices))', indices);
            [~,i] = min(dists);
            ind = indices(i);
        end
        
        %Returns the manhattan distance between 2 cells in the matrix. Uses wrapping
        %if ~obj.edges
        function d = matrix_distance(obj, base, ind)
            [a_1, b_1] = ind2sub(size(obj.matrix), base);
            [a_2, b_2] = ind2sub(size(obj.matrix), ind);
            wd = abs(a_1 - a_2);
            hd = abs(b_1 - b_2);
            if ~obj.edgesOn %wrappping
                wd = min(wd, size(obj.matrix,1) - wd);
                hd = min(hd, size(obj.matrix,2) - hd);
            end
            d = hd + wd;
        end
        

        
        %Returns the nearest free square in the matrix
        function ind = get_nearest_free(obj, i, j)
            ind = get_nearest_of_type(obj, i, j, 0);
        end

        %Gets the center cell in the matrix
        function ind = get_center(obj)
        	assert(obj.matrixOn == 1);
            a = floor(size(obj.matrix, 1)/2);
            ind = sub2ind(size(obj.matrix),a,a);
        end
        
        %Gets the ith color from the color matrix
        function c = get_color(obj,i)
            c = obj.colors(i,:);
        end

        %returns 1 if there is only one species
        function h = isHomogenous(obj)
            found = 0;
            h = 1;
            for i = 1:size(obj.matrix, 1)
                if ~isempty(find(obj.matrix == i, 1))
                    found = found + 1;
                end
                if found >= 2 
                    h = 0;
                    break;
                end
            end
        end
        
        %Returns a random cell of the chosen type
        function out = getRandomOfType(obj, type)
            assert(obj.matrixOn == 1)
            
            ofType = find(obj.matrix == type);
            out = ofType(randi(numel(ofType)));
        end
        
        % Matrix Methods
        
        %Changes an element in the matrix and resets the age
        function changeMatrix(obj, ind, new)
            assert(obj.matrixOn == 1);
            obj.matrix(ind) = new;
            if new > 0
                obj.age_matrix(ind) = 0;
            else
                obj.age_matrix(ind) = -1;
            end
        end
        
        %Mutates an element in the matrix (changes it without changing its
        %age)
        function mutateMatrix(obj, ind, new)
            assert(obj.matrixOn == 1);
            assert(obj.matrix(ind) ~= 0, 'ERROR: Cannot mutate an element that is currently zero');
            assert(new ~= 0, 'ERROR: Cannot mutate an element to become zero');
            obj.matrix(ind) = new;
        end
        
        %Resets the matrix to the input
        function resetMatrix(obj, new_mat)
            assert(obj.matrixOn == 1);
            obj.matrix = new_mat;
            obj.age_matrix = zeros(sqrt(obj.max_size));
            obj.age_matrix(new_mat == 0) = -1;
        end
        
        %Sets the total count variable
        function setTotalCount(obj, new)
            assert(sum(new) <= obj.max_size);
            assert(all(new >= 0));
            obj.total_count(:, obj.timestep) = new;
        end
                    
        %Updates the total_count, the percent_count, the overall_mean_fitness and
        %the age_matrix/age_structure properties
        function update_params(obj)
            mean_fitness = zeros(1,obj.num_types);
            for i = 1:obj.num_types
                obj.percent_count(i, obj.timestep) = obj.total_count(i, obj.timestep)./numel(obj.matrix);
                mean_fitness(i) = (obj.Param1(i))*obj.percent_count(i, obj.timestep); 
            end
            obj.overall_mean_fitness(obj.timestep) = dot(mean_fitness, obj.total_count(:,obj.timestep));
            if obj.OverlappingGenerations
                obj.age_matrix(obj.age_matrix ~= -1) = obj.age_matrix(obj.age_matrix ~= -1) + 1;
                ages = obj.age_matrix(obj.age_matrix ~= -1);
                obj.age_structure{obj.timestep} = hist(ages, max(ages))./length(ages);
            end            
        end
        
        
    end
    
    
    
    methods (Abstract)        
        %A method implemented by all of the child GridManager class.
        %This method updates obj.total_count for the new timestep, and, if
        %matrixOn is enabled, also updates the GridManager's petri dish
        %mat - new updated matrix
        %changed - entries in matrix that have changed
        %t - the timestep
        %h - whether or not we should halt
        [mat, changed, t, h] = get_next(obj)
    end
    
    
end