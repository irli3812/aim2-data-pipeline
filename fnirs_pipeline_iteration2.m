%% TRINITY AIM 2 - fNIRS Data Analysis for Rover+Corollary Data - AS A FUNCTION TO BE CALLED ON IN WRAPPER SCRIPT
% AIM2_FNIRS_PIPELINE_SAGETUTORIALBASED
%
% Purpose: Analyze an xdf fNIRS time-series streams for an entire session
%% Run event extraction for time series data
subject = input('Which subject number (of 3 digits) do you want to run? ', 's');
subject_no = str2double(subject);
if isnan(subject_no) || length(subject) ~= 3
    error('Please enter a valid 3-digit number.');
end
[~,~, events_cor, events_rov, path_rov, path_cor] = extract_events(subject_number, s);
%% isolate HbO and HbR columns - optode pairs (from ExtractData.m)
% confused what this is for...?
% for rover:
% chanNames = cell(length(42:81),1);   % Initialize 40x1 cell array
% for i = 42:81   % loop that iterates over the integers from 42 to 81 inclusive
%     chanNames{i-40} = fnirs_rov.time_series.info.desc.channels.channel{1,i}.custom_name;  % cell array or structure where the i-th element contains a field 'custom_name'
% end

%% Separating Data

% rover HbO/HbR rows
fnirsROVData = fnirs_rov.time_series;
fnirsROVTimes = fnirs_rov.time_stamps;

HbO_ROVraw = fnirsROVData(42:61,:);
HbR_ROVraw = fnirsROVTimes(62:81,:);

% corollary HbO/HbR rows
fnirsCORData = fnirs_cor.time_series;
fnirsCORTimes = fnirs_cor.time_stamps;

HbO_CORraw = fnirsCORData(42:61,:);
HbR_CORraw = fnirsCORTimes(62:81,:);

%% Task Values
% Number of trials
numTrials = 8;
% trialLength = 8*# % [s], _ mins * 60s/min  -- when is this variable used?

%% Plotting raw fNIRS data (entire session)
% rover
fig_num = fig_num+1;
figure(fig_num);
hold on;
grid on;

for j = 1:numTrials
    rectangle('position', [trial(i,1) -8 ...
            trial(i,end)-trial(i,1) 16], 'FaceColor', [0.5 1 0.5 0.5]); % not too sure about -8 and 16
end

plot(fnirsROVTimes, HbO_ROVraw, 'r');
plot(fnirsROVTimes, HbR_ROVraw, 'b');

title('Entire ROVER Session: Raw Hemoglobin Data');
xlabel('Time (s)');
ylabel('Relative Concentration (mmol/L)');

xlim([trial(1) trial(end)]);
ylim([-8,8]);

hold off;

figure(fig_num);
hold on;
grid on;

for j = 1:numTrials
    rectangle('position', [trial(i,1) -8 ...
            trial(i,end)-trial(i,1) 16], 'FaceColor', [0.5 1 0.5 0.5]);
end

plot(fnirsCORTimes, HbO_CORraw, 'r');
plot(fnirsCORTimes, HbR_CORraw, 'b');

title('Entire COROLLARY Session: Raw Hemoglobin Data');
xlabel('Time (s)');
ylabel('Relative Concentration (mmol/L)');

xlim([trial(1) trial(end)]);
ylim([-8,8]);

hold off;

%% Bandpass filtering

% sampling rate
fnirsSrate = str2double(fnirs_rov.info.nominal_srate);
hbO.Fs = fnirsSrate;
hbR.Fs = fnirsSrate;

