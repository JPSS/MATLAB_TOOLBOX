function [ results ] = load_profire_csv(varargin)
%% load profire csv data output

%% parse input variables
p = inputParser;
    
%% load data
% select file to open
[filename, pathname] = uigetfile('*','select profire csv data','MultiSelect','off');

% number of lines in csv file
nr_lines = 30;
% text data, each cell one line
data_text_lines = cell(nr_lines,1);

% open file
current_file = fopen([pathname filename],'r');
%print filename
filename

% load strings from file
for current_line = 1:nr_lines
    % load one line
    data_text_lines{current_line} = fgetl(current_file);
end

% parse data
Valve1_strings = strsplit(data_text_lines{12},';');
Valve1_numbers = str2double(Valve1_strings);

Signal_strings = strsplit(data_text_lines{18},';');
Signal_numbers = str2double(Signal_strings);

Valve2_strings = strsplit(data_text_lines{24},';');
Valve2_numbers = str2double(Valve2_strings);

Pressure_strings = strsplit(data_text_lines{30},';');
Pressure_numbers = str2double(Pressure_strings);

% close file
fclose(current_file);

% create results object
results.Position_strings = Valve1_strings;
results.Position_numbers = Valve1_numbers;
results.Signal_strings = Signal_strings;
results.Signal_numbers = Signal_numbers;
results.Position2_strings = Valve2_strings;
results.Position2_numbers = Valve2_numbers;
results.Pressure_strings = Pressure_strings;
results.Pressure_numbers = Pressure_numbers;

return