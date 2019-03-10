function [ lanes ] = manual_lane_selection( image, pos, varargin )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    
area = image( pos(2):pos(2)+pos(4), pos(1):pos(1)+pos(3)); % get the image inside pos
    x = double(pos(1):pos(1)+pos(3)); % define x-axis (horizontal axis)

    horizontalProfile = sum(area); % integrate along vertical (y-axis) 


    if isempty(varargin)     
        tmp = inputdlg('Number of lanes?', 'Number of lanes', 1, {'1'});
        N_lanes = str2double(tmp{1});
    else
        if varargin{1}>0
            N_lanes = varargin{1};
        else
            tmp = inputdlg('Number of lanes?', 'Number of lanes', 1, {'1'});
            N_lanes = str2double(tmp{1});
        end
    end
        
    xy = zeros(N_lanes+1, 2);
    
    cf = figure;
    hold all
    plot(x, horizontalProfile)
    set(gca, 'Xlim', [min(x), max(x)])
    title('Select intial lanes.')
    for i=1:N_lanes+1
        [xy(i,1), xy(i,2)] = ginput(1);
        vline(xy(i,1), 'r');
    end
    
    close(cf)

    % write areas
    lanes = zeros(N_lanes,4);
    for i=1:size(lanes, 1)
       lanes(i, 2)= pos(2); % top y-positions stays constant
       lanes(i, 4)= pos(4); % height stays constant
       lanes(i, 1) = xy(i,1); % top x-position
       lanes(i, 3) = xy(i+1,1)-xy(i,1); % width
    end
   
end

