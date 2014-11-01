%% Loads image (multiple channels possible), fits lanes according to step function convolved with gaussian
% returns horizontalIntegrals(lane length ,Nr. lanes) 
%loads fittype collection

run('my_prefs')

run fittype_collection;                                            %load fit types

data_dir = [ getenv('HOME') filesep 'Documents' ]; % where data is typically stored

path0 = cd;

%% load images
%selects images to open
%filename{Nimg} are filenames of files
%pathname{Nimg} are pathnames of files

options.WindowStyle='normal';
prompt={'How many images do you want to load:'};
def={'1'};
tmp = inputdlg(prompt, 'How many images do you want to load', 1, def, options);
n_img = str2double(tmp(1));

filename = cell(n_img, 1);
pathname = cell(n_img, 1);
cd(data_dir)
for i=1:n_img
    [filename{i} pathname{i}]=uigetfile('*.tif',['Select image ' num2str(i) ' of ' num2str(n_img)]);
    cd(pathname{i})
end
cd(path0)

%% create output folder

pname = inputdlg({'Output folder and prefix:'}, 'Output folder and prefix' , 1, {filename{1}(1:size(filename{1},2)-4)} );
prefix_out = pname{1};
path_out = [pathname{1} prefix_out ];
mkdir(path_out);

%% load, bg correct images and find lanes
%opens selected images (rotates), saves double data
%img{Nimg} are image double data
%img_bg{Nimg} are image double data background corrected using bg_correct_ui.m

img = cell(n_img, 1);
img_bg = cell(n_img, 1);

for i=1:n_img
    %bg correct
    img{i} = double(imread([pathname{i} filesep filename{i}])); 
    
    plot_image_ui(img{i})
    button = questdlg('Rotate?','Rotate','Rotate','No','No');
    if strcmp(button,'Rotate') %load old data
        img{i} = imrotate(img{i}, -90);
    end
    close all
    
    img_bg{i} = bg_correct_ui(img{i}, 'Background correction');
   
end
 %% find estimated lanes using find_lanes_roots.m
 %sums all image double data into one, then selects lane area, then selects
 %estimated lanes
 %img_sum is sum of all image double data
 %lanes(Nlanes) is array of lanes of [ leftBorder, Top, width, height ]
 %area is image double data in selected lane area
 %pos is position information of selected lane area [ leftBorder, Top, width, height ]
 
img_sum = img_bg{1};

for i=2:n_img
  img_sum = img_sum + img_bg{i};
end

plot_image_ui(img_sum)
title('Select area of lanes')
h = imrect;
position = wait(h);
pos = int32(getPosition(h));
area = img_sum( pos(2):pos(2)+pos(4), pos(1):pos(1)+pos(3));
verticalSum = sum(area);

button='No';

while strcmp(button,'No')
    lanes=find_lanes_roots(img_sum, pos);

    close all

    plot_image_ui(img_sum);
    title('preselected lanes');
    hold on
    for i=1:size(lanes,1)
        rectangle('Position', lanes(i,:), 'EdgeColor', 'r'), hold on
    end

    button = questdlg('Lanes ok?','ARE THEY???' ,'No','Yes', 'Yes');
end

close all

%% if there are negative vertical sums (due to bg correction), raise them to 0
%adds min verticalSum value to all of area

minValue=min(verticalSum);
close all
plot(verticalSum,'red')
hold on
plot(verticalSum-min(verticalSum))
plot(1:pos(3),0)
legend('original bg corrected','move to 0')
button = questdlg('move graph to 0?','whats it gonna be?' ,'No','Yes', 'Yes');
if strcmp(button,'Yes')
    verticalSum=verticalSum-minValue;
    area=area-minValue/double(pos(4));
end
close all

%% improve estimated lane by fitting 1 gaussian convolved with step function
%fits gauss step convolution to estimated lane areas, increases estimated lane
%area untill 1-cutoffFit1 of fit function integral is inside lane area
%laneFits{Nlanes} is cell of lanes of [fitobject, gof, output] from fit()
%lanesCorrected is array of lanes of [ leftBorder, rightBorder ]

prompt={'cutoff parameter fit improvement 1'};
def={'0.01'};
temp = inputdlg(prompt, 'cutoff parameter fit improvement 1', 1, def);
cutoffFit1=str2double(temp);

laneFits = cell(size(lanes,1),3);
lanesCorrected=zeros(size(lanes,1),2);

