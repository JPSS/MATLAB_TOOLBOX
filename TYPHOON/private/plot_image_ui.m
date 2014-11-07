function [ cur_fig ] = plot_image_ui(img)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
x = reshape(img, size(img,1)*size(img,2), 1);  %make an array out of the img to determine clim_start
clim = [min(min(img)) max(max(img))];
dc  = clim(2)-clim(1);
clim = [clim(1)-dc*0.01  clim(2)+dc*0.01];
clim_start = [mean(x)-3*std(x) mean(x)+3*std(x)];
clim_start(2) = min(clim_start(2), clim(2));
clim_start(1) = max(clim_start(1), clim(1)+1);

cur_fig = figure('units','normalized','outerposition',[0 0 1 1]);
colormap('Gray');
imagesc(img, clim_start), colorbar, axis image % plot

set(cur_fig,'toolbar','figure')
h = gca;
%uicontrol('Style', 'slider', 'Min',clim(1),'Max', clim(2),'Value',41, 'Position', [400 20 120 20],'Callback', {@my_rescale,h,clim});   

uicontrol('Style', 'slider', 'Min', clim(1),'Max', clim(2),'Value', clim_start(2), 'SliderStep', [0.001 0.01],'Position', [1 50 500 20],'Callback', {@lim_high,h,clim});  %slider top 
uicontrol('Style', 'slider', 'Min', clim(1),'Max', clim(2),'Value', clim_start(1), 'SliderStep', [0.001 0.01],'Position', [1 20 500 20],'Callback', {@lim_low,h,clim});   %slider bottom







end



function lim_high(hObj,event,ax, clim) %#ok<INUSL>
    % Called to set zlim of surface in figure axes
    % when user moves the slider control
    val =  get(hObj,'Value');
    clim_cur = get(ax, 'CLim');
    
    clim_set = [clim_cur(1) max( clim_cur(1)+1, val   )];
    set(ax, 'CLim',  clim_set );
    set(hObj, 'value', clim_set(2))
    
end


function lim_low(hObj,event,ax, clim) %#ok<INUSL>
    % Called to set zlim of surface in figure axes
    % when user moves the slider control
    val =  get(hObj,'Value');
    clim_cur = get(ax, 'CLim');
    clim_set = [ min( clim_cur(2)-1, val   ) clim_cur(2)];
    set(ax, 'CLim',   clim_set);
    set(hObj, 'value', clim_set(1))

end