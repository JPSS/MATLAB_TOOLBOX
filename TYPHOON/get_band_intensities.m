function [ bandData ] = get_band_intensities(imageData, varargin)
%% GET_BAND_INTENSITIES compute mean intensities of bands chosen by hand
%   Inputs: imageData = a struct that contains a cell of images, calles
%   images
%           resizable (optional) option whether band areas have same size 
%   Outputs:
%           bandData structure with
%               .band_intensities = mean intensities of selected bands
%               .bandPositions = psoitions for areas
%
% example: bandData = get_band_intensities(myImages, 'resizable', false)

    %% parse input
    p = inputParser;
    default_resizable = false; % default are same sized areas

    addRequired(p,'imageData');
    addParameter(p,'resizable',default_resizable, @islogical); 

    parse(p, imageData, varargin{:});    
    resizable = p.Results.resizable;
    
    %% input number of bands
    cf = plot_image_ui(imageData.images{1}); % show first image in series (change this maybe later)
    options.WindowStyle='normal';
    tmp = inputdlg({'How many bands do you want to integrate:'}, 'How many bands', 1, {'1'}, options);
    n_bands = str2double(tmp(1));
    close(cf)

    %% integrate areas
    [I_mean, bandPositions] = integrate_areas(imageData.images, n_bands, 'resizable', resizable); %cell of images, number of bands, 

    %% make output data
    bandData = struct('intensities',{I_mean},'positions',{bandPositions} );
    
end

