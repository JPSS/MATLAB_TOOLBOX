function [images, pname] = load_tem_images(img_size, r_filter )
% Loads a stack of TEM images 
%   Detailed explanation goes here

    original_size = 2048;
    data_dir = cd;
    
    %% ask for directory
    pname=uigetdir(data_dir,'Choose a folder with tem images.'); % get pathname
    tmp = dir([pname filesep '*_16.TIF']);
    fnames = {tmp.name}; % list of filenames
    n_img = size(fnames,2);


    %% load, filter and crop images
    disp(['Loading and filtering ' num2str(n_img) ' images...'])
    images = zeros(img_size, img_size, n_img);
    if r_filter > 0
        f_filter = fspecial('gaussian', r_filter*4*2 , r_filter); % gaussian filter, diameter = 2*(width = 4*sigma)
    end
    h = waitbar(0,'Loading and filtering images... ? time remaining');
    tic
    for i=1:n_img
        img = imread([pname filesep fnames{i}], 'PixelRegion', {[1 original_size], [1 original_size]});
        if r_filter > 0
            tmp = double(img)-double(imfilter(img, f_filter, 'same'));
        else
            tmp = double(img);
        end
        images(:,:,i) = imresize(tmp,[img_size img_size], 'nearest'); %bin image 4x4 for faster image processing
        %images(:,:,i) = imresize(img(1:2048,1:2048),[512 512], 'nearest'); %bin image 4x4 for faster image processing
        if i==1
            dt = toc;
            tic;
        else
            dt_this = toc;
            dt = (dt+dt_this)/2;
            tic;
        end

        n_remain = n_img-i;
        waitbar( i/n_img , h, ['Loading and filtering images... ' num2str(round(n_remain*dt/60*10)/10) ' min remaining'])

    end
    pause(0.1)
    close(h); 

end

