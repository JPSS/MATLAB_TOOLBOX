function [ output_args ] = de_bruijn_analysis( gelData )
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
        normalizedProfiles{i}=gelData.profiles{deBruijnChannel,i}./(gelData.profiles{normalizationChannel,i}-min([gelData.profiles{normalizationChannel,i}(gelData.profiles{normalizationChannel,i}<0); 0.00001]));
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
    plot(normalizedProfiles{i});
end
hold off


laneNumbersString=inputdlg('enter comma seperated start and end lane');
laneNumbers=str2num(laneNumbersString{1});

timeStepsString=inputdlg('enter comma seperated timesteps');
timeSteps=str2num(timeStepsString{1});

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

%0,10,20,30,40,50,60,70,80,90,100,110,120,180

output_args={deBruijnSum,normalizationSum,deBruijnSumNormalized,normalizedProfiles,gelData,fitTotal,fitNormalized};


end
