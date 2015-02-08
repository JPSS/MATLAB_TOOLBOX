function [] = update_ellipse( pos, radius, fig_handle)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    tmp = get(fig_handle, 'children');    %get handle to ellipse


    delete(tmp(1)); % ellipse should be first entry
    b = ellipse(radius, radius, 0, pos(1), pos(2));
    set(b, 'Color', [1 0 0])
end
