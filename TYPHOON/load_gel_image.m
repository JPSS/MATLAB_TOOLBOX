function imageData = load_gel_image(varargin)
%% Loads gel image data
%   INPUTS: 
%   'data_dir' (optional parameter) = initial directory, where data is
%   stored
%   'n_images' (optional parameter) = number of images to load
%   OUTPUT:
%   imageData struct with .images .pathnames .filenames .nrImages
%   .nrImages is number of images
%   .images is cell array {nr_image} of image data
%   .pathnames is cell array {nr_image} of pathnames to each image
%   .filenames is cell array {nr_image} of filenames of each image
%
% Example: myImageData = load_gel_image('data_dir', '~/Documents/Images');

%% parse input
p = inputParser;
default_data_dir = userpath; % default data directory is userpath
default_data_dir=default_data_dir(1:end-1);

addParameter(p,'data_dir',default_data_dir, @isstr); 
addParameter(p,'n_images', -1 ,@isnumeric) % n_images, default is -1

parse(p,  varargin{:});    
data_dir = p.Results.data_dir;  % default data location
nrImages = p.Results.n_images; % set number of images

%% select image data
init_path = cd; %remember initial/current path

if nrImages <= 0 % ask how many images user wants to load
    temp = inputdlg({'How many images (channels) do you want to load:'}, 'How many images (channels) do you want to load?', 1, {'1'});
    nrImages = str2double(temp(1));
end

filenames = cell(nrImages, 1);
pathnames = cell(nrImages, 1);

lastDirectory = data_dir;
for i=1:nrImages
    cd(lastDirectory)
    [filenames{i}, pathnames{i}]=uigetfile('*.tif','Select image:');
    lastDirectory = pathnames{i};
end
cd(init_path) % cd to initial directory

%% load image data
images = cell(nrImages, 1);

for i=1:nrImages
    images{i} = double(imread([pathnames{i} filesep filenames{i}]));             %load image data  
end

%% create imageData structure, return imageData structure

imageData=struct('images',{images},'pathnames',{pathnames},'filenames',{filenames},'nrImages',nrImages);