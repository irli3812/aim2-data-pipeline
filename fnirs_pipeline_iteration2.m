%% TRINITY AIM 2 - fNIRS Data Analysis for Corollary Data
% AIM2_FNIRS_PIPELINE_SAGETUTORIALBASED
%
% Purpose: Analyze a single fNIRS file
%% Run event extraction for time series data
[~,~, events_cor, events_rov, path_rov, path_cor] = extract_events();
%% isolate HbO and HbR columns - optode pairs (from ExtractData.m)
% chanNames = fnirs_rov(42:81, :);
chanNames = cell(length(42:81),1);   % Initialize 40x1 cell array
for i = 42:81   % loop that iterates over the integers from 42 to 81 inclusive
    chanNames{i-40} = time_series.info.desc.channels.channel{1,i}.custom_name;  % cell array or structure where the i-th element contains a field 'custom_name'
end

%% Separating Data
HbO_raw = time_series(42:61,:);
HbR_raw = time_series(62:81,:);

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