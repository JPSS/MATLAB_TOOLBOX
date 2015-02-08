%% startup
clear all; close all; clc;
path0=cd;
data_dir = cd;

%% parameters
input = {'Box size [pixel]:', 'Number of class references:', 'Include mirror (0=no, 1=yes):',... % sample options
    'Binning:', 'Radius of high-pass filter [pixel]:', 'Angel resolution [deg]:'};
input_default = {'200', '1', '1', '4', '15', '5'};
tmp = inputdlg(input, 'Parameters', 1, input_default);
box_size_real = round(str2double(tmp(1))); % size of particle on real image, HAS TO BE EVEN
mirror = str2double(tmp(3)); % include mirror transformation, 0=no, 1= yes
n_ref = str2double(tmp(2))*(mirror+1);
n_bin = str2double(tmp(4)); % number of pixel to bin in one dim
r_filter = str2double(tmp(5));  %100; % pixel (original image), radius for gaussian high pass, -1 == no filtering
dalpha = str2double(tmp(6)); % deg, angle resolution

if mod(box_size_real,n_bin*2) ~= 0
    box_size_real = box_size_real+2*n_bin-mod(box_size_real,n_bin*2);
    disp(['Box size not a multiple of bin_size. Changed to ' num2str(box_size_real)])
end

box_size = box_size_real/n_bin; % size of particle, HAS TO BE EVEN
img_size = 2048/n_bin; %size of the binned image

refine = 1; % dismiss particles with low correlation

%% load images
[images, pname] = load_tem_images(img_size, r_filter);

%% create output directory
path_out = [pname filesep datestr(now, 'yyyy-mm-dd_HH-MM') '_particles']; % output folder
mkdir(path_out)
prefix  = strsplit(pname, filesep); % determine prefix
prefix = prefix{end};

%% create class references
[templates ] = select_reference( images, box_size, n_ref, mirror, path_out);

%% Find particles using X-Correlation and find maximum correlations
[peaks_ref, peaks, img3] = find_particles(templates, images, dalpha , box_size);  
   

%% display images and found particles
%{
cc = varycolor(n_ref);
close all
myleg = cell(n_ref,1);
for t=1:n_ref
    myleg{t} = ['Reference ' num2str(t)];
end
for i=1:n_img
    subplot(1, 2, 1)
    imagesc(img3(:,:,i)), colorbar,  colormap gray, axis image, hold on % img2
    for r=1:n_ref
        h(r) = plot(peaks_ref{r,i}(:,1), peaks_ref{r,i}(:,2),  '.', 'color', cc(r,:));
    end
    title(['Image ' num2str(i) '/' num2str(n_img) ])
    legend(h, myleg)
    hold off
    
    subplot(1, 2, 2)
    imagesc(images(:,:,i)), colorbar, colormap gray, axis image, hold on %
    for r=1:n_ref
        h(r)=plot(peaks_ref{r,i}(:,1), peaks_ref{r,i}(:,2),  '.', 'color', cc(r,:));
    end
    title(['Image ' num2str(i) '/' num2str(n_img) ])
    legend(h, myleg)
    hold off
    pause
end
%}

%% generate stack of particles
close all
particles = cell(n_ref, n_img);
particles_rot = cell(n_ref, n_img);

for i=1:n_img
    img = imread([pname filesep fnames{i}], 'PixelRegion', {[1 2048], [1 2048]});
    N = 2048;
    w = 4*box_size/2;
    for t=1:n_ref
        p= zeros(2*w+1, 2*w+1, size(peaks_ref{t,i},1), 'uint16');
        p_rot= zeros(2*w+1, 2*w+1, size(peaks_ref{t,i},1), 'uint16');

        for j=1:size(peaks_ref{t,i},1)
            x = 4*peaks_ref{t,i}(j,1);
            y = 4*peaks_ref{t,i}(j,2);
            angle = peaks_ref{t,i}(j,4);
            p(max(1,w-y+2):min(2*w+1, 2*w+1-y-w+N),max(1,w-x+2):min(2*w+1, 2*w+1-x-w+N),j) = img(max(1, y-w):min(N,y+w) , max(1, x-w):min(N,x+w) );
            
                %    lib(:,:,j) = tmp(dx:dx+box_size, dx:dx+box_size);
            
            w2=w+4*dx;
            
           % bla = zeros(2*w2+1, 2*w2+1);
          %  bla( max(1,w2-y+2):min(2*w2+1, 2*w2+1-y-w2+N),max(1,w2-x+2):min(2*w2+1, 2*w2+1-x-w2+N)) = img(max(1, y-w2):min(N,y+w2) , max(1, x-w2):min(N,x+w2) );
            tmp = imrotate(img(max(1, y-w2):min(N,y+w2) , max(1, x-w2):min(N,x+w2) ), -angle, 'crop');
          %  tmp = imrotate(bla, -angle, 'crop');

          %  p_rot(:,:,j) = bla(4*dx:4*dx+4*box_size, 4*dx:4*dx+4*box_size);
       
            p_rot(max(1,w-y+2):min(2*w+1, 2*w+1-y-w+N),max(1,w-x+2):min(2*w+1, 2*w+1-x-w+N),j) = tmp(4*dx:4*dx+4*box_size, 4*dx:4*dx+4*box_size);
            %{
            subplot(3,2,1:4)
            imagesc(img), colorbar, colormap gray, axis image, hold on
            plot(x,y, 'r.')
            hold off
            subplot(3,2,5)
            imagesc(p(:,:,j)), colorbar, colormap gray, axis image
            title(['Particle ' num2str(j) ' angle = 0' ])
            subplot(3,2,6)
            imagesc(p_rot(:,:,j)), colorbar, colormap gray, axis image
            title(['Particle ' num2str(j) ' angle = ' num2str(angle)])
            pause
            %}
            
        end
        particles{t,i} = p;
        particles_rot{t,i} = p_rot;

    end
