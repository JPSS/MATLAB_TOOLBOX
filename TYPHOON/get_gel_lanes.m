function gelData = get_gel_lanes(imageData,varargin)
%% Loads image, fits lanes according to step function convolved with gaussian
%   INPUTS:
%   [ optional:[ weights for channels] ]
%   OUTPUT:
%   gelData struct with .profiles .lanePositions .imageNames
%   .profiles is cell array {nr_image,nr_lane} of lane profiles (horizontal integrals)
%   .lanePositions is array nr_lanes * [left edge, right edge, top edge, bottom edge]
%   .imageNames is cell array of image name strings
%   .fullProfiles is cell array {nr_image,nr_lane} of lane profiles (horizontal integrals) over entire gel image vertical length
%   .pathnames are pathnames of imageData
%   .filenames are filenames of imageData
% Example: profileData = get_gel_lanes(gelData, 'display', 'off', 'cutoff', 0.01);

%% parse input variables
    p = inputParser;
    % required parameter
    addRequired(p,'imageData');
    
    % optional parameter: weight_factors 
    default_weight_factors = num2cell(ones(1,imageData.nrImages));
    addParameter(p,'weight_factors', default_weight_factors,  @iscell); % check 

    % optional parameter: cutoff for fit
    default_cutoffFit = -1;
    addParameter(p,'cutoff', default_cutoffFit,  @isnumeric); % check 

    % optional parameter: display (if off does not plot results)
    default_display = 'on';
    expected_display = {'on', 'off'};
    addParameter(p,'display', default_display,  @(x) any(validatestring(x,expected_display))); % check display is 'on' or 'off'
    
    % optional parameter: selection_type, for initial lane selection
    default_selection_type = 'automatic';
    expected_selection_type = {'automatic', 'manual'};
    addParameter(p,'selection_type', default_selection_type,  @(x) any(validatestring(x,expected_selection_type))); % check display is 'on' or 'off'
    
    % optional parameter: background (if on copies .background from imageData.background)
    default_background = 'off';
    expected_background = {'on', 'off'};
    addParameter(p,'background', default_background,  @(x) any(validatestring(x,expected_background))); % check background is 'on' or 'off'
    
    % optional parameter: preset_laneArea (if on sets lane area selection rectangle to top half of image)
    default_preset_laneArea = 'off';
    expected_preset_laneArea = {'on', 'off'};
    addParameter(p,'preset_laneArea', default_preset_laneArea,  @(x) any(validatestring(x,expected_preset_laneArea))); % check preset_laneArea is 'on' or 'off'

    %
    parse(p, imageData, varargin{:});
    display_bool = strcmp(p.Results.display, 'on');
    weight_factors = p.Results.weight_factors;
    cutoffFit = p.Results.cutoff;
    selection_type = p.Results.selection_type;
    background_bool = strcmp(p.Results.background,'on');
    preset_laneArea_bool = strcmp(p.Results.preset_laneArea,'on');

%% load image weight factors

if length(weight_factors)~=imageData.nrImages
    error('wrong number of weights for images')
end

%% find estimated lanes using find_lanes_roots.m
%   pos is position information of selected lane area [ left edge, top edge, width, height ]
%   lanePositions(Nlanes) is array of lanes of [ left edge, top edge, width, height ]
%   nr_lanes is number of lanes found
 
image_sum = weight_factors{1}.*imageData.images{1};                           %calculated weighted sum of channel image data
for i=2:imageData.nrImages
  image_sum = image_sum + weight_factors{i}.*imageData.images{i};
end

plot_image_ui(image_sum)                                        %select area for lane determination
title('Select area of lanes')
if preset_laneArea_bool
    h = imrect(gca,[1 1 size(imageData.images{1},2)-1 0.5*size(imageData.images{1},1)]);
else
    h = imrect
end
wait(h);
selectedArea = int32(getPosition(h));
if strcmp(selection_type, 'manual')
    % manual detection of lanes
    close all

    lanePositions=manual_lane_selection(image_sum, selectedArea);

else 
    % automatic detecion of lanes
    button='No';
    while strcmp(button,'No')                                       %find lane fit start values using find_lanes_roots()
        lanePositions=find_lanes_intersect(image_sum, selectedArea);
        close all

        fig=plot_image_ui(image_sum);
        title('preselected lanes');
        hold on
        for i=1:size(lanePositions,1)
            rectangle('Position', lanePositions(i,:), 'EdgeColor', 'r'), hold on
        end
        button = questdlg('are the selected starting lanes ok?','are the selected starting lanes ok?' ,'No','Yes', 'Yes');
        close(fig);

    end
end
nr_lanes=size(lanePositions,1);

%% if there are negative vertical sums (due to bg correction), raise vertical sums to 0

area = image_sum( selectedArea(2):selectedArea(2)+selectedArea(4), selectedArea(1):selectedArea(1)+selectedArea(3));
verticalSum = sum(area);
minValue=min(verticalSum);
fig=figure;
plot(verticalSum,'red')
hold on
plot(verticalSum-min(verticalSum))
plot([1 selectedArea(3)],[0 0])
legend('original','move to 0')

button = questdlg('move min value to 0?','move min value to 0?' ,'No','Yes', 'Yes');

if strcmp(button,'Yes')
    verticalSum=verticalSum-minValue;
    area=area-minValue/double(selectedArea(4));
end
close(fig)

%% improve estimated lane by fitting 1 gaussian convolved with step function
%   fit gauss step convolution to estimated lane areas
%   if lane fit function area smaller than (1-cutoffFit), increase lane size
%   
%   laneFits{Nlanes} is cell of lanes of [fitobject, gof, output] from fit()
%   lanesCorrected is array of lanes of [ leftBorder, rightBorder ]

