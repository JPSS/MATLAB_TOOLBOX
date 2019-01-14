function lane_profile_data = get_gel_lanes(imageData,varargin)
%% Loads image, fits lanes according to step function convolved with gaussian
%   INPUTS:
%   imageData from load_gel_image.m
%   optional: {weight_factors}: weights for channels. Lanes are determined from weighted sum of all channels
%   optional: cutoff: data window for single lane is broadend until less than cutoff fraction of fit function is outside the
%               data window shown to fit (exact: the range width from fit center to the closer of the two data window edges,
%               applied to both directions)
%               lane width is edges of fit beyond which cutoff fraction of fit function (integral) lies
%   optional: display: switches display of fitting results 
%   optional: selection_type: select initial lane positions for fitting by hand or using threshold slider
%   optional: preset_laneArea: switch presetting selection of image area to be used for fitting to top half of gel
%   optional: vertical_correction: switch shifting vertical sum of gel so that no negative values remain
%   optional: preset_threshold = predetermined threshold value for lane detection
%       threshold is set to maximum value of smoothed horizontal profile multiplied with threshold value
%   OUTPUT:
%   lane_profile_data struct with .profiles .lanePositions .imageNames
%   .profiles is cell array {nr_image,nr_lane} of lane profiles (horizontal integrals)
%   .lanePositions is array nr_lanes * [left edge, right edge, top edge, bottom edge]
%   .imageNames is cell array of image name strings
%   .fullProfiles is cell array {nr_image,nr_lane} of lane profiles (horizontal integrals) over entire gel image vertical length
%   .pathnames are pathnames of imageData
%   .filenames are filenames of imageData
% Example: profileData = get_gel_lanes(imageData, 'display', 'off', 'cutoff', 0.01);

%% parse input variables
p = inputParser;
% required parameter
addRequired(p,'imageData');

% optional parameter: weight_factors 
default_weight_factors = num2cell(ones(1,imageData.nrImages));
addParameter(p,'weight_factors', default_weight_factors,  @iscell); 

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
addParameter(p,'selection_type', default_selection_type,  @(x) any(validatestring(x,expected_selection_type)));

% optional parameter: preset_laneArea (if on sets lane area selection rectangle to top half of image)
default_preset_laneArea = 'off';
addParameter(p,'preset_laneArea', default_preset_laneArea);

% optional parameter: vertical_correction (if on vertical correction question dialog is shown)
default_vertical_correction = 'on';
expected_vertical_correction = {'on', 'off'};
addParameter(p,'vertical_correction', default_vertical_correction,  @(x) any(validatestring(x,expected_vertical_correction))); % check vertical_correction is 'on' or 'off'

% optional parameter: preset threshold value for lane detection 
default_preset_threshold  = nan;
addParameter(p, 'preset_threshold', default_preset_threshold,  @isnumeric);

parse(p, imageData, varargin{:});
display_bool = strcmp(p.Results.display, 'on');
weight_factors = p.Results.weight_factors;
cutoffFit = p.Results.cutoff;
selection_type = p.Results.selection_type;
preset_laneArea_parameter = p.Results.preset_laneArea;
vertical_correction_bool = strcmp(p.Results.vertical_correction,'on');
preset_threshold = p.Results.preset_threshold;

%% load image weight factors

if length(weight_factors) ~= imageData.nrImages
    error('wrong number of weights for images')
end

%% find estimated lanes using find_lanes_roots.m
%   pos is position information of selected lane area [ left edge, top edge, width, height ]
%   lanePositions(Nlanes) is array of lanes of [ left edge, top edge, width, height ]
%   nr_lanes is number of lanes found

%calculated weighted sum of image data from all channels
image_sum = weight_factors{1}.*imageData.images{1};                           
for i=2:imageData.nrImages
  image_sum = image_sum + weight_factors{i}.*imageData.images{i};
end

%select area for lane determination
plot_image_ui(image_sum)                                        
title('Select area of lanes')
% preset lane area is on, draw half size rectangle
if strcmp(preset_laneArea_parameter, 'on')
    h = imrect(gca,[1 1 size(imageData.images{1},2)-1 0.5*size(imageData.images{1},1)]);
    wait(h);
    selectedArea = int32(getPosition(h));

