function lane_profile_data = normalize_lanes(lane_profile_data, migration_speeds, nr_steps, varargin)
%% normalizes profiles, taking into account migration speed normalization factors and image resolution from metadata
% INPUTS: 
%   lane_profile_data from get_gel_lanes()
%   migration_speeds, array of migration speed values for each lane
%   nr_steps, number of points in interpolated new rescaled profiles and x_ranges
%   OPTIONAL
%       resolution, if 'on', further normalizes lane profiles by dividing by image resolution

% OUTPUT:
%   lane_profile_data with added field .normalized_profiles

%% parse input variables
p = inputParser;
% required parameter
addRequired(p,'lane_profile_data');
addRequired(p,'migration_speeds');

% optional parameter: switch if image resolution should be used to normalize data
default_resolution  = 'off';
addParameter(p, 'resolution', default_resolution,  @ischar);

% parse variables
parse(p, lane_profile_data, migration_speeds, varargin{:});

% save optional variable
resolution = p.Results.resolution;

%% normalize lanes by migration_speeds

number_of_channels = size(lane_profile_data.profiles, 1)
number_of_lanes = size(lane_profile_data.profiles, 2)
profile_length = length(lane_profile_data.profiles{1,1})

for current_channel = 1:number_of_channels
    for current_lane = 1:number_of_lanes
        % generate x range
        x_range = 1:profile_length;
        % correct for pocket position
        x_range = x_range - lane_profile_data.pocketPositions(current_lane);
        % correct for migration speed
        x_range = x_range ./ migration_speeds(current_lane);

        % load profile data
        profile_data = lane_profile_data.profiles{current_channel, current_lane};
        % adjust profile height to account for x_range rescaling, conserving profile integral
        profile_data = profile_data .* migration_speeds(current_lane);
        
        % adjust for image resolution if variable is set to 'on'
        if strcmp(resolution, 'on')
        	profile_data = profile_data ./ lane_profile_data.metadata{current_channel}.XResolution...
                                    ./ lane_profile_data.metadata{current_channel}.YResolution;
        end
        
        x_ranges(current_channel, current_lane, :) = x_range;
        normalized_profiles(current_channel, current_lane, :) = profile_data;
    end
end

% largest initial x value of all rescaled ranges
largest_x_range_start = max(max(x_ranges(:,:,1)));
% smallest last x value of all rescaled ranges
smallest_x_range_end = min(min(x_ranges(:,:,end)));
% new stepsize in rescaled x_range
step_size = (smallest_x_range_end - largest_x_range_start) / nr_steps;

% generate new x_range, identical for all rescaled lane profiles
rescaled_x_range = largest_x_range_start:step_size:smallest_x_range_end;

for current_channel = 1:number_of_channels
    for current_lane = 1:number_of_lanes
        % load current profile and x_range
        x_range = squeeze(x_ranges(current_channel, current_lane, :));
        profile_data = squeeze(normalized_profiles(current_channel, current_lane, :));
        % generate interpolated profile over unified rescaled_x_range
        rescaled_profiles{current_channel,current_lane} = interp1(x_range, profile_data, rescaled_x_range, 'spline');
    end
end

%% add rescaled profiles and x_range to lane_profile_data
lane_profile_data.rescaled_profiles = rescaled_profiles;
lane_profile_data.rescaled_x_range = rescaled_x_range;

end