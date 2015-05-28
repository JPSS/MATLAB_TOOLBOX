function [ cur_fig ] = plot_image_ui(img,varargin)
%   plots image, adds sliders for colormap min, colormap max and data range
%   optional parameter 'colormap' takes any colormap, default gray colormap
%   optional parameter 'type' takes string, if string is 'image' creates an image class object, if other creates an figure class object

x = reshape(img, size(img,1)*size(img,2), 1);  %make an array out of the img to determine clim_start

%set slider limits and slider starting points
clim = [min(min(img)) max(max(img))];
dc  = clim(2)-clim(1);
clim = [clim(1)-dc*0.01  clim(2)+dc*0.01];
clim_start = [0 clim(2)];

% parse input 
p = inputParser;

addRequired(p,'img');
%addParameter(p,'colormap',colormap('Gray'), @(map)iptcheckmap(map, 'plot_image_ui', 'colormap', 'doesnt matter') ); 
addParameter(p,'colormap','Gray'); 
addParameter(p,'type','figure', @ischar ); 

parse(p, img, varargin{:});

%check type request, create appropriate class object
if strcmp(p.Results.type,'image')
else
    cur_fig = figure('units','normalized','outerposition',[0 0 1 1]);
    set(cur_fig,'toolbar','figure');
end

%apply colormap
colormap(p.Results.colormap);
 
axisHandle = gca;
 
stepSize=[0.001 0.01];          %slider minor and major stepsizes
%create slider objects
slider_upperLimit=uicontrol('Style', 'slider', 'Min', clim(1),'Max', clim(2),'Value', clim_start(2), 'SliderStep', stepSize,'Position', [1 50 500 20],'Callback', {@lim_high,axisHandle});  %slider upper limit 
slider_lowerLimit=uicontrol('Style', 'slider', 'Min', clim(1),'Max', clim(2),'Value', clim_start(1), 'SliderStep', stepSize,'Position', [1 30 500 20],'Callback', {@lim_low,axisHandle});   %slider lower limit
uicontrol('Style', 'slider', 'Min', stepSize(1),'Max', 1,'Value', 1, 'SliderStep', stepSize,'Position', [1 0 500 20],'Callback', {@lim_range,axisHandle,slider_upperLimit,slider_lowerLimit});   %slider multplier
 
if strcmp(p.Results.type,'image')
    cur_fig = imagesc(img, clim_start); %colorbar, axis image 
else
    imagesc(img, clim_start); %colorbar, axis image
end

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
    % Called to set range of data for zlim selection.
    % when user moves the slider control, rescales data range for limit sliders towards/away from center of current limits
    % then adjusts current lower and upper limit if they are beyond new data range
    val =  get(hObj,'Value');
    
    upperLimit_cur =get(slider_upperLimit,'Value');
    lowerLimit_cur =get(slider_lowerLimit,'Value');
    
    center=(lowerLimit_cur+upperLimit_cur)/2;
    
    width_new=(clim(2)-clim(1))*val;
    
    min_new=center-width_new/2;
    max_new=center+width_new/2;
    
    if min_new<clim(1)
        min_new=clim(1);
        max_new=min_new+width_new;
    end
    
    if max_new>clim(2)
        max_new=clim(2);
        min_new=max_new-width_new;
    end
       
    upperLimit_new=min(max_new,upperLimit_cur);
    lowerLimit_new=max(min_new,lowerLimit_cur);
   
    set(slider_upperLimit,'Value',upperLimit_new);
    set(slider_upperLimit,'Max',max_new);
    set(slider_upperLimit,'Min',min_new);

    set(slider_lowerLimit,'Value',lowerLimit_new);
    set(slider_lowerLimit,'Max',max_new);
    set(slider_lowerLimit,'Min',min_new);
    
    clim_set = [ lowerLimit_new upperLimit_new ];
    set(ax, 'CLim',   clim_set);
end

end