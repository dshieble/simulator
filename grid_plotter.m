function [] = grid_plotter(matrix, ax)

ax.XLim = [1 size(matrix, 1)];
ax.YLim = [1 size(matrix, 2)];
% f = figure();
% ax = axes('Parent',f);  %corrected from my original version
%axis([0 size(matrix, 1) 0 size(matrix, 2)], 'Parent', ax);
% axis off; axis equal;

for i = 1:size(matrix,1) - 1
    for j = 1:size(matrix,2) - 1
        rectangle('Parent', ax, 'Position',[i j 1 1],'facecolor',[0 0 matrix(i,j)]);
    end
end

 