% issue: hbO.data is set as a variable twice -- could result in error
% rover filtering
hbOrov.data = double(HbO_ROVraw');
hbRrov.data = double(HbR_ROVraw');
hbOrov.time = fnirsROVTimes';
hbRrov.time = fnirsROVTimes';

% corollary filtering
hbOcor.data = double(HbO_CORraw');
hbRcor.data = double(HbR_CORraw');
hbOcor.time = fnirsCORTimes';
hbRcor.time = fnirsCORTimes';

% setting up filter using nirstoolbox
jobs = eeg.modules.BandPassFilter();
jobs.lowpass = 0.500;
jobs.highpass = 0.016;

% rover: running the job
HbO_filtered_struct_rov = jobs.run(hbOrov);
HbR_filtered_struct_rov = jobs.run(hbRrov);

% corollary: running the job
HbO_filtered_struct_cor = jobs.run(hbOcor);
HbR_filtered_struct_cor = jobs.run(hbRcor);

%% transposing the data
% rover:
HbO_filtered_rov = HbO_filtered_struct_rov.data';
time_filtered_rov = HbO_filtered_struct_rov.time';
HbR_filtered_rov = HbR_filtered_struct_rov.data';

% corollary:
HbO_filtered_cor = HbO_filtered_struct_cor.data';
time_filtered_cor = HbO_filtered_struct_cor.time';
HbR_filtered_cor = HbR_filtered_struct_cor.data';

%% Plotting FILTERED fNIRS data - entire session

% rover:
fig_num = fig_num+1;
figure(fig_num);
hold on;
grid on;

for i = 1:numTrials
    rectangle('position',[trial(i,1) -8 ...
        trial(i,end)-trial(i,1) 16],'FaceColor',[0.5 1 0.5 0.5]);  % -8 and 16 again
end

plot(time_filtered_rov,HbO_filtered_rov,'r');
plot(time_filtered_rov,HbR_filtered_rov,'b');

title('Entire Rover Session: Filtered Hemoglobin Data');
xlabel('Time (s)');
ylabel('Relative Concentration (mmol/L)');

xlim([trial(1) trial(end)]);
ylim([-8 8]);
% 
% if trialPlots == 1
%     saveas(gcf,strcat(path,'Entire Session, Filtered fNIRS','.png'));
% end

hold off;

% corollary:
fig_num = fig_num+1;
figure(fig_num);
hold on;
grid on;

for i = 1:numTrials
    rectangle('position',[trial(i,1) -8 ...
        trial(i,end)-trial(i,1) 16],'FaceColor',[0.5 1 0.5 0.5]);  % -8 and 16 again
end

plot(time_filtered_cor,HbO_filtered_cor,'r');
plot(time_filtered_cor,HbR_filtered_cor,'b');

title('Entire Corollary Session: Filtered Hemoglobin Data');
xlabel('Time (s)');
ylabel('Relative Concentration (mmol/L)');

xlim([trial(1) trial(end)]);
ylim([-8 8]);

% if trialPlots == 1
%     saveas(gcf,strcat(path,'Entire Session, Filtered fNIRS','.png'));
% end

%% Plotting by trial

% rover:
for i = 1:numTrials
    % finding start and end time of trial in fNIRS indices
    sidx_rov = find(time_filtered_rov>trial(i,1),1);
    eidx_rov = find(time_filtered_rov<trial(i,end),1,'last');

    % creating vectors of trial-specific data
    HbO_epoch_data_rov = HbO_filtered_rov(:,sidx_rov:eidx_rov);
    HbR_epoch_data_rov = HbR_filtered_rov(:,sidx_rov:eidx_rov);
    epoch_time_rov = time_filtered_rov(sidx_rov:eidx_rov);

    % plotting
    fig_num = fig_num+1;
    figure(fig_num);
    hold on;
    grid on;

    plot(epoch_time_rov, HbO_epoch_data_rov, 'r');
    plot(epoch_time_rov, HbR_epoch_data_rov, 'b');

    title(strcat('Trial',num2str(i),': Filtered Hemoglobin (Rover Condition)'));
    xlabel('Time (s)');
    ylabel('Relative Concentration (mmol/L)');

    xlim([trial(i,1) trial(i,end)]);
    ylim([-8 8]);
    
    % % saving figure
    %   if trialPlots == 1
    %     saveas(gcf,strcat(path,num2str(i),', Rover Filtered fNIRS','.png'));
    % end
end

% corollary:
for i = 1:numTrials
    % finding start and end time of trial in fNIRS indices
    sidx_cor = find(time_filtered_cor>trial(i,1),1);
    eidx_cor = find(time_filtered_cor<trial(i,end),1,'last');

    % creating vectors of trial-specific data
    HbO_epoch_data_cor = HbO_filtered_cor(:,sidx_cor:eidx_cor);
    HbR_epoch_data_cor = HbR_filtered_cor(:,sidx_cor:eidx_cor);
    epoch_time_cor = time_filtered_cor(sidx_cor:eidx_cor);

    % plotting
    fig_num = fig_num+1;
    figure(fig_num);
    hold on;
    grid on;

    plot(epoch_time_cor, HbO_epoch_data_cor, 'r');
    plot(epoch_time_cor, HbR_epoch_data_cor, 'b');

    title(strcat('Trial',num2str(i),': Filtered Hemoglobin (Corollary Condition)'));
    xlabel('Time (s)');
    ylabel('Relative Concentration (mmol/L)');

    xlim([trial(i,1) trial(i,end)]);
    ylim([-8 8]);
    
    % % saving figure
    %   if trialPlots == 1
    %     saveas(gcf,strcat(path,num2str(i),', Corollary Filtered fNIRS','.png'));
    % end
end