end
clear('p', 'p_rot')

%%
clear data
data(n_ref/(mirror+1)) = struct('stats', [], 'particles', [],  'particles_rot', []);
w = 4*box_size/2;

for t=1:n_ref/(mirror+1)
    n_particle = 0;
    for i=1:n_img
        n_particle = n_particle + size(particles{(mirror+1)*t,i}, 3);
        if mirror
            n_particle = n_particle + size(particles{(mirror+1)*t-1,i}, 3);
        end
    end    
    
    p_out = zeros(2*w+1, 2*w+1, n_particle, 'uint16');
    p_out_rot = zeros(2*w+1, 2*w+1, n_particle, 'uint16');

    stats_out = zeros(n_particle, 5);
    
    m=1;
    if mirror 
        for i=1:n_img
            for j=1:size(particles{(mirror+1)*t-1,i},3)
                p_out(:,:,m) = particles{(mirror+1)*t-1,i}(:,:,j);
                p_out_rot(:,:,m) = particles_rot{(mirror+1)*t-1,i}(:,:,j);

                stats_out(m,1:4)  = peaks_ref{(mirror+1)*t-1,i}(j,1:4);
                stats_out(m,5)  = i;
                m = m+1;
            end
        end
    end
    for i=1:n_img
        for j=1:size(particles{(mirror+1)*t,i},3)
            p_out(:,:,m) = particles{(mirror+1)*t,i}(:,:,j);
            if mirror
                p_out_rot(:,:,m) = flipdim(particles_rot{(mirror+1)*t,i}(:,:,j),1);
            else
                p_out_rot(:,:,m) = particles_rot{(mirror+1)*t,i}(:,:,j);
            end
            stats_out(m,1:4)  = peaks_ref{(mirror+1)*t,i}(j,1:4);
            stats_out(m,5)  = i;
            m = m+1;
        end
    end
    
    data(t).stats = stats_out;
    data(t).particles = p_out;
    data(t).particles_rot = p_out_rot;

end
clear('p_out', 'p_out_rot')

%% refine 
disp('Refining particles...')

