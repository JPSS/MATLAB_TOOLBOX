%% Load RT-PCR MX-P3005 instrument data in text format 1
%delete first line of text file before loading. entire measurement requires same filters over time and wells

%originalDataCell is sorted cell array original data from text file 
%Segment / Ramp Plateau / Ramp Plateau Number / Well Number / Dye / Cycle Number / Fluorescence / Temperature

%filters is filters used in measurements
%filterNumber is number of filters used in measurements
%wells is wells measured
%wellNumber is number of wells measured
%totalMeasurementNumber is total number of datapoints
%wellMeasurementNumber is number of datapoints per well = totalMeasurementNumber/wellNumber
%filterMeasurementNumber is number of datapoints per well+filter = wellMeasurementNumber/filterNumber

%sortedDataCell is originalDataCell sorted according to Well, Dye, Segment, Ramp/Plateau number, cycle
%InstrumentData is 2d double array with (i,j) = measurement i of well+filter j
%InstrumentDataTemperatures is 2d double array with (i,j) = temperature i of well+filter j
%wellNames is cell array with well number / filter type / total measurement number  
%averagedData is 2d double array with (i,j) = (averaged measurement i, well+filter j)

clearvars

sampleNames={};
%sampleNames={'Fob20','Fob20b','JR1','JR1b','JR2','JR2b','empty','empty'}
%sampleNames={'Fob20','Fob20b','KT','KTb','KTc','KTd','KTe','KTf'}
% sampleNames={'Fob20','Fob20b','stack2','stack2b','stack3','stack3b','stack4','stack4b','stack5','stack5b','stack6','stack6b','stack7','stack7b'...
%     ,'stack8','stack8b','stack9','stack9b','stack10','stack10b','stack11','stack11b','stack12','stack12b','stack13','stack13b','stack14','stack14b'...
%     ,'stack15','stack15b','stack16','stack16b','stack17','stack17b','stack18','stack18b','stack19','stack19b','stack20','stack20b'}
%sampleNames={'Fob20','Fob20b','JX','JXb','empty','empty','empty','empty'}
%sampleNames={'LCa','LCb','Fob20a','Fob20b'}

[filename, pathname]=uigetfile('.txt');                         %select file to open

currentFile=fopen([pathname filename],'r');                     %open file

fseek(currentFile, 0, 'eof');                                   %Get file size
fileSize = ftell(currentFile);
frewind(currentFile);

data = fread(currentFile, fileSize, 'uint8');                   %Count number of line, 10 is ascii linebreak
numLines = sum(data == 10)-2;

frewind(currentFile);
firstLine=textscan(currentFile, '%s',1,'delimiter','\n')        %read experiment file name
originalDataNames=textscan(currentFile,'%s',8,'delimiter','\t') %read original data column names

originalDataCell=textscan(currentFile,'%d\t%s\t%d\t%d\t%s\t%d\t%f\t%f',numLines,'delimiter','\t');%read original data
for i=[1,3,4,6,7,8]
    originalDataCell{i}=num2cell(originalDataCell{i});
end
originalDataCell=[originalDataCell{:}];

fclose(currentFile);

filters=sortrows(unique(originalDataCell(:,5)))                 %filters used
filterNumber=int32(size(filters,1));                            %number of filters used

wells=sortrows(unique(cell2mat(originalDataCell(:,4))))         %wells measured
wellNumber=int32(size(wells,1))                                 %number of wells scanned

totalMeasurementNumber=numLines;
wellMeasurementNumber=totalMeasurementNumber/wellNumber;
filterMeasurementNumber=wellMeasurementNumber/filterNumber;

sortedDataCell=sortrows(originalDataCell,[4 5 1 6 3]);          %sort data according to Well, Dye, Segment, cycle, Ramp/Plateau number 
                                                                                                                                                                             
InstrumentData=zeros(filterMeasurementNumber,wellNumber*filterNumber);%matrix of all measurements (i,j) = measurement i of well+filter j

InstrumentDataTemperatures=zeros(filterMeasurementNumber,wellNumber*filterNumber);
                                                    
