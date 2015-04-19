function [ classes, N ] = manual_classify( )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    % load img file
    [fname, pname] = uigetfile('*.img', 'Select .img particle stack');

    % load images
    img = ReadImagic([pname fname]);


    N_class = 2;
    class_names = {'Open', 'Closed', 'Unknown'};
    classes = zeros(size(img,3), 1);
    cf = figure;
    
    % Create open-button
    Back_button = uicontrol('Style', 'pushbutton', 'String', class_names{1},...
        'Position', [10 20 50 20],... %location, values based on plot_image_gui
        'Callback', @classify);    
    
    % Create open-button
    Back_button = uicontrol('Style', 'pushbutton', 'String', class_names{2},...
        'Position', [100 20 50 20],... %location, values based on plot_image_gui
        'Callback', @classify); 
    
    % Create open-button
    Back_button = uicontrol('Style', 'pushbutton', 'String', class_names{3},...
        'Position', [190 20 50 20],... %location, values based on plot_image_gui
        'Callback', @classify); 
    
        % Create open-button
    Back_button = uicontrol('Style', 'pushbutton', 'String', 'stop',...
        'Position', [300 20 50 20],... %location, values based on plot_image_gui
        'Callback', @finish); 
    i = 1;
    while i <= size(img,3)
       imagesc(img(:,:,i)), axis image, colormap gray
       title(['Particle ' num2str(i)])
       uiwait(cf)
       i = i+1;
    end

        % callback function for back-button
    function classify(source,callbackdata)
        if strcmp(source.String, class_names{1})
            classes(i) = 1;
        end
        if strcmp(source.String, class_names{2})
            classes(i) = 2;
        end
        if strcmp(source.String, class_names{3})
            classes(i) = 3;
        end
        uiresume(cf);
    end

   function finish(source,callbackdata)
        dlmwrite([pname fname(1:end-4) '_classified_1-' num2str(i-1) '.txt'], classes,'delimiter', '\t')
        i = size(img,3)+1;
        uiresume(cf);
   end
    
    N = [length(classes(classes==0)), length(classes(classes==1)), length(classes(classes==2)), length(classes(classes==3))];
    disp(['Open: ' num2str(length(classes(classes==1)))])
    disp(['Closed: ' num2str(length(classes(classes==2)))])
    disp(['Unknown: ' num2str(length(classes(classes==3)))])
    disp(['Not classified: ' num2str(length(classes(classes==0)))])
    dlmwrite([pname fname(1:end-4) datestr(now, 'YYYY-mm-dd_HH-MM') '_classified.txt'], classes,'delimiter', '\t')
    save([pname fname(1:end-4) datestr(now, 'YYYY-mm-dd_HH-MM') '_classified.mat'], 'classes', 'class_names', 'N')

    cf = figure();
    bar(N(2:end))
    ylabel('Frequency')
    set(gca, 'XTickLabel', class_names)
    title([num2str(sum(N(2:end))) ' of ' num2str(sum(N)) ' particles' ])
    print(cf, [pname fname(1:end-4) datestr(now, 'YYYY-mm-dd_HH-MM') '_classified.tif'], '-dtiff', '-r300')

end

