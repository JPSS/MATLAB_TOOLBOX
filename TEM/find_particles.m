function [ peaks_ref, peaks, img3 ] = find_particles( templates, images, dalpha , box_size)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

box_size_template = size(templates, 1);
n_ref = size(templates, 3);
n_img = size(images, 3);
img_size = size(images, 1);

disp('Calculating x-correlation...')
alpha = 0:dalpha:359;
n_rot = length(alpha); % number of rotations
dx = int16((box_size_template-box_size-1)/2);

peaks = cell(n_ref, n_img);
peaks2 = cell(n_ref, n_img);

h = waitbar(0,'Calculating x-correlation... ? time remaining');

for t=1:n_ref
    % generate library
    lib = zeros(box_size+1, box_size+1, length(alpha));
    for j=1:n_rot
        tmp = imrotate(templates(:,:,t), alpha(j), 'crop');
        lib(:,:,j) = tmp(dx:dx+box_size, dx:dx+box_size);
    end

    %loop through images
    img3 = zeros(img_size, img_size, n_img); % stores maximum of cor-coef of all rotations
    img3_index = zeros(img_size, img_size, n_img); % stores index of maximum
    
    for i=1:n_img
        tic
        xcor_img = zeros(img_size, img_size, n_rot);
        
        for r=1:n_rot % loop through rotations
            tmp = normxcorr2(lib(:,:,r), images(:,:,i)); % x-correlate
            xcor_img(:,:,r) = tmp(box_size/2+1:end-box_size/2, box_size/2+1:end-box_size/2);
        end
        

        for k=1:512
        for l=1:512
            [cmax, imax] = max(xcor_img(k,l,:));
            img3(k,l,i) = cmax;
            img3_index(k,l,i) = imax;
        end
        end

        %find peaks in img3
        tmp = img3(box_size/2+1:end-box_size/2, box_size/2+1:end-box_size/2,i);
        h_min = mean(tmp(:)) + 0.25*std(tmp(:));
    
        p = find_peaks2d(tmp, round(box_size/4), h_min, 0); % radius of window, minimal height,  no absolure = relative height
        if length(p) > 0
            p(:,1:2) = p(:,1:2)+box_size/2+1;
            tmp = img3(:,:,i);
            tmp_index = img3_index(:,:,i);
            idx = sub2ind(size(tmp), p(:,2), p(:,1) );
            peaks{t,i} = [p(:,1:2) tmp(idx) alpha(tmp_index(idx))']; % x y coer_coef alpha 

            display(['Reference (' num2str(t) '/' num2str(n_ref) '): image (' num2str(i) '/' num2str(n_img) '), found ' num2str(size(p,1)) ' particles' ])

        end

        % compute time left
        if t==1 && i==1
            dt = toc;
        else
            dt_this = toc;
            dt = (dt+dt_this)/2;
        end
        frac = ((t-1)*n_img+i) / (n_ref*n_img);
        n_remain = (n_ref*n_img)-((t-1)*n_img+i);
        waitbar( frac , h, ['Calculating x-correlation... ' num2str(round(n_remain*dt/60*10)/10) ' min remaining']) 
    end
end
pause(0.1)
close(h)
close all



%% remove particles, which belong to multiple classes
%cc = varycolor(n_ref);
peaks_ref = cell(n_ref, n_img);
h = waitbar(0,'Searching for particles... ');

for i=1:n_img
    disp(['refining ' num2str(i) ])
    
    % genertate image of  correlations
    cor_img = zeros(img_size,img_size );
    cor_img_index = zeros(img_size,img_size );
    rot_img = zeros(img_size,img_size );
    for r=1:n_ref
        idx = sub2ind(size(cor_img), peaks{r,i}(:,2), peaks{r,i}(:,1) );
        cor_img(idx) = peaks{r,i}(:,3);
        cor_img_index(idx) = r;
        rot_img(idx) = peaks{r,i}(:,4);
    end
    
    p = find_peaks2d(cor_img, round(box_size/4), 0, 1 ); % find-peaks, width, min_height, absolute height 
    p(:,1:2) =  p(:,1:2)+1;
    
    for j=1:size(p,1)
        peaks_ref{cor_img_index(p(j,2),p(j,1)),i} = [peaks_ref{cor_img_index(p(j,2),p(j,1)),i}; p(j,1:2) cor_img(p(j,2),p(j,1)) rot_img(p(j,2),p(j,1)) ];
    end
    
    %{
     close all
    imagesc(cor_img), colorbar,  colormap gray, axis image, hold on % img2

    for r=1:n_ref
        plot(peaks{r,i}(:,1), peaks{r,i}(:,2),  'o', 'color', cc(r,:))
        plot(peaks_ref{r,i}(:,1), peaks_ref{r,i}(:,2),  '.', 'color', cc(r,:));

    end
    pause 
    %}
    
    waitbar( i/n_img , h, 'Searching for particles... ')

    
end
close(h);
pause(0.1);
  


end

