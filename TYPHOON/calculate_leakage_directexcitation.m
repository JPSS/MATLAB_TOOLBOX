function [leak_dir, cur_fig] = calculate_leakage_directexcitation(dd, da, aa, varargin)
%computes leakage and direct excitation correction from dd, da
% and aa image
%   Input:
%           dd = image of Donor excitation -> Donor emission
%           da = image of Donor excitation -> Acceptor emission
%           aa = image of Acceptor excitation -> Acceptor emission
%           display = on / off (optional) to show a plot 
%   Example:
%           calculate_leakage_directexcitation(dd, da, aa)
%           calculate_leakage_directexcitation(dd, da, aa, 'display', 'on')

%% check input variables
p = inputParser;
default_display = 'off';
expected_display = {'on', 'off'};

addRequired(p,'dd',@isnumeric);
addRequired(p,'da',@isnumeric);
addRequired(p,'aa',@isnumeric);

addParameter(p,'display', default_display,  @(x) any(validatestring(x,expected_display))); % check display is 'on' or 'off'

parse(p, dd, da, aa, varargin{:});
display_plot = strcmp(p.Results.display, 'on');

%% Integrate D-only and A-only band
[I_mean, areas] = integrate_areas({dd, da, aa}, 2, 'message', 'Select D-only and A-only area.'); %cell of images, number of bands



%% calculate corrections 

% d-only
pos = areas(1,:);
band_dd = dd(pos(2):pos(2)+pos(4),pos(1):pos(1)+pos(3));
band_da = da(pos(2):pos(2)+pos(4),pos(1):pos(1)+pos(3));

[p_leak, DA_donly, DD_donly] = calculate_ration_of_areas(band_da, band_dd);

% a-only
pos = areas(2,:);
band_aa = aa(pos(2):pos(2)+pos(4),pos(1):pos(1)+pos(3));
band_da = da(pos(2):pos(2)+pos(4),pos(1):pos(1)+pos(3));

[p_dir, DA_aonly, AA_aonly] = calculate_ration_of_areas(band_da, band_aa);

%% plot
if display_plot
    % compute profiles
    donly_profiles = [[areas(1,2):areas(1,2)+areas(1,4)]' ...
        sum(dd(areas(1,2):areas(1,2)+areas(1,4), areas(1,1):areas(1,1)+areas(1,3))')' ...
        sum(da(areas(1,2):areas(1,2)+areas(1,4), areas(1,1):areas(1,1)+areas(1,3))')' ...
        sum(aa(areas(1,2):areas(1,2)+areas(1,4), areas(1,1):areas(1,1)+areas(1,3))')'];

    aonly_profiles = [[areas(2,2):areas(2,2)+areas(2,4)]' ...
        sum(dd(areas(2,2):areas(2,2)+areas(2,4), areas(2,1):areas(2,1)+areas(2,3))')' ...
        sum(da(areas(2,2):areas(2,2)+areas(2,4), areas(2,1):areas(2,1)+areas(2,3))')' ...
        sum(aa(areas(2,2):areas(2,2)+areas(2,4), areas(2,1):areas(2,1)+areas(2,3))')'];

    cur_fig = figure();
    % plot dd vs da
    subplot(2, 2, 1)
    xlim = [min(DD_donly(:)) max(DD_donly(:))];
    plot(DD_donly(:), DA_donly(:), 'g.', xlim, p_leak(1)*xlim+p_leak(2), 'k' ,'MarkerSize', 1)
    legend({'Data', ['Fit, leak=' num2str(round(p_leak(1)*100)) '%']}, 'FontSize', 10, 'Location', 'SouthEast')
    xlabel('D->D')
    ylabel('D->A')
    title('Leakage correction')
    set(gca, 'XLim', [xlim(1) xlim(2)*1.2])

    % plot profile
    subplot(2, 2, 2)
    plot(donly_profiles(:,1), p_leak(1,1)*donly_profiles(:,2), 'g', donly_profiles(:,1), donly_profiles(:,3), 'b', donly_profiles(:,1), donly_profiles(:,3)-donly_profiles(:,2)*p_leak(1,1), 'b--' )
    legend({'D->D, scaled', 'D->A', 'D->A corrected'}, 'FontSize', 10)
    xlabel('Migration distance [pixel]')
    ylabel('Intensity')
    set(gca, 'XLim', [donly_profiles(1,1) donly_profiles(end,1)])

    % plot aa vs da
    subplot(2, 2, 3)
    xlim = [min(AA_aonly(:)) max(AA_aonly(:))];
    plot(AA_aonly(:), DA_aonly(:), 'r.', xlim, p_dir(1)*xlim+p_dir(2), 'k' ,'MarkerSize', 1)
    legend({'Data', ['Fit, dir=' num2str(round(p_dir(1)*100)) '%']}, 'FontSize', 10, 'Location', 'SouthEast')
    xlabel('A->A')
    ylabel('D->A')
    title('Direct excitation correction')
    set(gca, 'XLim', [xlim(1) xlim(2)*1.2])

    % plot profile
    subplot(2, 2, 4)
    plot(aonly_profiles(:,1), p_dir(1,1)*aonly_profiles(:,4), 'r', aonly_profiles(:,1), aonly_profiles(:,3), 'b', aonly_profiles(:,1), aonly_profiles(:,3)-aonly_profiles(:,4)*p_dir(1,1), 'b--' )
    legend({'A->A, scaled', 'D->A', 'D->A corrected'}, 'FontSize', 10)
    xlabel('Migration distance [pixel]')
    ylabel('Intensity')
    set(gca, 'XLim', [aonly_profiles(1,1) aonly_profiles(end,1)])

   % print(cur_fig, '-depsc2','-loose' , [file_out(1:end-4) '_corrections']); %save figure

    %display('Press some key to continue...')
   % questdlg('Go on','Halt','Go on','Go on');
   % close(cur_fig)
else
    cur_fig = [];
end

%% compine to matrix
leak_dir = [p_leak ; p_dir]; 
disp(['Leakage: ' num2str(round(p_leak(1)*100)) '% Direct Ex.: ' num2str(round(p_dir(1)*100)) '%' ])


end

