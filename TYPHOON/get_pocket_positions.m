function gelData = get_pocket_positions(gelData, channel, varargin)
%% Loads gel lanes, selects gel pocket location (max in selected subrange of profiles
%   INPUTS:
%   gelData = gelData struct from get_gel_lanes function
%   channel = index of image to be used for pocket detection
%   
%   OUTPUT:
%   gelData struct with .profiles .lanePositions .imageNames .fullProfiles .pocketPositions
%   .profiles is cell array {nr_image,nr_lane} of lane profiles (horizontal integrals)
%   .lanePositions is array nr_lanes * [left edge, right edge, top edge, bottom edge]
%   .imageNames is cell array of image name strings
%   .fullProfiles is cell array {nr_image,nr_lane} of lane profiles (horizontal integrals) over entire gel image vertical length
%   .pocketPosition is array of pocket locations for each lane profile
% Example: gelData = get_gel_lanes(gelData);

%% parse input variables
p = inputParser;
% required parameter
addRequired(p,'gelData');
addRequired(p,'channel');

% optional parameter: preset range for pocket detection
default_preset_range  = nan;
addParameter(p, 'preset_range', default_preset_range,  @isnumeric);

parse(p, gelData, channel, varargin{:});
preset_range = p.Results.preset_range;

%% 
button='No';
figure('units','normalized','outerposition',[0 0 1 1]);

%find pocket locations by finding maximum value in range
while strcmp(button,'No')
    
    % no preset range supplied, select range by hand
    if isnan(preset_range)
        clf
        fig = plot([gelData.profiles{channel,:}]);
        title('Select pocket peak area')
        rect = imrect;
        wait(rect);
        selectedArea = int32(getPosition(rect));
        delete(rect);
    % preset range supplied, immediately set as range
    else
        selectedArea = [preset_range(2) 0 preset_range(4) 0];
    end
    
    pocketPositions=[];
    title('pocket location correct? - press any key')
    for i = 1:length(gelData.profiles)
        [~, loc] = max(gelData.profiles{channel,i}(selectedArea(1):selectedArea(1)+selectedArea(3)));
        pocketPositions(i) = loc+selectedArea(1) - 1;
    end
    
    clf
    for i=1:length(gelData.profiles)
        plot([gelData.profiles{channel,i}]./max([gelData.profiles{channel,i}])+i-1);
        hold on
        x=[pocketPositions(i),pocketPositions(i)];
        y=[i-1,i];
        plot(x,y,'LineWidth',1.5,'color','black')
    end
    axis([0 length(gelData.profiles{channel,1}) 0 size(gelData.profiles,2)]);
    
    % no preset range supplied, check if pocket positions are correct
    if isnan(preset_range)
        button = questdlg('are the pocket positions ok?','are the pocket positions ok?' ,'No','Yes', 'Yes');
    % preset range supplied, only show result
    else
        title('Selected pocket positions')
        pause
        button = 'Yes';
    end
end

% close plot figure
close

gelData.pocketPositions=pocketPositions;