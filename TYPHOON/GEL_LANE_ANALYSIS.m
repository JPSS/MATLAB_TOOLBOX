%% analyze 1D gel lane data
%meanY is average of all Y values in selected area
%initialize arrays 


numberOfLanes=size(horizontalIntegrals,2);
laneLength=size(horizontalIntegrals,1);

meanY=zeros(numberOfLanes,1);               %means of lane intensities
meanXdotY=zeros(numberOfLanes,1);           %means of lane intensities multiplied with running distance from gel pocket location

weightedMean=zeros(numberOfLanes,1);        %weighted means of lanes
normSampleStandardDeviationY=zeros(numberOfLanes,1);%normalized sample standard deviations in intensity
weightedSampleStandardDeviation=zeros(numberOfLanes,1);%weighted sample standard deviatoins of lanes
normDotProduct=zeros(numberOfLanes,1);      %normalized dot products of lanes
gelPocketLocation=zeros(numberOfLanes,1);   %user chosen gel pocket locations

laneFigure=1;                               %figure to display original lane profiles
weightedMeanFigure=2;                       %figure to display weighted mean of lanes
weightedSampleStandardDeviationFigure=3;    %figure to display weighted sample standard deviations of lanes
normSampleStandardDeviationYFigure=4;       %figure to display nomalized sample standard deviations in Intensity
gelPocketFigure=5;                          %figure to display lane to pick gel pocket location
meanYFigure=6;                              %figure to display means in Intensity
correctionFigure=7;                         %figure to display lanes for running distance correction
normDotProductFigure=8;                     %figure to display normalized dot products of lanes


%% collect gel pocket locations


minValue=0;
for currentLane=1:numberOfLanes
    minValue=min(minValue,min(horizontalIntegrals(:,currentLane)));
end

for currentLane=1:numberOfLanes
  
    currentData=transpose(horizontalIntegrals(:,currentLane));      %load current lane data
    if minValue<0
        currentData=currentData-minValue;
    end
    
    figure(laneFigure);
    clf
    hold on
    plot(currentData,'b');
    plot(horizontalIntegrals(:,currentLane),'r');
    title('data: red, zero shifted data: blue, choose gel pocket, press any key');
    
    h = imrect;
    
    pause
    
    pos = int32(getPosition(h));
    
    delete(h);
   
    [maxValue maxPosition] = max(horizontalIntegrals(pos(1):pos(1)+pos(3),currentLane));
    gelPocketLocation(currentLane)=double(maxPosition+pos(1));

    %currentGelPocketLocation=ginput(1);                             %choose gel pocket location
    %gelPocketLocation(currentLane)=currentGelPocketLocation(1,1);
    
end

clf


%% select range for data analysis, choose filename modifier

prompt= {'filename modifier'};
dlg_title='Input';
num_lines=1;
def={''};
parameters = inputdlg(prompt,dlg_title,num_lines,def);
prefix_modifier=parameters{1};

button1='No';
while strcmp(button1,'No')                      %select data range

    figure(laneFigure);                         %display original lane profiles
    clf
    hold all
    minValue=0;
    for currentLane=1:numberOfLanes
        minValue=min(minValue,min(horizontalIntegrals(:,currentLane)));
        plot(horizontalIntegrals(:,currentLane));
    end
    title('SELECT DATA RANGE')
    hold off

    selectedRange=ginput(2);                    %select range for data analysis 
    rangeStart=round(selectedRange(1,1));
    rangeEnd=round(selectedRange(2,1));

    figure(laneFigure);                         %display original lane profiles
    clf
    hold all
    for currentLane=1:numberOfLanes
        plot(horizontalIntegrals(rangeStart:rangeEnd,currentLane));
    end
    title('check range selection, press any key')
    hold off
    
    pause
    button1 = questdlg('range ok?','is it?' ,'No','Yes', 'Yes');

end



%% calculate means and standard deviations of lanes/ lane intensities