if cutoffFit < 0
    prompt={'set cutoff parameter for fit improvement'};
    def={'0.01'};
    temp = inputdlg(prompt, 'set cutoff parameter for fit improvement', 1, def);
    cutoffFit=str2double(temp);
end

laneFits = cell(size(lanePositions,1),3);
lanesFitted=zeros(size(lanePositions,1),2);

gaussConvolveStepFit=fittype('gauss_convolve_step(x,sigma,stepEnd,stepHeight,stepStart)');      %select fitting function

for i=1:nr_lanes                                                                                %fit each lane
    leftEdge=double(lanePositions(i,1)-selectedArea(1));                                        %left/right edge relative to selected area
    rightEdge=double(lanePositions(i,1)+lanePositions(i,3)-selectedArea(1));
    fprintf('fitting lane number %i\n',i);
    
    fitParameters=[20,rightEdge,verticalSum(round((leftEdge+rightEdge)/2)),leftEdge];
    tempError=1;
    
    %shift lane edges by one pixel left or right and fit function again
    while tempError>cutoffFit
        
        leftEdge=leftEdge-1;
        if leftEdge==0
           error('lane edge fit moved outside of selected data range, left side');
        end
        rightEdge=rightEdge+1;
        if rightEdge>selectedArea(3)
            error('lane edge fit moved outside of selected data range, right side');
        end        
        
        %fit gauss convolved on step function to data in current lane selection
        fitParameters(2)=rightEdge;
        fitParameters(4)=leftEdge;
        [laneFits{i,1:3}]=general_fit_2d(gaussConvolveStepFit,leftEdge:rightEdge,verticalSum(leftEdge:rightEdge),[-Inf -Inf -Inf -Inf],[Inf Inf Inf Inf],fitParameters);
        
        newFitParameters=coeffvalues(laneFits{i,1});

        %calculate fit integral outside lane selection
        fitCenter=0.5*(newFitParameters(2)+newFitParameters(4));                          %center of fitted step function (equals gel pocket center)
        visibleWidth=min(fitCenter-leftEdge,rightEdge-fitCenter);                   %width of fitted step function inside current lane window
        tempError=1-gauss_convolve_step_integral(newFitParameters,fitCenter-visibleWidth,fitCenter+visibleWidth)/((newFitParameters(2)-newFitParameters(4))*newFitParameters(3));
    end
    %find fit width such that (1-cutOffFit) is within fit range
    tempFunctionHandle=@(x)gauss_convolve_step_integral(newFitParameters,fitCenter-x,fitCenter+x)/((newFitParameters(2)-newFitParameters(4))*newFitParameters(3))-(1-cutoffFit);
    fitWidth=fzero(tempFunctionHandle,0);
    lanesFitted(i,1)=round(fitCenter-fitWidth);
    lanesFitted(i,2)=round(fitCenter+fitWidth);
end

%% plot all corrected lane fits
if display_bool
    fig=figure;
    plot(verticalSum(1:selectedArea(3)));
    hold on
    for i=1:size(lanePositions,1)
        fitParameters=coeffvalues(laneFits{i,1});
        plot(laneFits{i,1})
        x=[lanesFitted(i,1),lanesFitted(i,1)];
        y=[0,fitParameters(3)];
        plot(x,y,'LineWidth',0.5,'color','black')
        x=[lanesFitted(i,2),lanesFitted(i,2)];
        y=[0,fitParameters(3)];
        plot(x,y,'LineWidth',0.5,'color','black')
        title('fitted lanes - press any key');
    end
    pause
    close(fig)
end

%% calculate lane profiles (horizontal integrals) for each lane
%   laneProfiles is array of lanes integrated horizontally over fitted lane size
%   fullLaneProfiles is array of lanes integrated horizontally over fitted lane size horizontally over the entire gel vertically

laneProfiles=cell(imageData.nrImages,nr_lanes);
fullLaneProfiles=cell(imageData.nrImages,nr_lanes);

for curr_image=1:imageData.nrImages
    
    tempImage=imageData.images{curr_image};
    tempArea=tempImage( selectedArea(2):selectedArea(2)+selectedArea(4), selectedArea(1):selectedArea(1)+selectedArea(3));

    for curr_lane=1:size(lanePositions,1)
        laneProfiles{curr_image,curr_lane}=sum(tempArea(1:selectedArea(4),lanesFitted(curr_lane,1):lanesFitted(curr_lane,2)),2);
        fullLaneProfiles{curr_image,curr_lane}=sum(tempImage(:,selectedArea(1)-1+lanesFitted(curr_lane,1):selectedArea(1)-1+lanesFitted(curr_lane,2)),2);      
    end
    
    % plot
    if display_bool
        hold all
        for curr_lane=1:size(lanePositions,1)
            plot(laneProfiles{curr_image,curr_lane})
            title('fitted profiles - press any key');
        end
        pause
        close all
    end

end

%% return lane data
%   lanePositions is array of nr_lanes* [left edge, right edge, top edge, bottom edge]

for i=1:nr_lanes
    lanePositions(i,1)=selectedArea(1)+lanesFitted(i,1)-1;
    lanePositions(i,2)=selectedArea(1)+lanesFitted(i,2)-1;
    lanePositions(i,3)=selectedArea(2);
    lanePositions(i,4)=selectedArea(2)+selectedArea(4)-1;
end

gelData=struct('profiles',{laneProfiles},'lanePositions',lanePositions,'imageNames',{imageData.filenames},'fullProfiles',{fullLaneProfiles});
gelData.pathnames=imageData.pathnames;
gelData.filenames=imageData.filenames;

if background_bool
    gelData.background=imageData.background;
end

end
