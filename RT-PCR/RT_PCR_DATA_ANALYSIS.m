%% Process loaded RT-PCR-MX-P3005 data
%averagedData is averaged RT-PCR data (averaged measurement, well+filter)
%backgroundWells is array of background wells (relative numbering 1,2,3...)
%backgroundNumber is number of background wells
%averageBackground is array of background data of each filter
%averagedDataBack is averagedData with background substracted in non-background-wells
%averagedDataBackAvg is averagedDataBack with multiple identical wells averaged


%% subtract background, divide by background, multiply by mean background (to keep magnitude of intensity constant)

button='No';
while strcmp(button,'No')                                   %select background wells

    backgroundWellsString=inputdlg('comma-separated background well nrs');
    backgroundWells=str2num(backgroundWellsString{1})
    backgroundNumber=length(backgroundWells);

    figure
    for i=1:backgroundNumber                                %display selected background wells
        plot(averagedData(:,(backgroundWells(i)-1)*filterNumber+1:(backgroundWells(i)*filterNumber)))
        hold on
    end
    hold off
    
    button = questdlg('wells ok?','is it?' ,'No','Yes', 'Yes');
    clf
end

averageBackground=zeros(size(averagedData,1),filterNumber); %averaged backgrounds for filters
                                                            
for i=1:backgroundNumber                                    %calculate averaged backgrounds
    for j=1:filterNumber
        averageBackground(:,j)=averageBackground(:,j)+averagedData(:,(backgroundWells(i)-1)*filterNumber+j);
    end
end
averageBackground=averageBackground./double(backgroundNumber);

averagedDataBack=averagedData;
for i=1:wellNumber                                          %subtract average background from non-background data, divide by average background, multiply with mean average background
    for j=1:filterNumber
        if ismember(i,backgroundWells)
            averagedDataBack(:,(i-1)*filterNumber+j)=averagedData(:,(i-1)*filterNumber+j);
        else
            averagedDataBack(:,(i-1)*filterNumber+j)=((averagedData(:,(i-1)*filterNumber+j)-averageBackground(:,j))./averageBackground(:,j)).*mean(averageBackground(:,j));
        end
    end
end

%% Plot filter data

for i=1:filterNumber
    currentFigure=figure;
    plot(averagedDataBack(:,i:filterNumber:wellNumber*filterNumber))
    title(filters(i,:));
    
    xlabel('measurement points')                                           %label x axis
    ylabel('Fluorscence [a.u.]')                                          %label y axis
    
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

%% join multiple identical samples

buttonAvg = questdlg('multiple wells?','multiple wells?' ,'No','Yes', 'Yes');

if strcmp(buttonAvg,'Yes')
    numberDuplicatsString=inputdlg('number of identical samples');%select number of identical samples
    numberDuplicats=str2num(numberDuplicatsString{1})

    averagedDataBackAvg=zeros(size(averagedData,1),size(averagedData,2)/numberDuplicats);

    for i=1:wellNumber/numberDuplicats                          %average over multiples of same sample
        for j=1:filterNumber
            for k=1:numberDuplicats
                averagedDataBackAvg(:,(i-1)*filterNumber+j)=averagedDataBackAvg(:,(i-1)*filterNumber+j)+averagedDataBack(:,((i-1)*numberDuplicats+k-1)*filterNumber+j);
            end
            averagedDataBackAvg(:,(i-1)*filterNumber+j)=averagedDataBackAvg(:,(i-1)*filterNumber+j)./numberDuplicats;
        end
    end    
end


%% Plot averagedDataBackAvg data

if strcmp(buttonAvg,'Yes')
    for i=1:filterNumber
        currentFigure=figure;
        plot(averagedDataBackAvg(:,i:filterNumber:wellNumber*filterNumber/numberDuplicats))
        
        xlabel('measurement points')                                           %label x axis
        ylabel('Fluorscence [a.u.]')                                          %label y axis
        
        if isempty(sampleNames)
            legend(num2str(1:wellNumber/numberDuplicats))
        else
            legend(sampleNames{1:numberDuplicats:end})
        end
        title(filters(i,:));
        
        set(findall(currentFigure,'-property','FontSize'),'FontSize',18)    %change all font sizes
        set(currentFigure, 'Units', 'centimeters')                                    %set paper size to figure size
        set(currentFigure, 'PaperUnits', 'centimeters')
        figureSize=get(currentFigure, 'Position');
        set(currentFigure, 'PaperSize', figureSize(3:4))
    end
end

%% save background-corrected data

file=fopen([pathname filename(1:length(filename)-38) '_minBackground.txt'], 'w');%open file to write
           
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
dlmwrite([pathname filename(1:length(filename)-38) '_minBackground.txt'], averagedDataBack, 'delimiter', '\t','-append')

%% save background-corrected averaged data    

if strcmp(buttonAvg,'Yes')
    file=fopen([pathname filename(1:length(filename)-38) '_minBackgroundAvg.txt'], 'w');%open file to write                                                    

    for i=1:wellNumber*filterNumber/numberDuplicats             %write 'wellNr_filterType' or 'sampleName_filterType' in each column header
        if isempty(sampleNames)
            fprintf(file,[num2str(fix((i+1)/filterNumber)) '_' wellNames{2,i} '\t']);
        else
            fprintf(file,[sampleNames{fix((i+1)/filterNumber)*numberDuplicats} '_' wellNames{2,i} '\t']);
        end
    end
    
    fprintf(file,'\n');
    fclose(file);
                                                                %save averaged data to file
    dlmwrite([pathname filename(1:length(filename)-38) '_minBackgroundAvg.txt'], averagedDataBackAvg, 'delimiter', '\t','-append')
