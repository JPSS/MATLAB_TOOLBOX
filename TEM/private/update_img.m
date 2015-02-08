function [] = update_img(img, fig_handle )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    imagesc( img , 'Parent', fig_handle);
    axis(fig_handle, 'image');

end

