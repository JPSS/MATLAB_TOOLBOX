function [ B_shift, dx_min, dy_min ] = overlay_image( imgA, imgB, search_range )
%find the optimal shift to overlay images A and B, based on minimizing
%chi2 = sum_(i,j) (a_ij - beta * b_ij)^2 / N / M  
% N and M are the dimesions of the overlay
% A and B should be equal in size


%% select area, which should be considered
plot_image_ui(double(imgA));
title('Image A: Select area for overlay')
h = imrect;
position = wait(h);
pos = int32(getPosition(h)); % [xmin ymin width height]
close all
pause(0.1)

A = double(imgA(pos(2):pos(2)+pos(4)  ,   pos(1):pos(1)+pos(3) ) );
B = double(imgB(pos(2):pos(2)+pos(4)  ,   pos(1):pos(1)+pos(3) ) );
%%
[cc, shift, B_shift] = xcorr2_bounded(A, B, search_range, 1);
dx_min = shift(1);
dy_min = shift(2);

%{
beta = sum(A(:))./sum(B(:)); % detection efficiency factor between the two channels

dx_min = 0;
dy_min = 0;

chi2min = inf; % sum(  (A(:)-beta*B(:)).^2   ) ./ size(A,1) / size(A,2); % init minim
chi2 = zeros(search_range*2+1, search_range*2+1);

display('Searching for optimal overlay... please wait')
for dy=-search_range:search_range
    for dx=-search_range:search_range
        
        asub = A( max(1,1+dy):min(end, end+dy ), max(1,1+dx):min(end, end+dx )  ); % sub image to be overlayed
        bsub = B( max(1, 1-dy):min(end-dy, end)      , max(1,1-dx):min(end-dx, end)   ); % sub image to be overlayed

        %chi2(dy+search_range+1,dx+search_range+1 ) = -sum( asub(:) .* bsub(:) ) / numel(asub); % x-correlation current
        
        
        chi2(dy+search_range+1,dx+search_range+1 ) = sum( (asub(:) - beta*bsub(:) ).^2 ) / numel(asub); %calculate current chi2
        
        if chi2(dy+search_range+1,dx+search_range+1 ) < chi2min
            dx_min = dx;
            dy_min = dy;
            chi2min = chi2(dy+search_range+1,dx+search_range+1 );
            %disp([dx dy])
        end

    end
end

display(['Optimum found for dx = ' num2str(dx_min) ' and dy = ' num2str(dy_min)])

if abs(dx_min)==search_range || abs(dy_min)==search_range
    display('Optimal shift found is equal to search_range. Increasing search_range is recommended.')
end
%}


%%
%{
close all
subplot(3, 1, 1)
imagesc(A-beta*B, [1 1e4]), colormap gray; axis image; colorbar
title(['Difference of original images (dx = ' num2str(0) ' , dy = ' num2str(0) ')' ])

subplot(3, 1, 2)
dx = dx_min; dy = dy_min; 
asub = A( max(1,1+dy):min(end, end+dy ), max(1,1+dx):min(end, end+dx )  ); % sub image to be overlayed
bsub = B( max(1, 1-dy):min(end-dy, end)      , max(1,1-dx):min(end-dx, end)   ); % sub image to be overlayed

imagesc(asub-beta*bsub, [1 1e4]), colormap gray; axis image; colorbar
title(['Difference of shifted images (dx = ' num2str(dx_min) ' , dy = ' num2str(dy_min) ')'])

subplot(3, 1, 3)
dx = -1; dy = -4; 
asub = A( max(1,1+dy):min(end, end+dy ), max(1,1+dx):min(end, end+dx )  ); % sub image to be overlayed
bsub = B( max(1, 1-dy):min(end-dy, end)      , max(1,1-dx):min(end-dx, end)   ); % sub image to be overlayed

imagesc(asub-beta*bsub, [1 1e4]), colormap gray; axis image; colorbar
title(['Difference of shifted images (dx = ' num2str(dx_min) ' , dy = ' num2str(dy_min) ')'])
%}

%%
scrsz = get(0,'ScreenSize');

close all


figure('OuterPosition',[ 1 scrsz(4) scrsz(3)*0.4 scrsz(4)/2])
% generate output image
padval = mean(imgB(:));
B_shift = padval*ones(size(imgB)); % pad with mean of imgB
bsub = imgB( max(1, 1-dy_min):min(end-dy_min, end)      , max(1,1-dx_min):min(end-dx_min, end)   );
B_shift(  max(1,1+dy_min):min(end+dy_min ,end),  max(1,1+dx_min):min(end+dx_min ,end) ) = bsub; % set B_shift

beta = sum(imgA(:))./sum(imgB(:));

% plot result
scale = [min(imgA(:)-beta*imgB(:)) mean(imgA(:)-beta*imgB(:))+std(double(imgA(:)-beta*imgB(:))) ];

subplot(2, 1, 1)
imagesc(imgA-beta*imgB, scale), colormap gray; axis image; colorbar
title(['Difference of original images (dx = ' num2str(0) ' , dy = ' num2str(0) ')' ])

subplot(2, 1, 2)
imagesc(double(imgA)-beta*B_shift, scale), colormap gray; axis image; colorbar
title(['Difference of shifted images (dx = ' num2str(dx_min) ' , dy = ' num2str(dy_min) ')'])

figure('OuterPosition',[ scrsz(3)*0.5 scrsz(4) scrsz(3)*0.4 scrsz(4)/2])
imagesc(cc, [max(cc(:))-(max(cc(:))-min(cc(:)))/8 max(cc(:))]),  colorbar, axis image, hold on
plot(dx_min+search_range+1, dy_min+search_range+1, 'g.')
legend({['Max. corr. found for dx = ' num2str(dx_min) ' and dy = ' num2str(dy_min)]})
%% pause


end

