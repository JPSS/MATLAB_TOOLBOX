function [ I, areas ] = integrate_areas(img, n_areas, same_size, plot_factor)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    close all
    areas = zeros(n_areas, 4);
    I = zeros(n_areas, max(size(img)));
    N_img = max(size(img));
    img_show = zeros(size(img{1},1), size(img{1},2));
    for i=1:N_img
        img_show = img_show + plot_factor(i) .* img{i};
    end
    
    plot_image_ui(img_show); %img{1});
    
    for i=1:n_areas
        for j=1:i-1
            rectangle('Position', areas(j,:), 'EdgeColor', 'r'); %plot all integrated areas
            text(areas(j, 1)+areas(j,3)/2, areas(j, 2)+areas(j,4)/2, num2str(j), 'Color', 'r', 'VerticalAlignment', 'Middle', 'HorizontalAlignment', 'Center')
        end
        
        if i==1
            h = imrect;
        else
            if same_size
                h = imrect(gca, double(pos));
                setResizable(h, 0)
            else
                h = imrect;
            end
        end
        wait(h);
        pos = int32(getPosition(h)); % [xmin ymin width height]
        delete(h)
        areas(i,:) = pos;
        for j= 1:max(size(img))
            I(i,j) = sum(sum((img{j}(pos(2):pos(2)+pos(4)  , pos(1):pos(1)+pos(3))))); %integrate
        end
    end
    
    close all
end