wellNames=cell(3,wellNumber*filterNumber);                      %cell array with well number / filter type / total measurement number       


for currentWell=1:wellNumber                                    %fill InstrumentData,InstrumentDataTemperature Matrix with measurements for each well/filter
    for currentFilter=1:filterNumber
        startPoint=(currentWell-1)*wellMeasurementNumber+(currentFilter-1)*filterMeasurementNumber+1;   %first measurement of well+filter
        endPoint=(currentWell-1)*wellMeasurementNumber+(currentFilter)*filterMeasurementNumber;         %last measurement of well+filter
        InstrumentData(:,(currentWell-1)*filterNumber+currentFilter)=cell2mat(sortedDataCell(startPoint:endPoint,7));
        InstrumentDataTemperatures(:,(currentWell-1)*filterNumber+currentFilter)=cell2mat(sortedDataCell(startPoint:endPoint,8));
        wellNames(1,(currentWell-1)*filterNumber+currentFilter)=sortedDataCell(startPoint,4);
        wellNames(2,(currentWell-1)*filterNumber+currentFilter)=sortedDataCell(startPoint,5);
        wellNames(3,(currentWell-1)*filterNumber+currentFilter)=num2cell((currentWell-1)*filterNumber+currentFilter);
    end
end

%% calculate averaged intensities in multiple measurements per cycle

currentPos=1;                                                   %current measurement Nr in InstrumentData
newPos=1;                                                       %current position in averagedData
currentValues=InstrumentData(currentPos,:);                     %current sum of measurements at measurement cycle
currentTemperatures=InstrumentDataTemperatures(currentPos,:);
currentLength=1;                                                %current number of measurements at current measurement cycle

while currentPos~=filterMeasurementNumber                       %average over multiple measurements at one measurement cycle
    if isequal(sortedDataCell(currentPos,6),sortedDataCell(currentPos+1,6)) %add another measurement to measurement cycle
        currentValues=currentValues+InstrumentData(currentPos+1,:);
        currentTemperatures=currentTemperatures+InstrumentDataTemperatures(currentPos+1,:);
        currentLength=currentLength+1;
    else                                                        %new measurement cycle
        averagedData(newPos,:)=currentValues/currentLength;
        averagedDataTemperature(newPos,:)=currentTemperatures/currentLength;
        newPos=newPos+1;
        currentValues=InstrumentData(currentPos+1,:);
        currentTemperatures=InstrumentDataTemperatures(currentPos+1,:);
        currentLength=1;
    end
    currentPos=currentPos+1;
end
averagedData(newPos,:)=currentValues/currentLength;             %add final measurement cycle
averagedDataTemperature(newPos,:)=currentTemperatures/currentLength;

%% display averaged data

for i=1:filterNumber
    currentFigure=figure;
    plot(averagedData(:,i:filterNumber:wellNumber*filterNumber))
    title(filters(i,:));

    if isempty(sampleNames)
        legend(num2str([wellNames{1,i:filterNumber:wellNumber*filterNumber}]'))
    else
        legend(sampleNames)
    end    
        
    set(findall(currentFigure,'-property','FontSize'),'FontSize',18)    %change all font sizes
    set(currentFigure, 'Units', 'centimeters')                                    %set paper size to figure size
    set(currentFigure, 'PaperUnits', 'centimeters')
    figureSize=get(currentFigure, 'Position');
    set(currentFigure, 'PaperSize', figureSize(3:4))
end

%% save averaged data

file=fopen([pathname filename(1:length(filename)-38) '_sorted.txt'], 'w');%open file to write
                                                                
for i=1:wellNumber*filterNumber                                 %write 'wellNr_filterType' or 'sampleName_filterType' in each column header
    if isempty(sampleNames)
        fprintf(file,[num2str(wellNames{1,i}) '_' wellNames{2,i} '\t']);
    else
        fprintf(file,[sampleNames{fix((i+1)/filterNumber)} '_' wellNames{2,i} '\t']);
    end
end

fprintf(file,'\n');
fclose(file);

%save averaged data to file
dlmwrite([pathname filename(1:length(filename)-38) '_sorted.txt'], averagedData, 'delimiter', '\t','-append')
