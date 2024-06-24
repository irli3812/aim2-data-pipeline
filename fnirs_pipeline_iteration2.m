%% TRINITY AIM 2 - fNIRS Data Analysis for Rover+Corollary Data
% AIM2_FNIRS_PIPELINE_SAGETUTORIALBASED
%
% Purpose: Analyze an xdf fNIRS time-series streams for an entire session
%% Run event extraction for time series data
[~,~, events_cor, events_rov, path_rov, path_cor] = extract_events();
%% isolate HbO and HbR columns - optode pairs (from ExtractData.m)
% confused what this is for...?
% for rover:
chanNames = cell(length(42:81),1);   % Initialize 40x1 cell array
for i = 42:81   % loop that iterates over the integers from 42 to 81 inclusive
    chanNames{i-40} = fnirs_rov.time_series.info.desc.channels.channel{1,i}.custom_name;  % cell array or structure where the i-th element contains a field 'custom_name'
end

%% Separating Data
% rover HbO/HbR rows
HbO_raw = fnirs_rov.time_series(42:61,:);
HbR_raw = fnirs_rov.time_series(62:81,:);
% corollary HbO/HbR rows
HbO_raw = fnirs_cor.time_series(42:61,:);
HbR_raw = fnirs_cor.time_series(62:81,:);

%% Plotting raw fNIRS data (entire session)
fig_num = fig_num+1;
figure(fig_num);
hold on;
grid on;


for j = 1:9999 % edit 9999 to be numTrials (depends on each subject/session) - need function
    rectangle('position', [trial(i,1) -6 ...
            trial(i,end)-trial(i,1) 12], 'FaceColor', [0.5 1 0.5 0.5]);
end

plot()