end



%%



    currentFigure=figure;
    plot(averagedDataTemperature(35:end,1),averagedDataBack(35:end,[3*3]))
    title(filters(3));
    currentLegend=legend('14 sticky TATA')
    xlabel('temperature [?C]')                                           %label x axis
    ylabel('Fluorscence [a.u.]')                                          %label y axis
    
    set(findall(currentFigure,'-property','FontSize'),'FontSize',18)    %change all font sizes
    set(currentFigure, 'Units', 'centimeters')                                    %set paper size to figure size
    set(currentFigure, 'PaperUnits', 'centimeters')
    figureSize=get(currentFigure, 'Position');
    set(currentFigure, 'PaperSize', figureSize(3:4))
    
    set(currentLegend,'color','none')
    
    set(gca, 'Color', 'none')
    export_fig temp.pdf -transparent
    
    
    currentFigure=figure;
    plot(averagedDataTemperature(6:end,1),averagedDataBackAvg(6:end,48:3:60))
    title(filters(3));
    legend(sampleNames{1:2:end})
    xlabel('temperature [?C]')                                           %label x axis
    ylabel('Fluorscence [a.u.]')                                          %label y axis
    
    set(findall(currentFigure,'-property','FontSize'),'FontSize',18)    %change all font sizes
    set(currentFigure, 'Units', 'centimeters')                                    %set paper size to figure size
    set(currentFigure, 'PaperUnits', 'centimeters')
    figureSize=get(currentFigure, 'Position');
    set(currentFigure, 'PaperSize', figureSize(3:4))

    
    bla=averagedDataBackAvg(6:end,3:3:end);
    for i=1:20
        bla(:,i)=bla(:,i)/max(bla(:,i));
    end
    

    blu=averagedDataBackAvg(338:588,3:3:end)+flipud(averagedDataBackAvg(589:839,3:3:end))+averagedDataBackAvg(840:1090,3:3:end)+flipud(averagedDataBackAvg(1091:1341,3:3:end));
    currentFigure=figure;
    test=surf(blu(1:3:end,2:19));
    set(gca,'XTick',1:18)
    set(gca,'XTickLabel',sampleNames(3:2:end-2))
    set(gca,'XTickLabelRotation',35)
    title('Cy35')
    set(gca,'YTick',1:16.45:83.34)
    set(gca,'YTickLabel',[25:5:50])
    ylabel('temperature [C]')    
    zlabel('fluorescence [a.u.]')
    set(findall(currentFigure,'-property','FontSize'),'FontSize',18)    %change all font sizes
    set(currentFigure, 'Units', 'centimeters')                                    %set paper size to figure size
    set(currentFigure, 'PaperUnits', 'centimeters')
    figureSize=get(currentFigure, 'Position');
    set(currentFigure, 'PaperSize', 2.*figureSize(3:4))
    set(test, 'FaceColor', 'interp')
    
    currentFigure=figure;
    test=surf(flipud(averagedDataBackAvg(210:10:end,6:3:end-1)));
    set(gca,'XTick',1:18)
    set(gca,'XTickLabel',sampleNames(3:2:end-2))
    set(gca,'XTickLabelRotation',35)
    title('Cy35')
    set(gca,'YTick',1:6:108)
    set(gca,'YTickLabel',[180:-10:0])
    ylabel('time [m]')    
    zlabel('fluorescence [a.u.]')
    set(findall(currentFigure,'-property','FontSize'),'FontSize',18)    %change all font sizes
    set(currentFigure, 'Units', 'centimeters')                                    %set paper size to figure size
    set(currentFigure, 'PaperUnits', 'centimeters')
    figureSize=get(currentFigure, 'Position');
    set(currentFigure, 'PaperSize', 2.*figureSize(3:4))
    set(test, 'FaceColor', 'interp')
    
    
    
    blu=averagedDataBackAvg(338:588,3:3:end)+flipud(averagedDataBackAvg(589:839,3:3:end))+averagedDataBackAvg(840:1090,3:3:end)+flipud(averagedDataBackAvg(1091:1341,3:3:end));
    currentFigure=figure;
    plot(blu(1:end,2:19));
    legend(sampleNames{3:2:end-2})
    title('Cy35')
    xlabel('temperature [C]')    
    set(gca,'XTick',1:50:251)
    set(gca,'XTickLabel',[25:5:50])
    ylabel('fluorescence [a.u.]')
    set(findall(currentFigure,'-property','FontSize'),'FontSize',18)    %change all font sizes
    set(currentFigure, 'Units', 'centimeters')                                    %set paper size to figure size
    set(currentFigure, 'PaperUnits', 'centimeters')
    figureSize=get(currentFigure, 'Position');
    set(currentFigure, 'PaperSize',figureSize(3:4))
    
    
    currentFigure=figure;
    [axes,line1,line2]=plotyy([1:17], [bla{:,3}], [1:17], averagedDataBackAvg(end,6:3:end-4));

    legend('Curved ratio','FRET')
    title('polymer orientation')
    ylabel(axes(1),'correct ratio') % left y-axis
    ylabel(axes(2),'Fluorescence [a.u.]') % right y-axis                          %label y axis
    
    set(gca,'XTick',1:17);
    set(gca,'XTickLabel',[bla(:,1)]);
    set(gca,'XTickLabelRotation',35)

    set(findall(currentFigure,'-property','FontSize'),'FontSize',18)    %change all font sizes
    set(currentFigure, 'Units', 'centimeters')                                    %set paper size to figure size
    set(currentFigure, 'PaperUnits', 'centimeters')
    figureSize=get(currentFigure, 'Position');
    set(currentFigure, 'PaperSize', figureSize(3:4))
    