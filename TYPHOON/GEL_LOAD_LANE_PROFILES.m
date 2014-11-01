%% load lane_data from previous run of GEL_LANE_PROFILES
%filename should end in _lanes_data.txt

[filename pathname]=uigetfile('*_lanes_data.txt','load _lanes_data.txt');
cd(pathname)

%% create output folder

path_out = pathname(1:size(pathname,2)-1);
prefix_out= filename(1:size(filename,2)-15);
cutoffFit1=0;

%% load data

horizontalIntegrals=dlmread([path_out filesep filename ]);

cd(matlab_dir);

%% display data
clf
hold all
for i=1:size(horizontalIntegrals,2)
    plot(horizontalIntegrals(:,i))
end