function [ cur_fig ] = plot_image_ui(img,varargin)
%   plots image, adds sliders for colormap min max and range

x = reshape(img, size(img,1)*size(img,2), 1);  %make an array out of the img to determine clim_start

%set slider limits and slider starting points
clim = [min(min(img)) max(max(img))];
dc  = clim(2)-clim(1);
clim = [clim(1)-dc*0.01  clim(2)+dc*0.01];
clim_start = [mean(x)-3*std(x) mean(x)+3*std(x)];
clim_start(2) = min(clim_start(2), clim(2));
clim_start(1) = max(clim_start(1), clim(1)+1);

cur_fig = figure('units','normalized','outerposition',[0 0 1 1]);

if nargin>1                                %set colormap
    colormap(varargin{1});
else
    colormap('Gray');
end

imagesc(img, clim_start), colorbar, axis image % plot
set(cur_fig,'toolbar','figure')
axisHandle = gca;

stepSize=[0.001 0.01];          %slider minor and major stepsizes
%create slider objects
slider_upperLimit=uicontrol('Style', 'slider', 'Min', clim(1),'Max', clim(2),'Value', clim_start(2), 'SliderStep', stepSize,'Position', [1 50 500 20],'Callback', {@lim_high,axisHandle});  %slider upper limit 
slider_lowerLimit=uicontrol('Style', 'slider', 'Min', clim(1),'Max', clim(2),'Value', clim_start(1), 'SliderStep', stepSize,'Position', [1 30 500 20],'Callback', {@lim_low,axisHandle});   %slider lower limit
uicontrol('Style', 'slider', 'Min', clim(1)+stepSize(1),'Max', clim(2),'Value', clim(2), 'SliderStep', stepSize,'Position', [1 0 500 20],'Callback', {@lim_range,axisHandle,slider_upperLimit,slider_lowerLimit});   %slider multplier

function lim_high(hObj,event,ax) %#ok<INUSL>
    % Called to set upper zlim of surface in figure axes
    % when user moves the slider control
    val =  get(hObj,'Value');
    clim_cur = get(ax, 'CLim');
    clim_set = [clim_cur(1) max( clim_cur(1)+stepSize(1), val )];
    set(ax, 'CLim',  clim_set );
    set(hObj, 'value', clim_set(2))
end


function lim_low(hObj,event,ax) %#ok<INUSL>
    % Called to set lower zlim of surface in figure axes
    % when user moves the slider control
    val =  get(hObj,'Value');
    clim_cur = get(ax, 'CLim');
    clim_set = [ min( clim_cur(2)-stepSize(1), val   ) clim_cur(2)];
    set(ax, 'CLim',   clim_set);
    set(hObj, 'value', clim_set(1))

end

function lim_range(hObj,event,ax, slider_upperLimit,slider_lowerLimit) %#ok<INUSL>
    % Called to set range for zlim of surface in figure axes
    % when user moves the slider control, rescales lower and upper limit sliders, then adjusts lower and upper limit
    val =  get(hObj,'Value');
    
    min_cur= get(slider_upperLimit,'Min');
    max_cur= get(slider_upperLimit,'Max');
    
    upperLimit_cur =get(slider_upperLimit,'Value');
    lowerLimit_cur =get(slider_lowerLimit,'Value');
    
    upperLimit_new=min_cur+(upperLimit_cur-min_cur)*(val-min_cur)/(max_cur-min_cur);
    lowerLimit_new=min_cur+(lowerLimit_cur-min_cur)*(val-min_cur)/(max_cur-min_cur);
    
    set(slider_upperLimit,'Value',upperLimit_new);
    set(slider_upperLimit,'Max',val);

    set(slider_lowerLimit,'Value',min_cur+(lowerLimit_cur-min_cur)*(val-min_cur)/(max_cur-min_cur));
    set(slider_lowerLimit,'Max',val);
    
    clim_set = [ lowerLimit_new upperLimit_new ];
    set(ax, 'CLim',   clim_set);
end

end