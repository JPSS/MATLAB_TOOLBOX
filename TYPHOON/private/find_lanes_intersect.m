function [ lanes ] = find_lanes_intersect( image, pos )
%% find lanes edges at intersection with user-supplied threshold
%   Detailed explanation goes here

area = image( pos(2):pos(2)+pos(4), pos(1):pos(1)+pos(3));
x = double(pos(1):pos(1)+pos(3));

verticalIntegral = sum(area);

%%
close all
subplot(2, 1, 1)
imagesc(image), axis image, colormap gray
set(gca, 'XLim', [pos(1) pos(1)+pos(3)])
set(gca, 'YLim', [pos(2) pos(2)+pos(4)])

shift = mean(verticalIntegral)-std(verticalIntegral);
subplot(2, 1, 2)
hleg(1) = plot(x, verticalIntegral, 'b');
hold on
hleg(2) = hline(mean(verticalIntegral), 'k--');
hleg(3) = hline(min(verticalIntegral), 'y--');
hleg(4) = hline(max(verticalIntegral), 'g--');
y_init = (max(verticalIntegral)-min(verticalIntegral))/2;
hleg(5) = hline(y_init, 'r--');

legend(hleg, {'y', 'mean(y)', 'min(y)', 'max(y)', '(max(y)-min(y))/2 (default)'})
set(gca, 'XLim', [pos(2) pos(2)+pos(4)])

plot(x, verticalIntegral, 'b')
xlim = [x(1) x(end)]; 
set(gca, 'XLim', xlim)
h = imline(gca, xlim, [y_init y_init]);
setColor(h,[1 0 0]);
setPositionConstraintFcn(h, @(pos)[  xlim' [pos(1,2);pos(1,2)]  ])
pos_line = wait(h);
shift = pos_line(1,2);

close all
%%
y_shift = verticalIntegral - shift;

%find roots of y_shift
r = [];
for i=1:length(y_shift)-1
    if y_shift(i)*y_shift(i+1) < 0 %root
       r = [r ; i];
    end
end

lanes = zeros(length(r)/2,4);

for i=1:size(lanes, 1)
   lanes(i, 2)= pos(2);
   lanes(i, 4)= pos(4);
   
   lanes(i, 1) = x(r(i*2-1));
   lanes(i, 3) = x(r(i*2))-x(r(i*2-1)); 

end

end

