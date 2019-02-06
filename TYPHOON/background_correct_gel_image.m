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
        
        % check if .gel format was used to generate LAU format
        if isfield(imageData,'images_tiff_format')
            % image data should be in LAU format
            
            %smallest and largest pixel values that are possible in LAU format
            min_pixel_value = 0.01976423;
            max_pixel_value = 1976.076364;
            % factors for transforming from linear to square-root format
            multiplier = 65535 / (sqrt(max_pixel_value) - sqrt(min_pixel_value));
            offset = sqrt(min_pixel_value) * multiplier; 
        else
            %smallest and largest pixel value in current image
            min_pixel_value = min(min(imageData.images{i}));
            max_pixel_value = max(max(imageData.images{i}));
            % factors for transforming from linear to square-root format
            multiplier = 65535 / (sqrt(max_pixel_value) - sqrt(min_pixel_value));
            offset = sqrt(min_pixel_value) * multiplier; 
        end
        
        %number of bins in histogram
        nr_steps = 2^16;

        % calculate quadratically increasing bin sizes for image intensity histogram that is sensitive at low intensities
        % skip very first datapoint in case there is a 0 intensity background in gel-free areas
        edges = (((1:nr_steps-1) + offset) ./ multiplier).^2;
        
        %calculate histogram of image
        [histogram, edges] = histcounts(imageData.images{i}, edges);
        
        % normalize histogram with bin sizes to calculate intensity probability density
        histogram = histogram ./ (edges(2:end) - edges(1:end - 1));
        
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