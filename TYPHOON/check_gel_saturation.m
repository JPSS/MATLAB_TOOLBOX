function [ gelData, cur_fig ] = check_gel_saturation( gelData )
%checks if gelData.images contains images that are saturated
%   Input: gelData with field images
%   Outpu: gelData with additional field saturation
%Example = [gelData_raw, cf] = check_gel_saturation(gelData_raw);

    saturated = zeros(size(gelData.images));

    %generate a uint16 colormap
    %b = [0:1:(2^16-1)]/(2^16-1);
    %cm_uint16 = [b' b' b'];
    %cm_uint16(end,:) = [1 0 0 ];

    for i=1:length(gelData.images)
        if max(gelData.images{i}(:)) == 2^16-1
            saturated(i) = 1;
            disp(['WARNING: Image ' num2str(i) ' is saturated.'])
            %imagesc(gelData.images{i}), colormap(cm_uint16), colorbar, axis image, hold on
            cur_fig = plot_image_ui(gelData.images{i}); hold on
            [x, y] = find(gelData.images{i} == 2^16-1);
            plot(y, x, 'r.')             
            tmp = questdlg(['WARNING: Image ' num2str(i) ' is saturated.'],'Saturation Warning','Close image','Keep image', 'Close image');
            if strcmp(tmp, 'Close image')
                close(cur_fig);
            end
        else
            disp(['Image ' num2str(i) ' is good.'])
        end    

    end

    gelData.saturation = saturation;

end

