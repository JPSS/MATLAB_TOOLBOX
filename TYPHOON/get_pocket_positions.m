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
figure('units','normalized','outerposition',[0 0 1 1]);
while strcmp(button,'No')                                       %find pocket locations by finding maximum value in range
    clf
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
    button = questdlg('are the pocket positions ok?','are the pocket positions ok?' ,'No','Yes', 'Yes');
end

gelData.pocketPositions=pocketPositions;