function imageDataRotated = rotate_gel_image(imageData)
%% rotates images in gel image structure
%   INPUTS: imageData from load_gel_image.m
%   OUTPUT:
%   imageData struct from load_gel_image.m with .images rotated if selected

%% rotate images

for i=1:imageData.nrImages
   
    cf = plot_image_ui(imageData.images{i}); %plot and rotate gel
    button = questdlg('Rotate?','Rotate','Rotate','No','No');
    if strcmp(button,'Rotate') 
        imageData.images{i} = imrotate(imageData.images{i}, -90);
    end
    close(cf)
  
end
%% create imageDataRotated structure, return imageDataRotated structure

imageDataRotated=imageData;