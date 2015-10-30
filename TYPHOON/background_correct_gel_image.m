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
default_n_ref_bg = 1; % default for number of references for background correction

addRequired(p,'imageData');
addParameter(p,'numberOfAreas',default_n_ref_bg, @isnumeric); 

    % optional parameter: histogram_background (if on, selects background from maximum of smoothed image histogram
    default_histogram_background = 'off';
    expected_histogram_background = {'on', 'off'};
        % check histogram_background is 'on' or 'off'
    addParameter(p,'histogram_background', default_histogram_background,  @(x) any(validatestring(x,expected_histogram_background)));

    % optional parameter: histogram_smooth_span for image histogram smoothing for background determination
    default_histogram_smooth_span = 10;
    addParameter(p,'histogram_smooth_span', default_histogram_smooth_span,  @isnumeric); % check 
    
parse(p, imageData, varargin{:});
n_ref_bg = p.Results.numberOfAreas;  % number of references for background correction

    histogram_background_bool=strcmp(p.Results.histogram_background,'on');
    histogram_smooth_span = p.Results.histogram_smooth_span;

%% apply background correction to images

images_bg = cell(imageData.nrImages, 1);
background = cell(imageData.nrImages, 1); % stores bckground values
for i=1:imageData.nrImages
    
    if histogram_background_bool    %subtract maximum location value of smoothed image histogram from image
        histogram=histcounts(imageData.images{i},max(max(imageData.images{i}))-min(min(imageData.images{i})));  %calculate histogram of image
        histogram_smooth=smooth(histogram,histogram_smooth_span);                                               %smooth histogram of image
        [~, loc]=max(histogram_smooth);
        loc=loc+min(min(imageData.images{i}))-1+0.5;                                                            %determine peak location+half bin size
        
        clf
        plot([min(min(imageData.images{i})):max(max(imageData.images{i}))-1],histogram_smooth)                  %display smooth histogram and location
        hold on
        plot([loc loc],[0 max(histogram_smooth)]);
        axis([0 sum(histogram.*[min(min(imageData.images{i})):max(max(imageData.images{i}))-1])/sum(histogram) 0 max(histogram_smooth)])
        pause
        
        background{i}=loc;                                      %save background correction value
        images_bg{i}=imageData.images{i}-loc;                   %subtract background correction value
    else
        [images_bg{i}, background{i}] = correct_background(imageData.images{i}, 'areas', n_ref_bg); % subtract a constant from each image  
    end
end
%% create imageDataBgCorrected structure, return imageDataBgCorrected structure

imageData.images=images_bg;
imageData.background = background;
imageDataBgCorrected=imageData;