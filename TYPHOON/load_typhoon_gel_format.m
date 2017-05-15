function imageData = load_typhoon_gel_format(varargin)
%% Loads image, fits lanes according to step function convolved with gaussian
%   INPUTS: 
%   'data_dir' (optional parameter) = initial directory, where data is stored
%   'n_images' (optional parameter) = number of images to load
%   OUTPUT:
%   imageData struct with .images .images_gel .images_tiff .pathnames .filenames .nrImages
%   .nrImages is number of images
%   .images is cell array {nr_image} of image data in linear LAU format
%   .images_gel is cell array {nr_image} of image data in square-root .gel format
%   .images_tiff is cell array {nr_image} of image data in linear-with-constant-offset .tiff format
%   .pathnames is cell array {nr_image} of pathnames to each image
%   .filenames is cell array {nr_image} of filenames of each image
%
% Example: myImageData = load_gel_image('data_dir', '~/Documents/Images');

%% parse input variables

parser = inputParser;
% default data directory is userpath
default_data_dir = userpath;
default_data_dir = default_data_dir(1:end - 1);

addParameter(parser, 'data_dir', default_data_dir, @isstr);
% n_images is number of images, default is -1
addParameter(parser,'n_images', -1 ,@isnumeric)

parse(parser,  varargin{:});
% default data location
data_dir = parser.Results.data_dir;
% set number of images
nrImages = parser.Results.n_images;
    
%% select .gel file to calculate maximum intensity from
%remember initial/current path
init_path = cd; 

% ask how many images user wants to load
if nrImages <= 0 
    temp = inputdlg({'How many images (channels) do you want to load:'}, 'How many images (channels) do you want to load?', 1, {'1'});
    nrImages = str2double(temp(1));
end

filenames = cell(nrImages, 1);
pathnames = cell(nrImages, 1);

lastDirectory = data_dir;
for i = 1:nrImages
    cd(lastDirectory)
    [filenames{i}, pathnames{i}] = uigetfile('*.gel','Select image:');
    lastDirectory = pathnames{i};
end

% cd to initial directory
cd(init_path)

%% load image data in .gel format
images_gel = cell(nrImages, 1);

for i = 1:nrImages
    images_gel{i} = double(imread([pathnames{i} filesep filenames{i}]));
end

%% calculate LAU format values from .gel format
images_LAU = cell(nrImages, 1);

%standard values for the ZNN typhoon scanner:
%LAU value for QL=0
pix = 25;
L = 5;
G = 65536;
LAU_0 = (pix / 100)^2 * 100 * 10^(L * (0/G - 0.5));
LAU_65535 = (pix / 100)^2 * 100 * 10^(L * (65535/G - 0.5));

for i = 1:nrImages
    images_LAU{i} = (images_gel{i} .* ((sqrt(LAU_65535) - sqrt(LAU_0)) / 65535) + sqrt(LAU_0)) .^ 2;
end


%% calculate tiff format values from .gel format
images_tiff = cell(nrImages, 1);

for i = 1:nrImages
    LAU_max = max(max(images_LAU{i}));
    
    %sorted array of unique values in LAU data
    values_in_LAU_data = sort(unique(images_LAU{i}(:)));
    
    if max(max(images_gel{i})) == 65535
        'tiff scaled to 65535'
        images_tiff{i} = 62258/(values_in_LAU_data(end-1) - LAU_0) .* (images_LAU{i} - LAU_0);
        %values above max_non_saturated_value are set to 65535
        max_non_saturated_value = 62258/(values_in_LAU_data(end-1) - LAU_0) .* (values_in_LAU_data(end-1) - LAU_0);
        images_tiff{i}(images_tiff{i} > max_non_saturated_value) = 65535;
    else
        'tiff scaled to 62258'
        images_tiff{i} = 62258/(LAU_max - LAU_0) .* (images_LAU{i} - LAU_0);
    end
end

%% create imageData structure, return imageData structure

imageData = struct('images_gel',{images_gel}, 'images', {images_LAU}, 'images_tiff', {images_tiff}, 'pathnames', {pathnames}, 'filenames', {filenames}, 'nrImages', nrImages);
end
