function [ image_bg, bg ] = correct_background( image, image_title, N_ref )
%% subtract background from image
%if N_ref is passed, fits a 2D background plane through at least 3 reference points
%else subtracts a constant reference background value

%% calculate background reference values

if ~exist('N_ref', 'var') % use average frame
   N_ref = 1;
else
    if N_ref < 3
        disp('Number of reference points to small. Changed to 3.')
        N_ref = 3;
    end
end

[I, areas] = integrate_areas({image}, N_ref, 1, [1 1]); %cell of images, number of bands, 1=all bands habe the same size
close all

%% fit a first order polynomial to the bg-points

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

    plot_image_ui(image_bg);
else
    image_bg =  image - bg_points(1,3) ;
end

end

 