for currentLane=1:numberOfLanes
    
    currentData=transpose(horizontalIntegrals(:,currentLane));      %load current lane data
    if minValue<0
        currentData=currentData-minValue;
    end

    currentRangeStart=round(rangeStart-gelPocketLocation(1)+gelPocketLocation(currentLane));%shift ranges by gel pocket location shift
    currentRangeEnd=round(rangeEnd-gelPocketLocation(1)+gelPocketLocation(currentLane));
    
    normalizedCurrentData=currentData/sum(currentData(currentRangeStart:currentRangeEnd));%normalized lane data
  
    meanY(currentLane)=mean(currentData(currentRangeStart:currentRangeEnd));
    meanXdotY(currentLane)=mean(currentData(currentRangeStart:currentRangeEnd).*(rangeStart:rangeEnd));
    
    weightedMean(currentLane)=meanXdotY(currentLane)/meanY(currentLane)-gelPocketLocation(1);
   
    normSampleStandardDeviationY(currentLane)=sqrt(var(normalizedCurrentData(currentRangeStart:currentRangeEnd)));
    
    weightedSampleStandardDeviation(currentLane)=sqrt(var((rangeStart:rangeEnd),normalizedCurrentData(currentRangeStart:currentRangeEnd)));
    
    hold off

end


%% calculate normalized dot product

for currentLane=1:numberOfLanes-1
  
    currentData=transpose(horizontalIntegrals(:,currentLane));
    if minValue<0
        currentData=currentData-minValue;
    end
    currentRangeStart=round(rangeStart-gelPocketLocation(1)+gelPocketLocation(currentLane));%shift ranges by gel pocket location shift
    currentRangeEnd=round(rangeEnd-gelPocketLocation(1)+gelPocketLocation(currentLane));
    
    nextData=transpose(horizontalIntegrals(:,currentLane+1));
    if minValue<0
        nextData=nextData-minValue;
    end
    nextRangeStart=round(rangeStart-gelPocketLocation(1)+gelPocketLocation(currentLane+1));%shift ranges by gel pocket location shift
    nextRangeEnd=round(rangeEnd-gelPocketLocation(1)+gelPocketLocation(currentLane+1));
    
                                                                                %normalize lane data according to dot product
    currentData=currentData/sqrt(dot(currentData(currentRangeStart:currentRangeEnd),currentData(currentRangeStart:currentRangeEnd)));
    nextData=nextData/sqrt(dot(nextData(nextRangeStart:nextRangeEnd),nextData(nextRangeStart:nextRangeEnd)));
    
    normDotProduct(currentLane)=dot(currentData(currentRangeStart:currentRangeEnd),nextData(nextRangeStart:nextRangeEnd));
    
end

%% normalize with control lanes
%select control lanes, weighted mean distances will be normalized by average
%chosen control lane distance from control lane pocket location

% button1 = questdlg('correct with control lanes?','do you?' ,'No','Yes', 'Yes');
% 
% if strcmp(button1,'Yes')
%     prompt= {'number of control lanes'};
%     dlg_title='Input';
%     num_lines=1;
%     def={'1'};
%     parameters = inputdlg(prompt,dlg_title,num_lines,def);
%     numControlLanes=str2double(parameters(1));
% 
%     correctionLength=0;
% 
%     for i=1:numControlLanes
%         prompt= {'location control lane'};
%         dlg_title='Input';
%         num_lines=1;
%         def={'1'};
%         parameters = inputdlg(prompt,dlg_title,num_lines,def);
%         currentLane=str2double(parameters(1));
% 
%         figure(correctionFigure);
%         clf
%         plot(horizontalIntegrals(:,currentLane));
%         title('select correction reference location');
%         currentCorrectionLocation=ginput(1);
% 
%         correctionLength=correctionLength+currentCorrectionLocation(1,1)-gelPocketLocation(currentLane);
%     end
% 
%     correctionLength=correctionLength/numControlLanes
% 
%     weightedMean=weightedMean/correctionLength
% else
%     correctionLength=1;
% end

%% normalize with 2 control lanes
%select control lanes, weighted mean distances will be normalized by linear
%fit of running speed between the two control lanes

button1 = questdlg('correct with control lanes?','do you?' ,'No','Yes', 'Yes');

if strcmp(button1,'Yes')
    
    prompt= {'location control lane 1'};
    dlg_title='Input';
    num_lines=1;
    def={'1'};
    parameters = inputdlg(prompt,dlg_title,num_lines,def);
    lane1=str2double(parameters(1));

    figure(correctionFigure);
    clf
    plot(horizontalIntegrals(:,lane1));
    title('select correction reference location');
    
    h = imrect;
    pause
    pos = int32(getPosition(h));
    delete(h);
    [maxValue maxPosition] = max(horizontalIntegrals(pos(1):pos(1)+pos(3),lane1));
    
    correctionLocation1=double(maxPosition+pos(1))
   
    correctionLength1=correctionLocation1-gelPocketLocation(lane1)
    
    prompt= {'location control lane 2'};
    dlg_title='Input';
    num_lines=1;
    def={'1'};
    parameters = inputdlg(prompt,dlg_title,num_lines,def);
    lane2=str2double(parameters(1));

    figure(correctionFigure);
    clf
    plot(horizontalIntegrals(:,lane2));
    title('select correction reference location');
    
    h = imrect;
    pause
    pos = int32(getPosition(h));
    delete(h);
    [maxValue maxPosition] = max(horizontalIntegrals(pos(1):pos(1)+pos(3),lane2));
    
    correctionLocation2=double(maxPosition+pos(1))
    
    correctionLength2=correctionLocation2-gelPocketLocation(lane2)

    for i=1:numberOfLanes
        weightedMean(i)=weightedMean(i)/(correctionLength1+(i-lane1)*(correctionLength2-correctionLength1)/(lane2-lane1));
    end
    
