function [ image_bg, bg ] = correct_background( image, varargin )
% subtract background from image
% if N_ref >= 3 is passed, the function fits a 2D background plane through at least 3 reference points
% else a constant is subtracted
% input: 
%       image = matrix of image
%       'areas' number of reference areas to calculate background
% output:
%       image_bg = background corrected image
%       bg = background value (if constant mode was selected)

    % parse input 
    p = inputParser;
    default_n_ref = 1;

    addRequired(p,'image', @isnumeric);
    addParameter(p,'areas',default_n_ref, @isnumeric); 

    parse(p, image, varargin{:});
    N_ref = p.Results.areas;

    % calculate background reference values

    if N_ref ~= 1  % use a linear plane to fit to background
       if N_ref < 3
           disp('Warning: not enough reference-areas for a linear plane. N_ref changed to 4.')
           N_ref = 4;
       end
    end

    [I, areas] = integrate_areas({image}, N_ref, 'resizable', false, 'message', ['Select ' num2str(N_ref) ' background areas']); %cell of images, number of bands, 1=all bands habe the same size
    close all

    % fit a first order polynomial to the bg-points

    bg_points = zeros(N_ref,3);
    for i=1:N_ref
        bg_points(i,1) = areas(i,2)+areas(i,4)/2; % x-coordinate
        bg_points(i,2) = areas(i,1)+areas(i,3)/2; % y-coordinate
        bg_points(i,3) = mean( mean(  image(areas(i,2):areas(i,2)+areas(i,4)  ,   areas(i,1):areas(i,1)+areas(i,3)   ) ));
    end

    if N_ref > 1
        bg = fit( bg_points(:,1:2), bg_points(:,3), 'poly11');

        % subtract
        [i, j] = meshgrid(1:1:size(image,1), 1:1:size(image,2));
        ti = i'; tj = j';
        z = bg([ti(:) tj(:)]);
        Z = reshape(z, size(image));
        image_bg =  image - Z ;
        %plot_image_ui(image_bg);
    else
        image_bg =  image - bg_points(1,3) ;
        bg = bg_points(1,3);
    end

end

 