function imageData = load_gel_image()
%% Loads image, fits lanes according to step function convolved with gaussian
%   INPUTS: none
%   OUTPUT:
%   imageData struct with .images .pathnames .filenames .nrImages
%   .nrImages is number of images
%   .images is cell array {nr_image} of image data
%   .pathnames is cell array {nr_image} of pathnames to each image
%   .filenames is cell array {nr_image} of filenames of each image


%% select image data

temp = inputdlg({'How many images (channels) do you want to load:'}, 'How many images (channels) do you want to load?', 1, {'1'});
nrImages = str2double(temp(1));

filenames = cell(nrImages, 1);
pathnames = cell(nrImages, 1);

lastDirectory = userpath;
lastDirectory=lastDirectory(1:end-1);
for i=1:nrImages
    cd(lastDirectory)
    [filenames{i}, pathnames{i}]=uigetfile('*.tif','Select image:');
    lastDirectory = pathnames{i};
end

%% load image data, rotate images if necessary, apply background correction to images

images = cell(nrImages, 1);

for i=1:nrImages
    images{i} = double(imread([pathnames{i} filesep filenames{i}]));             %load image data  
end

%% create imageData structure, return imageData structure

imageData=struct('images',{images},'pathnames',{pathnames},'filenames',{filenames},'nrImages',nrImages);