% preset lane area is off, draw full rectangle
elseif strcmp(preset_laneArea_parameter, 'off')
    h = imrect;
    wait(h);
    selectedArea = int32(getPosition(h));

% preset lane area is on with positions delivered, draw and accept rectangle
else
    title('Preselected gel area (Press any key to continue)')
    rectangle('Position', preset_laneArea_parameter)
    selectedArea = preset_laneArea_parameter;
    %h = imrect(gca, preset_laneArea_parameter);
    pause
end

if strcmp(selection_type, 'manual')
    % manual detection of lanes
    close all
    lanePositions = manual_lane_selection(image_sum, selectedArea);

else 
    % automatic detecion of lanes
    button='No';
    %find lane fit start values using find_lanes_roots()
    while strcmp(button,'No')
        lanePositions = find_lanes_intersect(image_sum, selectedArea, 30, 'preset_threshold', preset_threshold);
        close all

        fig = plot_image_ui(image_sum);
        title('preselected lanes');
        hold on
        for i = 1:size(lanePositions,1)
            rectangle('Position', lanePositions(i,:), 'EdgeColor', 'r'), hold on
        end
        
        % if no preset lane selection threshold, check if lanes are correctly selected
        if isnan(preset_threshold)
            button = questdlg('are the selected starting lanes ok?','are the selected starting lanes ok?' ,'No','Yes', 'Yes');
        else
            pause
            button = 'Yes';
        end
        close(fig);

    end
end
nr_lanes = size(lanePositions,1);

%% if there are negative vertical sums (due to bg correction), raise vertical sums to 0

area = image_sum( selectedArea(2):selectedArea(2)+selectedArea(4), selectedArea(1):selectedArea(1)+selectedArea(3));
verticalSum = sum(area);

if vertical_correction_bool

    minValue = min(verticalSum);
    fig = figure;
    plot(verticalSum,'red')
    hold on
    plot(verticalSum-min(verticalSum))
    plot([1 selectedArea(3)],[0 0])
    legend('original','move to 0')

    button = questdlg('move min value to 0?','move min value to 0?' ,'No','Yes', 'Yes');

    if strcmp(button,'Yes')
        verticalSum = verticalSum - minValue;
    end
    close(fig)
end

%% improve estimated lane by fitting 1 gaussian convolved with step function
%   fit gauss step convolution to estimated lane areas
%   if lane fit function area smaller than (1-cutoffFit), increase lane size
%   
%   laneFits{Nlanes} is cell of lanes of [fitobject, gof, output] from fit()
%   lanesCorrected is array of lanes of [ leftBorder, rightBorder ]

if cutoffFit < 0
    prompt = {'set cutoff parameter for fit improvement'};
    def = {'0.01'};
    temp = inputdlg(prompt, 'set cutoff parameter for fit improvement', 1, def);
    cutoffFit = str2double(temp);
end

laneFits = cell(size(lanePositions, 1), 3);
lanesFitted = zeros(size(lanePositions, 1), 2);

 %select fitting function
gaussConvolveStepFit = fittype('gauss_convolve_step(x,sigma,stepEnd,stepHeight,stepStart)');