limit = zeros(n_ref/(mirror+1), 1);
if refine
    for t=1:n_ref/(mirror+1)
        [cc_sort, sort_index] = sortrows(data(t).stats(:,3), -1);
        i = [1:size(cc_sort,1)]';

        close all
        subplot(1, 2, 1)
        imagesc(data(t).particles_rot(:,:,sort_index(1))), axis image, colormap gray
       % title(['Ref ' num2str(t) ', particle ' num2str(i) ', cc = ' num2str(data(t).stats(sort_index(1),3))])
        cur_img = gca;

        subplot(1, 2, 2)
        plot(i, cc_sort, 'b'), hold on
        ylim = [0 1];
        set(gca, 'YLim', ylim, 'XLim', [1 i(end)]);
        h = imline(gca,[1 1], ylim);
        setColor(h,[1 0 0]);
        setPositionConstraintFcn(h, @(pos)[ min( i(end), max(1,[pos(2,1);pos(2,1)])) ylim'   ])

        id = addNewPositionCallback(h, @(pos) update_img(  data(t).particles_rot(:,:,sort_index(  max(1, min(i(end), round(pos(1,1))))   ) ), cur_img )  );
        id2 = addNewPositionCallback(h, @(pos) title(['cc = ' num2str( cc_sort(  max(1, min(i(end), round(pos(1,1))))) )]) );

        pos_line = wait(h);
        limit_index = max(1, min(i(end), round(pos_line(1,1))));
        limit(t) = cc_sort(limit_index);

    end
    pause(0.1)
    close all
end
pause(0.1)
close all

%% write  refining 
dlmwrite([path_out filesep 'cc_thresholds_ref_cc_min.txt'], [ [1:n_ref/(mirror+1)]' limit], '\t');

%%

data_refined(n_ref/(mirror+1)) = struct('stats', [], 'particles', [],  'particles_rot', []);

w = 4*box_size/2;
for t=1:n_ref/(mirror+1)
    
    index = find(data(t).stats(:,3)>limit(t));
    stats = zeros(size(index, 1),5);

    p = zeros(2*w+1, 2*w+1, size(index, 1), 'uint16');
    p_rot = zeros(2*w+1, 2*w+1, size(index, 1), 'uint16');

    for i=1:size(index,1)
        stats(i,:) = data(t).stats(index(i),:);
        p(:,:,i) = data(t).particles(:,:,index(i));
        p_rot(:,:,i) = data(t).particles_rot(:,:,index(i));
    end
    
    data_refined(t).stats = stats;
    data_refined(t).particles = p;
    data_refined(t).particles_rot = p_rot;
    
end
clear('p', 'p_rot')


%% write particles for each reference 
disp('Writing particles...')

for t=1:n_ref/(mirror+1)
    % write as spider-file
    %writeSPIDERfile([path_out filesep prefix '_ref_' num2str(t) '.spi'], data_refined(t).particles, 'stack')
    %writeSPIDERfile([path_out filesep prefix '_ref_' num2str(t) '_rot.spi'], data_refined(t).particles_rot, 'stack')
  
    % write a img file
    WriteImagic(data_refined(t).particles, [path_out filesep prefix '_ref_' num2str(t)])

    % write as single tif-files
    path_out_tif1 = [path_out filesep prefix '_ref_' num2str(t) '_tif'];
    path_out_tif2 = [path_out filesep prefix '_ref_' num2str(t) '_rot_tif'];
    %path_out_spi = [path_out filesep prefix '_ref_' num2str(t) '_spi'];
    
    mkdir(path_out_tif1)
    mkdir(path_out_tif2)
    %mkdir(path_out_spi)
    
    for i=1:size(data_refined(t).particles, 3)
        imwrite(data_refined(t).particles(:,:,i), [path_out_tif1 filesep 'ref_' num2str(t) '_' sprintf('%.3i',i) '.tif' ]);
        imwrite(data_refined(t).particles_rot(:,:,i), [path_out_tif2 filesep 'ref_' num2str(t) '_' sprintf('%.3i',i) '.tif' ]);
        %writeSPIDERfile([path_out_spi filesep 'ref_' num2str(t) '_' sprintf('%.3i',i) '.spi' ], data_refined(t).particles(:,:,i))
    end
end

%% write all particles
% write as spider-file
%writeSPIDERfile([path_out filesep 'all.spi'], cat(3,data.particles), 'stack')


%% write as img file
WriteImagic(cat(3,data.particles), [path_out filesep 'all'])

%% write as single tif-files
%{
path_out_tif = [path_out filesep 'all_tif'];
mkdir(path_out_tif)
m = 1;
for t=1:n_ref/(mirror+1)
    for i=1:size(data(t).particles, 3)
        imwrite(data(t).particles(:,:,i), [path_out_tif filesep 'all_' sprintf('%.3i',m) '.tif' ]);
        m = m+1;
    end
end
%}

%% display images and found particles
disp('Plotting images...')

cc = varycolor(n_ref);
close all
cur_fig = figure('Visible', 'off', 'OuterPosition', [0 0 1000 800]); 

myleg = cell(n_ref,1);
for t=1:n_ref
    myleg{t} = ['Ref. ' num2str(t)];
end

w = box_size/2;

for i=1:n_img
    subplot(1, 2, 1)
    imagesc(img3(:,:,i)), colorbar,  colormap gray, axis image, hold on % img2
    h = zeros(n_ref,1);
    for r=1:n_ref
        h(r) = plot(peaks_ref{r,i}(:,1), peaks_ref{r,i}(:,2),  '+', 'color', cc(r,:), 'MarkerSize', 1);
        
        for j=1:size(peaks_ref{r,i},1)
            rectangle('Position',[peaks_ref{r,i}(j,1)-w, peaks_ref{r,i}(j,2)-w, 2*w+1, 2*w+1], 'EdgeColor', cc(r,:))
        end
    end
    title(['Image ' num2str(i) '/' num2str(n_img) ])
    legend(h, myleg)
    hold off
    
    subplot(1, 2, 2)
    imagesc(images(:,:,i)), colorbar, colormap gray, axis image, hold on %
    for r=1:n_ref
        h(r)=plot(peaks_ref{r,i}(:,1), peaks_ref{r,i}(:,2),  'x', 'color', cc(r,:), 'MarkerSize', 1);
        for j=1:size(peaks_ref{r,i},1)
            rectangle('Position',[peaks_ref{r,i}(j,1)-w, peaks_ref{r,i}(j,2)-w, 2*w+1, 2*w+1], 'EdgeColor', cc(r,:))
        end
    end
    title(['Image ' num2str(i) '/' num2str(n_img) ])
    legend(h, myleg)
    hold off
       
    %pause
    print(cur_fig, '-dtiff', '-r200', [path_out filesep 'image2_' sprintf('%.03i',i) '.tif'])

end


disp('finished')

