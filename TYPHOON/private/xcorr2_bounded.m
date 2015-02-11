function [ cc, best_shift, B_out ] = xcorr2_bounded( A, B, search_range, status)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    dx_best = 0;
    dy_best = 0;

    cc_max = 0;
    cc = zeros(search_range*2+1, search_range*2+1);

    if status
        h = waitbar(0,'Searching for optimal overlay... please wait');
    end
    %display('Searching for optimal overlay... please wait')
    counter = 0;
    for dy=-search_range:search_range
        for dx=-search_range:search_range
            asub = A( max(1,1+dy):min(end, end+dy ), max(1,1+dx):min(end, end+dx )  ); % sub image to be overlayed
            bsub = B( max(1, 1-dy):min(end-dy, end)      , max(1,1-dx):min(end-dx, end)   ); % sub image to be overlayed

            cc(dy+search_range+1,dx+search_range+1 ) = corr2(asub, bsub);
            
            if cc(dy+search_range+1,dx+search_range+1 ) > cc_max
                dx_best = dx;
                dy_best = dy;
                cc_max = cc(dy+search_range+1,dx+search_range+1 );
                %disp([dx dy])
            end

            counter = counter+1;
            frac = counter / (2*search_range+1).^2;
            if status
                waitbar( frac , h, 'Searching for optimal overlay... please wait')
            end
        end
    end
    
    if status
        close(h)
    end
    display(['Optimal overlay found for dx = ' num2str(dx_best) ' and dy = ' num2str(dy_best) ', cc_max = ' num2str(cc_max)])

    if abs(dx_best)==search_range || abs(dy_best)==search_range
        display('Optimal shift found is equal to search_range. Increasing search_range is recommended.')
    end

    best_shift = [dx_best dy_best];

    % generate output image B_out
    B_out = mean(B(:)).*ones(size(B)); % pad with mean of B
    B_out(  max(1,1+dy_best):min(end+dy_best ,end),  max(1,1+dx_best):min(end+dx_best ,end) ) = B( max(1, 1-dy_best):min(end-dy_best, end) , max(1,1-dx_best):min(end-dx_best, end) ); 


end

