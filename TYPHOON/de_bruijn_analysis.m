function [ output_args ] = de_bruijn_analysis( gelData, imageData )
%% do de_bruijn_analysis on gel data
%   INPUTS:
%   gelData struct returned by get_gel_lanes.m
%   OUTPUT:

nr_lanes=size(gelData.lanePositions,1);

display(gelData.imageNames);
deBruijnChannelString=inputdlg('which image is the de bruijn channel?');
deBruijnChannel=str2num(deBruijnChannelString{1});

deBruijnSum=zeros(nr_lanes,1);                       %calculate integrals of deBruijn profiles
for i=1:nr_lanes
    deBruijnSum(i)=sum(gelData.profiles{deBruijnChannel,i});
end

%normalize de bruijne data with book keeping oligo data?
button = questdlg('Normalize de bruijne data?','normalize','normalize','do not normalize','do not normalize');
if strcmp(button,'normalize')
    
    normalizationChannelString=inputdlg('which image is the normalization channel?');
    normalizationChannel=str2num(normalizationChannelString{1});
    
    normalizationSum=zeros(nr_lanes,1);                       %calculate integrals of normalization profiles
    for i=1:nr_lanes
        normalizationSum(i)=sum(gelData.profiles{normalizationChannel,i});
    end
    
    deBruijnSumNormalized=deBruijnSum./normalizationSum;
    
    normalizedProfiles=cell(nr_lanes,1);
    for i=1:nr_lanes
        normalizedProfiles{i}=max(0,gelData.profiles{deBruijnChannel,i})./max(0.00001,gelData.profiles{normalizationChannel,i});
    end 
end

fig1=figure;
subplot(2,2,1)
plot(deBruijnSum);
title('total deBruijn intensity sum')

subplot(2,2,2)
plot(normalizationSum);
title('book keeping oligo intensity sum')

subplot(2,2,3)
plot(deBruijnSumNormalized);
title('normalized de Bruijn intensity sum')

subplot(2,2,4)
hold on
for i=1:nr_lanes
    plot(gelData.profiles{normalizationChannel,i});
end
hold off
rect = imrect;
wait(rect);
selectedRange = int32(getPosition(rect));
delete(rect);

stepSize=1;
normData=[gelData.profiles{normalizationChannel,:}];
profileData=[normalizedProfiles{:}];

cutoffWidth=max(max(normData(selectedRange(1):selectedRange(1)+selectedRange(3),:)));
graphLength=length(gelData.profiles{1,1});
laneWidth=100;
len2=round(nr_lanes*laneWidth/graphLength);
imageArray=ones(graphLength*len2,nr_lanes*laneWidth);
opacityArray=zeros(length(1:graphLength)*len2,nr_lanes*laneWidth);
for i=1:nr_lanes
    for j=1:stepSize:graphLength
        width=max(0,min(normData(j,i),cutoffWidth));
        qualityColor=profileData(j,i);
        startLeft=i*laneWidth-laneWidth/2;
        startRight=i*laneWidth-laneWidth/2+1;
        endLeft=startRight-round((width/cutoffWidth)*(laneWidth/2));
        endRight=startLeft+round((width/cutoffWidth)*(laneWidth/2));
        imageArray(j*len2:j*len2+len2,endLeft:endRight)=qualityColor;
        opacityArray(j*len2:j*len2+len2,endLeft:endRight)=1;
    end
end
fig=figure;
fig=plot_image_ui(imageArray,'colormap',flipud(colormap),'type','image');
set(fig,'AlphaData',opacityArray);


fig=figure;
imageDebruijn=imageData.images{1}./imageData.images{2};
fig=plot_image_ui(imageDebruijn,'colormap',flipud(colormap),'type','image');
title('Select area of max intensity')
rect = imrect;
wait(rect);
selectedArea = int32(getPosition(rect));
delete(rect);
title('de bruijn quality')
maxIntensity=max(max(imageData.images{2}(selectedArea(2):selectedArea(2)+selectedArea(4),selectedArea(1):selectedArea(1)+selectedArea(3))));

alphaMatrix=min(1,(imageData.images{2}/maxIntensity));
colorbar
set(fig,'AlphaData',alphaMatrix);

fitTotal=[];
fitNormalized=[];
button = questdlg('fit de bruijne data?','fit','fit','do not fit','do not fit');
if strcmp(button,'fit')
    laneNumbersString=inputdlg('enter comma seperated start and end lane');
    laneNumbers=str2num(laneNumbersString{1});

    timeStepsString=inputdlg('enter comma seperated timesteps');
    timeSteps=transpose(str2num(timeStepsString{1}));

    ft=fittype( 'exp_offset(x,amplitude,exponentialFactor,offset)' );
    fitTotal=struct('fitresult',{{}},'gof',{{}},'output',{{}});
    [ fitTotal.fitresult, fitTotal.gof, fitTotal.output]=general_fit_2d(ft,timeSteps,deBruijnSum(laneNumbers(1):laneNumbers(2)),[0,-inf,-inf],[inf,0,inf],[mean(deBruijnSum(laneNumbers(1):laneNumbers(2))),1/mean(timeSteps),0]);

    fitNormalized=struct('fitresult',{{}},'gof',{{}},'output',{{}});
    [ fitNormalized.fitresult, fitNormalized.gof, fitNormalized.output]=general_fit_2d(ft,timeSteps,deBruijnSumNormalized(laneNumbers(1):laneNumbers(2)),[0,-inf,-inf],[inf,0,inf],[mean(deBruijnSumNormalized(laneNumbers(1):laneNumbers(2))),1/mean(timeSteps),0]);

    figure(fig1);
    subplot(2,2,1)
    hold on
    plot(feval(fitTotal.fitresult,timeSteps));
    hold off

    subplot(2,2,3)
    hold on
    plot(feval(fitNormalized.fitresult,timeSteps));
    hold off
end

output_args={deBruijnSum,normalizationSum,deBruijnSumNormalized,normalizedProfiles,gelData,fitTotal,fitNormalized};

return

%display lane quality and intensity over migration distance, color is quality, width is intensity
fig1=figure;
colorMap=flipud(colormap);
stepSize=2;
normData=[gelData.profiles{normalizationChannel,:}];
profileData=[normalizedProfiles{:}];
colorLimitLow=min(min(profileData(selectedRange(1):selectedRange(1)+selectedRange(3),:)));
colorLimitHigh=max(max(profileData(selectedRange(1):selectedRange(1)+selectedRange(3),:)));
profileData=min(colorLimitHigh,max(colorLimitLow,profileData));
cutoffWidth=max(max(normData(selectedRange(1):selectedRange(1)+selectedRange(3),:)));
graphLength=length(gelData.profiles{1,1});
axis([0 nr_lanes+1 0 graphLength]);
for i=1:nr_lanes
    for j=1:stepSize:graphLength
        width=max(0,min(gelData.profiles{2,i}(j),cutoffWidth));
        qualityColor=colorMap(round(1+63*(profileData(j,i)-colorLimitLow)/(colorLimitHigh-colorLimitLow)),:);
        rectangle('Position',[i-width/(2*cutoffWidth) graphLength-(j-stepSize/2) width/cutoffWidth stepSize],'EdgeColor','none','LineStyle','none','FaceColor',qualityColor)
        hold on
    end
end
hold off

%0,10,20,30,40,50,60,70,80,90,100,110,120,180


end