%fit each lane
for i = 1:nr_lanes
    %left/right edge relative to selected area
    leftEdge = double(lanePositions(i,1) - selectedArea(1));                                        
    rightEdge = double(lanePositions(i,1) + lanePositions(i,3) - selectedArea(1));
    fprintf('fitting lane number %i\n',i);
    
    fitParameters = [20, rightEdge, verticalSum(round((leftEdge + rightEdge)/2)), leftEdge];
    tempError = 1;
    
    %shift lane edges by one pixel left or right and fit function again
    while tempError > cutoffFit
        
        leftEdge = leftEdge - 1;
        if leftEdge == 0
           error('lane edge fit moved outside of selected data range, left side');
        end
        rightEdge = rightEdge + 1;
        if rightEdge > selectedArea(3)
            error('lane edge fit moved outside of selected data range, right side');
        end        
        
        %fit gauss convolved on step function to data in current lane selection
        fitParameters(2) = rightEdge;
        fitParameters(4) = leftEdge;
        [laneFits{i,1:3}] = general_fit_2d(gaussConvolveStepFit, leftEdge:rightEdge, verticalSum(leftEdge:rightEdge)...
                                            , [-Inf -Inf -Inf -Inf], [Inf Inf Inf Inf], fitParameters);
        
        newFitParameters=coeffvalues(laneFits{i,1});

        %calculate fit integral outside lane selection
        
        %center of fitted step function (equals gel pocket center)
        fitCenter = 0.5 * (newFitParameters(2) + newFitParameters(4));
        %smaller of the distances from the fit center to the edge of the data window being fitted
        visibleWidth = min(fitCenter - leftEdge, rightEdge - fitCenter);
        tempError = 1 - gauss_convolve_step_integral(newFitParameters, fitCenter - visibleWidth,fitCenter + visibleWidth)...
                            / ((newFitParameters(2) - newFitParameters(4)) * newFitParameters(3));
    end
    %find fit width such that (1-cutOffFit) is within fit range
    tempFunctionHandle = @(x)gauss_convolve_step_integral(newFitParameters,fitCenter-x,fitCenter+x)/((newFitParameters(2)-newFitParameters(4))*newFitParameters(3))-(1-cutoffFit);
    fitWidth = fzero(tempFunctionHandle,0);
    lanesFitted(i,1) = round(fitCenter - fitWidth);
    lanesFitted(i,2) = round(fitCenter + fitWidth);
end

%% plot all corrected lane fits
if display_bool
    fig = figure;
    plot(verticalSum(1:selectedArea(3)));
    hold on
    for i = 1:size(lanePositions,1)
        fitParameters = coeffvalues(laneFits{i,1});
        plot(laneFits{i,1})
        x = [lanesFitted(i,1), lanesFitted(i,1)];
        y = [0, fitParameters(3)];
        plot(x, y, 'LineWidth', 0.5, 'color', 'black')
        x = [lanesFitted(i,2),lanesFitted(i,2)];
        y = [0, fitParameters(3)];
        plot(x, y, 'LineWidth', 0.5, 'color', 'black')
        title('fitted lanes - press any key');
    end
    pause
    close(fig)
end

%% calculate lane profiles (horizontal integrals) for each lane
%   laneProfiles is array of lanes integrated horizontally over fitted lane size
%   fullLaneProfiles is array of lanes integrated horizontally over fitted lane size horizontally over the entire gel vertically

laneProfiles = cell(imageData.nrImages,nr_lanes);
fullLaneProfiles = cell(imageData.nrImages,nr_lanes);

for curr_image = 1:imageData.nrImages
    
    tempImage = imageData.images{curr_image};
    tempArea = tempImage( selectedArea(2):selectedArea(2)+selectedArea(4), selectedArea(1):selectedArea(1)+selectedArea(3));

    for curr_lane=1:size(lanePositions,1)
        laneProfiles{curr_image,curr_lane} = sum(tempArea(1:selectedArea(4),lanesFitted(curr_lane,1):lanesFitted(curr_lane,2)),2);
        fullLaneProfiles{curr_image,curr_lane} = sum(tempImage(:,selectedArea(1)-1+lanesFitted(curr_lane,1):selectedArea(1)-1+lanesFitted(curr_lane,2)),2);      
    end
    
    % plot
    if display_bool
        hold all
        for curr_lane = 1:size(lanePositions,1)
            plot(laneProfiles{curr_image,curr_lane})
            title('fitted profiles - press any key');
        end
        pause
        close all
    end

end

%% return lane data
%   lanePositions is array of nr_lanes* [left edge, right edge, top edge, bottom edge]

for i = 1:nr_lanes
    lanePositions(i,1) = selectedArea(1)+lanesFitted(i,1)-1;
    lanePositions(i,2) = selectedArea(1)+lanesFitted(i,2)-1;
    lanePositions(i,3) = selectedArea(2);
    lanePositions(i,4) = selectedArea(2)+selectedArea(4)-1;
end

lane_profile_data = struct('profiles', {laneProfiles},...
                           'lanePositions', lanePositions,...
                           'imageNames', {imageData.filenames},...
                           'fullProfiles', {fullLaneProfiles},...
                           'metadata', {imageData.metadata});
lane_profile_data.pathnames = imageData.pathnames;
lane_profile_data.filenames = imageData.filenames;

if exist('imageData.background')
    lane_profile_data.background = imageData.background;
end

end
