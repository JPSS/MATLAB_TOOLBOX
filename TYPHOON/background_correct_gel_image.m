function imageDataBgCorrected = background_correct_gel_image(imageData)
%% Loads image, fits lanes according to step function convolved with gaussian
%   INPUTS: imageData from load_gel_image.m
%   OUTPUT:
%   imageData struct from load_gel_image.m with .images replaced by background corrected images

%% apply background correction to images

images_bg = cell(imageData.nrImages, 1);

for i=1:imageData.nrImages
    images_bg{i} = correct_background(imageData.images{i}, 'areas', 1); % subtract a constant from each image  
end
%% create imageDataBgCorrected structure, return imageDataBgCorrected structure

imageData.images=images_bg;
imageDataBgCorrected=imageData;