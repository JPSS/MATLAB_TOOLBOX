function [ B_shift, dx_min, dy_min, figures ] = overlay_image( imgA, imgB, varargin )
%find the optimal shift to overlay images A and B, based on maximizing
%cross-correlation
% Input:    imgA = Image A
%           imgB = Image B
%           search_range (optional) = range (in pixel), that will be
%           considered
% Output:   B_shift = Image B shifted, that it correlates with image B
%           dx_min = shift in x
%           dy_min = shift in y
%           figures = handles to figures
% Example:  [b_shift] = overlay_image(a, b, 'search_range', 5, 'display', 'on');
%% parse input
p = inputParser;
expected_display = {'on', 'off'};

addRequired(p,'imgA', @isnumeric); %
addRequired(p,'imgB', @isnumeric); %
addParameter(p,'search_range', 10, @isnumeric); % check search_range, default=10 pixel
addParameter(p,'is', 10, @isnumeric); % check search_range, default=10 pixel
addParameter(p,'display', 'on',  @(x) any(validatestring(x,expected_display))); % check display is 'on' or 'off'

parse(p, imgA, imgB, varargin{:});
search_range = p.Results.search_range;
display_bool = strcmp(p.Results.display, 'on');

% check for sizes of images
if ~( (size(imgA,1)==size(imgB,1)) && (size(imgA,2)==size(imgB,2)) )
    disp('Warning: A and B do not have the same size.')
end
%% select area, which should be considered
cur_fig = plot_image_ui(double(imgA));
title('Image A: Select area for overlay')
h = imrect;
position = wait(h);
pos = int32(getPosition(h)); % [xmin ymin width height]
close(cur_fig)
pause(0.1)

A = double(imgA(pos(2):pos(2)+pos(4)  ,   pos(1):pos(1)+pos(3) ) );
B = double(imgB(pos(2):pos(2)+pos(4)  ,   pos(1):pos(1)+pos(3) ) );

%% determine shift based on chosen area
[cc, shift, ~] = xcorr2_bounded(A, B, search_range, 1);
dx_min = shift(1);
dy_min = shift(2);

%% generate output image
padval = mean(imgB(:));
B_shift = padval*ones(size(imgB)); % pad with mean of imgB
bsub = imgB( max(1, 1-dy_min):min(end-dy_min, end)      , max(1,1-dx_min):min(end-dx_min, end)   );
B_shift(  max(1,1+dy_min):min(end+dy_min ,end),  max(1,1+dx_min):min(end+dx_min ,end) ) = bsub; % set B_shift


%% plot results
if display_bool
    beta = sum(imgA(:))./sum(imgB(:));

    figures(1) = figure();
    scale = [min(imgA(:)-beta*imgB(:)) mean(imgA(:)-beta*imgB(:))+std(double(imgA(:)-beta*imgB(:))) ];

    subplot(2, 1, 1)
    imagesc(imgA-beta*imgB, scale), colormap gray; axis image; colorbar
    title(['Difference of original images (dx = ' num2str(0) ' , dy = ' num2str(0) ')' ])

    subplot(2, 1, 2)
    imagesc(double(imgA)-beta*B_shift, scale), colormap gray; axis image; colorbar
    title(['Difference of shifted images (dx = ' num2str(dx_min) ' , dy = ' num2str(dy_min) ')'])

    figures(2) = figure; %('OuterPosition',[ scrsz(3)*0.5 scrsz(4) scrsz(3)*0.4 scrsz(4)/2])
    imagesc(cc, [max(cc(:))-(max(cc(:))-min(cc(:)))/8 max(cc(:))]),  colorbar, axis image, hold on
    plot(dx_min+search_range+1, dy_min+search_range+1, 'g.')
    legend({['Max. corr. found for dx = ' num2str(dx_min) ' and dy = ' num2str(dy_min)]})
else
    figures = [];
end

end

