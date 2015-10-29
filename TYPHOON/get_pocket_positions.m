function gelData = get_pocket_positions(gelData,channel)
%% Loads gel lanes, selects gel pocket location (max in selected subrange of profiles
%   INPUTS:
%   [ optional:[ weights for channels] ]
%   OUTPUT:
%   gelData struct with .profiles .lanePositions .imageNames .fullProfiles .pocketPositions
%   .profiles is cell array {nr_image,nr_lane} of lane profiles (horizontal integrals)
%   .lanePositions is array nr_lanes * [left edge, right edge, top edge, bottom edge]
%   .imageNames is cell array of image name strings
%   .fullProfiles is cell array {nr_image,nr_lane} of lane profiles (horizontal integrals) over entire gel image vertical length
%   .pocketPosition is array of pocket locations for each lane profile
% Example: gelData = get_gel_lanes(gelData);

button='No';
while strcmp(button,'No')                                       %find pocket locations by finding maximum value in range
    fig=figure;
    fig=plot([gelData.profiles{channel,:}]);
    title('Select pocket peak area')
    rect = imrect;
    wait(rect);
    selectedArea = int32(getPosition(rect));
    delete(rect);

    pocketPositions=[];
    title('pocket location correct? - press any key')
    for i=1:length(gelData.profiles)
        [~, loc]=max(gelData.profiles{channel,i}(selectedArea(1):selectedArea(1)+selectedArea(3)));
        pocketPositions(i)=loc+selectedArea(1)-1;
        fig=plot([gelData.profiles{channel,i}]);
        hold on

        x=[pocketPositions(i),pocketPositions(i)];
        y=[0,max(gelData.profiles{channel,i})];
        plot(x,y,'LineWidth',0.5,'color','black')
        pause
        clf
    end
    button = questdlg('are the pocket positions ok?','are the pocket positions ok?' ,'No','Yes', 'Yes');
end

gelData.pocketPositions=pocketPositions;