end


%% plot results

figure(weightedMeanFigure);
clf
plot(weightedMean);
axis([1 numberOfLanes 0 1.1*max(weightedMean)])
title('weighted mean');

figure(weightedSampleStandardDeviationFigure);
clf
plot(weightedSampleStandardDeviation);
axis([1 numberOfLanes 0 1.1*max(weightedSampleStandardDeviation)])
title('weighted Sample Standard Deviation');

figure(normSampleStandardDeviationYFigure);
clf
plot(normSampleStandardDeviationY);
axis([1 numberOfLanes 0 1.1*max(normSampleStandardDeviationY)])
title('normalized sample Standard Deviation Y');

figure(gelPocketFigure);
clf
plot(gelPocketLocation);
axis([1 numberOfLanes 0 1.1*max(gelPocketLocation)])
title('gel pocket location');

figure(meanYFigure);
clf
plot(meanY);
axis([1 numberOfLanes 0 1.1*max(meanY)])
title('mean Y');

figure(normDotProductFigure);
clf
plot(normDotProduct);
axis([1 numberOfLanes-1 0 1.1*max(normDotProduct)])
title('normDotProduct');


%% fit 2 state exponential decay with time offset model to weighted mean data

button1 = questdlg('do you want a time fit?','do you?' ,'No','Yes', 'Yes');
button2 = 'No';

coeffs=zeros(9,1);                                                  %fit data coefficients

run fittype_collection;                                            %load fit types

opts=optimset('Algorithm','interior-point');

while strcmp(button1,'Yes') && strcmp(button2,'No')                 %collect time data
    prompt= {'tStart','tEnd','tStep'};
    dlg_title='Input';
    num_lines=1;
    def={'10','120','10'};
    parameters = inputdlg(prompt,dlg_title,num_lines,def);
    tStart=str2double(parameters(1));
    tEnd=str2double(parameters(2));
    tStep=str2double(parameters(3));

    time=transpose(tStart:tStep:tEnd);

    prompt= {'startLane','endLane'};                                %select lanes for fit
    dlg_title='Input';
    num_lines=1;
    def={'1',num2str(numberOfLanes)};
    parameters = inputdlg(prompt,dlg_title,num_lines,def);
    coeffs(8)=str2double(parameters(1));
    coeffs(9)=str2double(parameters(2));
    
    prompt= {'tOffset','tau','xa','xb','alpha','beta','gamma','startLane','endLane'};%collect starting values for fit
    dlg_title='Input';
    num_lines=1;
    def={'5','30',num2str(weightedMean(coeffs(8))),num2str(weightedMean(coeffs(9))),'10','1','10',num2str(coeffs(8)),num2str(coeffs(9))};
    parameters = inputdlg(prompt,dlg_title,num_lines,def);
    coeffs(1)=str2double(parameters(1));
    coeffs(2)=str2double(parameters(2));
    coeffs(3)=str2double(parameters(3));
    coeffs(4)=str2double(parameters(4));
    coeffs(5)=str2double(parameters(5));
    coeffs(6)=str2double(parameters(6));
    coeffs(7)=str2double(parameters(7));
    coeffs(8)=str2double(parameters(8));
    coeffs(9)=str2double(parameters(9));
    
                                                                    %parameters=[tOffset tau xa xb alpha beta gamma dt]
                                                                    %params=[tOffset tau xa xb alpha beta gamma]
    fitType1=meanAtoBFit;
    xData1=time;
    yData1=weightedMean(coeffs(8):coeffs(9));
    parameterOrder1=[1 2 3 4];

    fitType2=normDotProductFit;
    xData2=time(1:length(time)-1);
    yData2=normDotProduct(coeffs(8):coeffs(9)-1);
    parameterOrder2=[5 6 7 1 2 8];

    parameters=transpose(coeffs(1:7));
    
    
    A=[ 1 0 0 0 0 0 0  ;                                                %fit coefficient constraint matrix
    -1 0 0 0 0 0 0 ;
    0 1 0 0 0 0 0 ;
    0 -1 0 0 0 0 0 ;
    0 0 1 0 0 0 0 ;
    0 0 -1 0 0 0 0 ;
    0 0 0 1 0 0 0 ;
    0 0 0 -1 0 0 0 ;
    0 0 0 0 1 0 0 ;
    0 0 0 0 -1 0 0 ;
    0 0 0 0 0 1 0 ;
    0 0 0 0 0 -1 0 ;
    0 0 0 0 0 0 1 ;
    0 0 0 0 0 0 -1 ];

    b=[ 10000 0 10000 0 10000 0  10000 0 10000 0 10000 0 10000 0 ];     %fit coefficient constraints

    coeffs(1:7)=fmincon(@(params)generalErrorSquared2Fits( fitType1, xData1, yData1, parameterOrder1, fitType2, xData2, yData2, parameterOrder2, [params tStep]),parameters,A,b,[],[],[],[],[],opts); 

    figure(weightedMeanFigure);
    clf
    hold all
    plot(time,weightedMean(coeffs(8):coeffs(9)));
    plot(tStart:1:tEnd,meanAtoBFit(coeffs(1),coeffs(2),coeffs(3),coeffs(4),tStart:1:tEnd));
    axis([time(1) time(coeffs(9)-coeffs(8)+1) 0 1.1*max(weightedMean(coeffs(8):coeffs(9)))])
    title('weighted mean');
       
    figure(normDotProductFigure);
    clf
    hold all
    plot(time(1:coeffs(9)-coeffs(8)),normDotProduct(coeffs(8):coeffs(9)-1));
    plot(tStart:1:(tEnd-tStep),normDotProductFit(coeffs(5),coeffs(6),coeffs(7),coeffs(1),coeffs(2),tStep,tStart:1:(tEnd-tStep)));
    axis([time(1) time(coeffs(9)-coeffs(8)) 0 1.1*max(normDotProduct(coeffs(8):coeffs(9)-1))])
    title('normalized dot product');
    
    button2 = questdlg('Fit Ok?','is it?' ,'No','Yes', 'Yes');
