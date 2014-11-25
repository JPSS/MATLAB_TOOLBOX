function gelData = get_gel_lanes(imageData,varargin)
%% Loads image, fits lanes according to step function convolved with gaussian
%   INPUTS:
%   [ optional:[ weights for channels] ]
%   OUTPUT:
%   gelData struct with .profiles .lanePositions .imageNames
%   .profiles is cell array {nr_image,nr_lane} of lane profiles (horizontal integrals)
%   .lanePositions is array nr_lanes * [left edge, right edge, top edge, bottom edge]
%   .imageNames is cell array of image name strings

%% load image weight factors

if isempty(varargin)                                                            %check weights for different channels
    weight_factors=num2cell(ones(1,imageData.nrImages));
elseif length(varargin)~=imageData.nrImages
    error('wrong number of weights for images')
else
    weight_factors=varargin;
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
h = imrect;
wait(h);
selectedArea = int32(getPosition(h));

button='No';
while strcmp(button,'No')                                       %find lane fit start values using find_lanes_roots()
    lanePositions=find_lanes_intersect(image_sum, selectedArea);
    close all

    plot_image_ui(image_sum);
    title('preselected lanes');
    hold on
    for i=1:size(lanePositions,1)
        rectangle('Position', lanePositions(i,:), 'EdgeColor', 'r'), hold on
    end

    button = questdlg('are the selected starting lanes ok?','are the selected starting lanes ok?' ,'No','Yes', 'Yes');
end
nr_lanes=size(lanePositions,1);

close all

%% if there are negative vertical sums (due to bg correction), raise vertical sums to 0

area = image_sum( selectedArea(2):selectedArea(2)+selectedArea(4), selectedArea(1):selectedArea(1)+selectedArea(3));
verticalSum = sum(area);
minValue=min(verticalSum);
close all
plot(verticalSum,'red')
hold on
plot(verticalSum-min(verticalSum))
plot(1:selectedArea(3),0)
legend('original','move to 0')

button = questdlg('move min value to 0?','move min value to 0?' ,'No','Yes', 'Yes');
if strcmp(button,'Yes')
    verticalSum=verticalSum-minValue;
    area=area-minValue/double(selectedArea(4));
end
close all

%% improve estimated lane by fitting 1 gaussian convolved with step function
%   fit gauss step convolution to estimated lane areas
%   if lane fit function area smaller than (1-cutoffFit), increase lane size
%   
%   laneFits{Nlanes} is cell of lanes of [fitobject, gof, output] from fit()
%   lanesCorrected is array of lanes of [ leftBorder, rightBorder ]

prompt={'set cutoff parameter for fit improvement'};
def={'0.01'};
temp = inputdlg(prompt, 'set cutoff parameter for fit improvement', 1, def);
cutoffFit=str2double(temp);

laneFits = cell(size(lanePositions,1),3);
lanesFitted=zeros(size(lanePositions,1),2);

gaussConvolveStepFit=fittype('gauss_convolve_step(x,sigma,stepEnd,stepHeight,stepStart)');      %select fitting function

for i=1:nr_lanes                                                                                %fit each lane
    leftEdge=double(lanePositions(i,1)-selectedArea(1));                                        %left/right edge relative to selected area
    rightEdge=double(lanePositions(i,1)+lanePositions(i,3)-selectedArea(1));
    fprintf('fitting lane number %i\n',i);
    
    fitParameters=[50,rightEdge-round((rightEdge-leftEdge)/4),verticalSum(round(leftEdge+(rightEdge-leftEdge)/2)),leftEdge+round((rightEdge-leftEdge)/4)];
    tempError=1;
    
    %shift lane edges by one pixel left or right and fit function again
    while tempError>cutoffFit
        
        if (rightEdge-fitParameters(2))>=(fitParameters(4)-leftEdge)
            leftEdge=leftEdge-1;
            if leftEdge==0
                error('lane edge fit moved outside of selected data range, left side');
            end
        else
            rightEdge=rightEdge+1;
            if rightEdge>selectedArea(3)
                error('lane edge fit moved outside of selected data range, right side');
            end
        end
        
        %fit gauss convolved on step function to data in current lane selection
        [laneFits{i,1:3}]=generalFit2D(gaussConvolveStepFit,leftEdge:rightEdge,verticalSum(leftEdge:rightEdge),[-Inf -Inf -Inf -Inf],[Inf Inf Inf Inf],fitParameters);
        fitParameters=coeffvalues(laneFits{i,1});

        %calculate fit integral outside lane selection
        tempError=1-gauss_convolve_step_integral(fitParameters,leftEdge,rightEdge)/((fitParameters(2)-fitParameters(4))*fitParameters(3));
    end
    lanesFitted(i,1)=leftEdge;
    lanesFitted(i,2)=rightEdge;
end

%% plot all corrected lane fits

plot(verticalSum(1:selectedArea(3)))
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
close all

%% calculate lane profiles (horizontal integrals) for each lane
%   laneProfiles is array of lanes integrated horizontally over fitted lane size

laneProfiles=cell(imageData.nrImages,nr_lanes);  %zeros(selectedArea(4),size(lanePositions,1),nr_images);

for curr_image=1:imageData.nrImages
    hold all
    
    tempImage=imageData.images{curr_image};
    tempArea=tempImage( selectedArea(2):selectedArea(2)+selectedArea(4), selectedArea(1):selectedArea(1)+selectedArea(3));

    for curr_lane=1:size(lanePositions,1)
        laneProfiles{curr_image,curr_lane}=sum(tempArea(1:selectedArea(4),lanesFitted(curr_lane,1):lanesFitted(curr_lane,2)),2);
        plot(laneProfiles{curr_image,curr_lane})
        title('fitted profiles - press any key');
    end
    pause
    close all
end

%% return lane data
%   lanePositions is array of nr_lanes* [left edge, right edge, top edge, bottom edge]

for i=1:nr_lanes
    lanePositions(i,1)=selectedArea(1)+lanesFitted(i,1)-1;
    lanePositions(i,2)=selectedArea(1)+lanesFitted(i,2)-1;
    lanePositions(i,3)=selectedArea(2);
    lanePositions(i,4)=selectedArea(2)+selectedArea(4);
end

gelData=struct('profiles',{laneProfiles},'lanePositions',lanePositions,'imageNames',{imageData.filenames});
end