for i=1:size(lanes,1)
    startPoint=double(lanes(i,1)-pos(1))
    endPoint=double(lanes(i,1)+lanes(i,3)-pos(1))
    
    %fit gauss convolved on step function to data in current lane selection
    tempParameters=[50,endPoint-round((endPoint-startPoint)/4),verticalSum(round(startPoint+(endPoint-startPoint)/2)),startPoint+round((endPoint-startPoint)/4)];
    %[laneFits{i,1:3}]=gaussConvolveStepFit(startPoint:endPoint,verticalSum(startPoint:endPoint),tempParameters);
    [laneFits{i,1:3}]=generalFit2D(gaussConvolveStepFit,startPoint:endPoint,verticalSum(startPoint:endPoint),[-Inf -Inf -Inf -Inf],[Inf Inf Inf Inf],tempParameters);
    tempParameters=coeffvalues(laneFits{i,1});
    %calculate fit integral outside lane selection
    tempError=1-gaussConvolveStepIntegral(tempParameters,startPoint,endPoint)/((tempParameters(2)-tempParameters(4))*tempParameters(3));
    laneFits{i,2}.rsquare;
    
    %shift lane edges by one pixel left or right and fit function again
    while tempError>cutoffFit1
        
        if (endPoint-tempParameters(2))>=(tempParameters(4)-startPoint)
            startPoint=startPoint-1;
            if startPoint==0
                'FUCK FUCK FUCK lane edge is outside of data range selected, left side'
            end
        else
            endPoint=endPoint+1;
            if endPoint>pos(3)
                'FUCK FUCK FUCK lane edge is outside of data range selected, right side'
            end
        end
               
        [laneFits{i,1:3}]=generalFit2D(gaussConvolveStepFit,startPoint:endPoint,verticalSum(startPoint:endPoint),[-Inf -Inf -Inf -Inf],[Inf Inf Inf Inf],tempParameters);
        tempParameters=coeffvalues(laneFits{i,1});
        tempError=1-gaussConvolveStepIntegral(tempParameters,startPoint,endPoint)/((tempParameters(2)-tempParameters(4))*tempParameters(3));
        laneFits{i,2}.rsquare;
        
        close all

    end
    lanesCorrected(i,1)=startPoint;
    lanesCorrected(i,2)=endPoint;

end

%% plot all corrected lane fits

plot(verticalSum(1:pos(3)))
hold on
for i=1:size(lanes,1)
    tempParameters=coeffvalues(laneFits{i,1});
    plot(laneFits{i,1})
    x=[lanesCorrected(i,1),lanesCorrected(i,1)];
    y=[0,tempParameters(3)];
    plot(x,y,'LineWidth',0.5)
    x=[lanesCorrected(i,2),lanesCorrected(i,2)];
    y=[0,tempParameters(3)];
    plot(x,y,'LineWidth',0.5)
    
end
pause
close all

%% calculate horizontal integrals for each lane
%horizontalIntegrals are array of lanes integrated horizontally over
%estimated lane size

hold all

horizontalIntegrals=zeros(pos(4),size(lanes,1));

for i=1:size(lanes,1)
    horizontalIntegrals(:,i)=sum(area(1:pos(4),lanesCorrected(i,1):lanesCorrected(i,2)),2);
    plot(horizontalIntegrals(:,i))
end
pause
close all

%% save lane positions _lanes_positions.txt
%saves lane positions to output folder
%value 1= left edge
%value 2= right edge
%value 3= upper edge
%value 4= lower edge

currentFile=fopen([path_out filesep prefix_out '_lanes_positions.txt'],'w');

area = img_sum( pos(2):pos(2)+pos(4), pos(1):pos(1)+pos(3));
horizontalIntegrals(:,i)=sum(area(1:pos(4),lanesCorrected(i,1):lanesCorrected(i,2)),2);

for i=1:size(lanes,1)
    fprintf(currentFile,'%f\t',pos(1)+lanesCorrected(i,1)-1);
    fprintf(currentFile,'%f\t',pos(1)+lanesCorrected(i,2)-1);
    fprintf(currentFile,'%f\t',pos(2));
    fprintf(currentFile,'%f\t',pos(2)+pos(4));
    fprintf(currentFile,'\n');
end

fclose(currentFile);


%% save horizontal integral data to _lanes_data.txt
%saves horizontalIntegrals data to output folder

A_out = zeros(pos(4), size(lanes,1));

for i=1:size(lanes,1)
    A_out(:,i)= horizontalIntegrals(:,i);
end
dlmwrite([path_out filesep prefix_out '_lanes_data.txt'], A_out, 'delimiter' , '\t')