end

coeffs                                                             %print fit results



%% save data
%each lane is one row 
%x1=gelPocketPositions
%x2=weightedMean
%x3=weighted Sample standard deviation
%x4=normalized sample standard deviation Y
%x5=Y integrated
%x6=normalized dot product
%x7=fit of weighted Mean
%x8=fit normDotProduct
%x9=alpha
%x10=beta
%x11=gamma
%x12=tOffset
%x13=tau
%x14=xa
%x15=xb
%x16=lane Left
%x17=lane Right
%x18=rangeStart
%x19=rangeEnd
%x20=cutoffFit1

currentFile=fopen([path_out filesep prefix_out prefix_modifier '_lanes_analysis.txt'],'w');

for i=1:numberOfLanes

    fprintf(currentFile,'%e\t',gelPocketLocation(i));
    fprintf(currentFile,'%e\t',weightedMean(i));
    fprintf(currentFile,'%e\t',weightedSampleStandardDeviation(i));
    fprintf(currentFile,'%e\t',normSampleStandardDeviationY(i));
    fprintf(currentFile,'%e\t',meanY(i)*(rangeEnd+1-rangeStart));
    if i<numberOfLanes
        fprintf(currentFile,'%e\t',normDotProduct(i));
    end

    if i>=coeffs(8)&&i<=coeffs(9)
        fprintf(currentFile,'%e\t',meanAtoBFit(coeffs(1),coeffs(2),coeffs(3),coeffs(4),time(i-coeffs(8)+1)));
    else
        fprintf(currentFile,'\t');
    end
    
    if i>=coeffs(8)&&i<=coeffs(9)-1
        fprintf(currentFile,'%e\t',normDotProductFit(coeffs(5),coeffs(6),coeffs(7),coeffs(1),coeffs(2),tStep,time(i-coeffs(8)+1)));
    else
        fprintf(currentFile,'\t');
    end
    
    if i==1
        for j=1:9
            fprintf(currentFile,'%e\t',coeffs(j));
        end
        fprintf(currentFile,'%e\t',rangeStart);
        fprintf(currentFile,'%e\t',rangeEnd);
        fprintf(currentFile,'%e',cutoffFit1);
    end
    fprintf(currentFile,'\n');    
end

fclose(currentFile);




