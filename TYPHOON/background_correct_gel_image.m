function imageDataBgCorrected = background_correct_gel_image(imageData, varargin)
%% Loads image, fits lanes according to step function convolved with gaussian
%   INPUTS: imageData from load_gel_image.m
%           'numberOfAreas' (optional parameter) = set number of areas for
%           bg correction, default is 1
%           optional: histogram_background: if 'on' activates automatic background determination from gel image histogram
%           optional: histogram_smooth_span: set span of smoothing of histogram for automatic background correction
%   OUTPUT:
%   imageData struct from load_gel_image.m with .images replaced by background corrected images
% Example = background_correct_gel_image(img, 'numberOfAreas', 4)

%% parse input
p = inputParser;
% default for number of references for background correction
default_n_ref_bg = 1;

addRequired(p, 'imageData');
addParameter(p, 'numberOfAreas', default_n_ref_bg, @isnumeric); 

% optional parameter: histogram_background (if on, selects background from maximum of smoothed image histogram
default_histogram_background = 'off';
expected_histogram_background = {'on', 'off'};
% check histogram_background is 'on' or 'off'
addParameter(p, 'histogram_background', default_histogram_background, @(x) any(validatestring(x,expected_histogram_background)));

% optional parameter: histogram_smooth_span for image histogram smoothing for background determination
default_histogram_smooth_span = 10;
addParameter(p, 'histogram_smooth_span', default_histogram_smooth_span, @isnumeric); 
    
parse(p, imageData, varargin{:});
% number of references for background correction
n_ref_bg = p.Results.numberOfAreas;

histogram_background_bool = strcmp(p.Results.histogram_background, 'on');
histogram_smooth_span = p.Results.histogram_smooth_span;

%% apply background correction to images

images_bg = cell(imageData.nrImages, 1);
background = cell(imageData.nrImages, 1); % stores bckground values
for i = 1:imageData.nrImages
    
    %subtract maximum location value of smoothed image histogram from image
    if histogram_background_bool
        
        %highest pixel value in current image
        max_pixel_value = max(max(imageData.images{i}));
        
        %calculate histogram of image
        [histogram, edges] = histcounts(imageData.images{i}, 2^16);
        %smooth histogram of image
        histogram_smooth = smoothdata(histogram, 'movmean', histogram_smooth_span);
        [~, loc] = max(histogram_smooth);
        %determine peak location+half bin size
        loc = 0.5 * (edges(loc) + edges(loc + 1));
        
        %display smooth histogram and unsmoothed histogram and peak location
        figure
        clf
        plot( edges(1:end - 1) + 0.5*(edges(2) - edges(1)), histogram_smooth)
        hold on
        plot( edges(1:end - 1) + 0.5*(edges(2) - edges(1)), histogram)
        plot([loc loc],[0 max(histogram_smooth)]);
        axis([min(min(imageData.images{i})) min(4*loc, max(max(imageData.images{i}))) 0 max(histogram)])
        pause
        
        % close figure
        close
        
        %save background correction value
        background{i} = loc;
        %subtract background correction value
        images_bg{i} = imageData.images{i} - loc;
    else
        % subtract a constant from each image  
        [images_bg{i}, background{i}] = correct_background(imageData.images{i}, 'areas', n_ref_bg);
    end
end
%% create imageDataBgCorrected structure, return imageDataBgCorrected structure

imageData.images = images_bg;
imageData.background = background;
imageDataBgCorrected = imageData;