%%
close all, clear all, clc

[images, pname] = load_tem_images(2048, -1); % 2048x2048 image, no filter

path_out = [pname filesep datestr(now, 'yyyy-mm-dd_HH-MM') '_images-imagic'];
mkdir(path_out)
tmp = strsplit(pname, filesep);
prefix_out = tmp{end};

%% write a img file
for i=1:size(images,3)
    WriteImagic(uint16(images(:,:,i)), [path_out filesep prefix_out '_' sprintf('%04i', i) ])
end
