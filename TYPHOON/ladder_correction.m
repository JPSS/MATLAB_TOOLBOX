function [ gel_data ] = ladder_correction(gel_data , data_channel, ladder_channel, intensity_multiplicator)
%% fit 6 gaussians to 6 DNA ladder bands in each lane, correct lane profiles using fits
%   INPUTS: gel_data from load_gel_image.m
%           data_channel is number of channel with sample data
%           ladder_channel is number of channel that contains DNA ladder information for lane adjustments
%           intensity_multiplicator scales ladder_channel image before subtracting data_channel from it to remove all non-Ladder data.
%               should be set <1 usually so that all non-Ladder data is negative and will be set to 0
%   OUTPUT:
%   results struct with .gaussFitcoeffs .mean_ladder_speeds
%   .gaussFitcoeffs are coefficients of 6 gauss fit for each lane
%   .mean_ladder_speeds is list[lane] mean speed of ladder bands
%  Example = folding_time_determination(gel_data, 1:20, -0.05, 0.8, 851, 0.5)


%number of datapoints in profiles
profile_length = length(gel_data.profiles{1,1})
num_lanes = size(gel_data.profiles,2)

%data before pocket_offset + pocket_position is ignored for fitting because it usually has large fluctuations in data
pocket_offset = 20;

%% subtract data channel from intensity_multiplicator * ladder channel, set negative values to 0 to create ladder only profile
ladder_minus_data = zeros(profile_length, num_lanes);            
for i = 1:num_lanes
    %last values of data and ladder channel
    background_data = gel_data.profiles{data_channel, i}(end);
    background_ladder = gel_data.profiles{ladder_channel, i}(end);
    
    ladder_minus_data(:,i) = intensity_multiplicator * (gel_data.profiles{ladder_channel,i} - background_ladder)...
                                - (gel_data.profiles{data_channel,i} - background_data);
end
%set all negative values of ladder only profile to zero to make flat background
ladder_minus_data(ladder_minus_data < 0) = 0;                                                 

%% fit dna ladder bands using 6 gaussians
fig = figure('units','normalized','outerposition',[0 0 1 1]);

button = 'No';
while strcmp(button,'No')  
    fit_function = fittype('gauss6');
    %select start values for gauss fit
    plot(ladder_minus_data(:,1));
    title('select 6 peak tops for start values x and y');
    [x,y] = ginput(6);

    %start values for fit. are taken from previous fit result after first fit
    startValues = zeros(1, 6 * 3);
    %gauss amplitudes
    startValues(1:3:end) = y;
    %gauss x-locations, from profile start
    startValues(2:3:end) = x;
    %gauss width
    startValues(3:3:end) = 20;

    %coefficients of 6 gauss fit, distance is from start of profile, not pocket positions
    gauss_fit_coeffs = zeros(num_lanes, 6 * 3);
    
    %fit gausses for every lane.  (starting from pocketPosition + pocketOffset)
    for i = 1:num_lanes
        current_pocket_start = gel_data.pocketPositions(i) + pocket_offset;
        [fit_result{i}, gof, output] = fit((current_pocket_start:profile_length).', ladder_minus_data(current_pocket_start:end,i),...
                                                fit_function, 'StartPoint', startValues);
        gauss_fit_coeffs(i,:)=coeffvalues(fit_result{i});
        startValues=gauss_fit_coeffs(i,:);
    end

    %plot fit results to check if fits are good
    for i = 1:num_lanes
        %plot data
        plot((current_pocket_start:profile_length), ladder_minus_data(current_pocket_start:end,i)/max(ladder_minus_data(current_pocket_start:end,i)) + i - 1);
        hold on
        %plot fits
        plot((current_pocket_start:profile_length),...
            feval(fit_result{i}, (current_pocket_start:profile_length).')/max(feval(fit_result{i},(current_pocket_start:profile_length).')) + i - 1);
        %plot fit peak positions
        for j = 1:6
            plot([gauss_fit_coeffs(i,j*3 - 1) gauss_fit_coeffs(i,j*3 - 1)],[i-1, i])
        end
    end
    button = questdlg('are the fits ok?','are the fits ok?' ,'No','Yes', 'Yes');
    clf
end
close(fig);    

%mean DNA ladder speed of each lane, relative to its pocket position
mean_ladder_speeds = mean(gauss_fit_coeffs(:,2:3:end).') - gel_data.pocketPositions;

results = struct('gauss_fit_coeffs',{gauss_fit_coeffs});
results.('mean_ladder_speeds') = mean_ladder_speeds;

gel_data.('ladder_correction') = results;
return