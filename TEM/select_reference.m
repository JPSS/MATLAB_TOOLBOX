function [ templates ] = select_reference( images, box_size, n_ref, mirror, path_out )
% Opens a GUI to select a particle from images. 
% Returns an array of reference images (templates)

    n_img = size(images,3);
    img_size = size(images,1);
    box_size_template = ceil(2*box_size/2/cos(pi/4));%200;
    box_size_template = int16(box_size_template + mod(box_size_template, 2) +1 ) ; % make it even
    templates = zeros(box_size_template, box_size_template, n_ref);
    w = (box_size_template-1)/2;
    for i=1:n_ref/(mirror+1) 
        go_on = 1;
        j = 1;
        close all
        figure('units','normalized','outerposition',[0 0 1 1]);

        while go_on 
            imagesc(images(:,:,j)), axis image, colormap gray
            button = questdlg(['Select an image for ref. ' num2str(i)],'Image','Use this','Previous','Next', 'Use this');
            if strcmp(button, 'Next')
                j = min(n_img,j+1);
            end
            if strcmp(button, 'Previous')
                j = max(j-1, 1);
            end
            if strcmp(button, 'Use this')
                go_on = 0;
            end
        end
        % select particle
        h = imrect(gca, [img_size/2 img_size/2 double(box_size_template) double(box_size_template)]);
        setResizable(h,0) 
        pos = int16(wait(h));


        %refine reference
        r = double(box_size/2);
        template = images(pos(2):pos(2)+pos(4), pos(1):pos(1)+pos(3),j);
        close all
        imagesc( [pos(1) pos(1)+pos(3)], [pos(2) pos(2)+pos(4)],template), colorbar, colormap gray, axis image
        cur_fig = gca;
        h = impoint(gca,[pos(1)+box_size_template/2 pos(2)+box_size_template/2]);
        setColor(h, [1 0 0])
        b = ellipse(r, r, 0, double(pos(1)+box_size_template/2), double(pos(2)+box_size_template/2));
        set(b, 'Color', [1 0 0])
        addNewPositionCallback(h, @(pos) update_ellipse(pos, r, cur_fig) );
        c = round(wait(h));
        close all

        area = [c(2)-w c(2)+w c(1)-w c(1)+w];
        if mirror
            templates(:,:,2*i-1) = images(area(1):area(2), area(3):area(4), j);
            templates(:,:,2*i) = flipdim(images(area(1):area(2), area(3):area(4), j) ,1);
        else
            templates(:,:,i) = images(area(1):area(2), area(3):area(4), j);
        end

    end

    
    %% display and write templates
    path_out_templates = [path_out filesep 'reference_particles'];
    mkdir(path_out_templates)
    dx = (box_size_template-box_size-1)/2;
    figure
    for i=1:n_ref
        subplot(n_ref/(mirror+1),mirror+1,i)
        imagesc(templates(dx:dx+box_size, dx:dx+box_size,i)),  colormap gray, axis image
        tmp_out = templates(dx:dx+box_size, dx:dx+box_size,i)-min(min(templates(dx:dx+box_size, dx:dx+box_size,i)));
        imwrite(  uint16(tmp_out*(2^16-1)/max(tmp_out(:))) , [path_out_templates filesep 'ref_' num2str(i) '.tif' ]);
    end


end

