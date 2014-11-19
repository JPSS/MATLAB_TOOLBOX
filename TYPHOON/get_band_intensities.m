function [ bandData ] = get_band_intensities( varargin )
%% GET_BAND_INTENSITIES compute mean intensities of bands chosen by hand
%   Inputs: data_dir (optional) define initial directory for choosing
%               images
%           areas_bg (optional) number of reference areas for background
%                  correction
%           resizable (optional) option whether band areas have same size 
%   Outputs:
%           bandData structure with
%               .band_intensities = mean intensities of selected bands
%               .bandPositions = psoitions for areas
%               .imageNames = filenames of images
%               .pathnames = pathnames of images
%               .correctedImages= background corrected mages
%               .background = subtracted backgrounds
%
% example: bandData = get_band_intensities('data_dir', '~/Documents', 'areas_bg', 4, 'resizable', false)

    %% parse input
    p = inputParser;
    default_data_dir = cd;
    default_n_ref_bg = 1; % default for number of references for background correction
    default_resizable = false;

    addParameter(p,'data_dir',default_data_dir, @isstr); 
    addParameter(p,'areas_bg',default_n_ref_bg, @isnumeric); 
    addParameter(p,'resizable',default_resizable, @islogical); 

    parse(p, varargin{:});    
    data_dir = p.Results.data_dir;  % default data location
    n_ref_bg = p.Results.areas_bg;  % number of references for background correction
    resizable = p.Results.resizable;
    path0 = cd;
    
    %% load image
    tmp = inputdlg({'How many images (channels) do you want to load:'}, 'Number of channels' , 1, {'1'} );
    n_img = str2double(tmp{1});

    filenames = cell(n_img, 1);
    pathnames = cell(n_img, 1);

    last_dir = data_dir;
    for i=1:n_img
        cd(last_dir)
        [filenames{i}, pathnames{i}]=uigetfile('*.tif','Select image:');
        last_dir = pathnames{i};
    end
    cd(path0)

    %% load and bg correct images
    images = cell(n_img, 1);
    img_bg = cell(n_img, 1);
    background = cell(n_img, 1);
    for i=1:n_img
        images{i} = double(imread([pathnames{i} filesep filenames{i}]));  %load
        disp(['Loaded image: ' filenames{i}])
        disp(['Image directory: ' pathnames{i}])
        plot_image_ui(images{i});
        button = questdlg('Rotate?','Rotate','Rotate','No','No');
        if strcmp(button,'Rotate') %load old data
            images{i} = imrotate(images{i}, -90);
        end
        close all
        [img_bg{i}, background{i}] = correct_background(images{i}, 'areas', n_ref_bg);    %bg correct with constant value
        close all    
    end
    
    %% select bands by hand
    plot_image_ui(img_bg{1});
    options.WindowStyle='normal';
    tmp = inputdlg({'How many bands do you want to integrate:'}, 'How many bands', 1, {'1'}, options);
    n_bands = str2double(tmp(1));
    close all

    %% integrate areas, all areas have the same size
    [I_mean, bandPositions] = integrate_areas(img_bg, n_bands, 'resizable', resizable); %cell of images, number of bands, 

    %% make output data
    bandData = struct('band_intensities',{I_mean},'bandPositions',{bandPositions}, ...
    'imageNames',{filenames},'pathnames',{pathnames}, ...
    'correctedImages', {img_bg}, 'background', {background} )
    
end

