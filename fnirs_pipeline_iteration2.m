%% TRINITY AIM 2 - Data Cleaning for Rover or Corollary fNIRS Data - AS A FUNCTION TO BE CALLED ON IN WRAPPER SCRIPT
% AIM2_FNIRS_PIPELINE_SAGETUTORIALBASED
% Purpose: Analyze xdf fNIRS time-series streams for an entire session

%% Data extraction and setting the condition variable
subject = input('Which subject number (of 3 digits) do you want to run? ', 's');
[fnirs_cor, fnirs_rov, events_cor, events_rov, path1, path2] = extract_events(subject);
% condition
condition = input('Is this for the rover or corollary condition? Type "r" for rover and "c" for corollary.', 's');
if condition == "r"
    cond = fnirs_rov;
elseif condition == "c"
    cond = fnirs_cor;
else
    print('Invalid input. Please enter "r" or "c."');
end

%% isolate HbO and HbR columns - optode pairs (from ExtractData.m)
% -> for feature extraction?
% for rover:
% chanNames = cell(length(42:81),1);   % Initialize 40x1 cell array
% for i = 42:81   % loop that iterates over the integers from 42 to 81 inclusive
%     chanNames{i-40} = fnirs_rov.time_series.info.desc.channels.channel{1,i}.custom_name;  % cell array or structure where the i-th element contains a field 'custom_name'
% end
% phys fnirs features in SP

%% Separating Data

% function for ALL fnirs

% HbO/HbR rows
fnirsData = cond.time_series;
fnirsTimes = cond.time_stamps;

HbOraw = fnirsData(42:61,:);
HbRraw = fnirsData(62:81,:);

%% Adding time delay to fNIRS times
% Adding time delay to fNIRS times: it is recommended to delay the fNIRS data by 3-8 seconds to represent the lag between the time the brain activity occurs, and the time the data is streamed. This line of code adds 6 seconds of delay.  
fnirsTimes = fnirsTimes - 6; % DURIP ADDED 6 seconds, recommended 3-8 s

%% Task Values
% Number of trials
numTrials = 8;
% trialLength = 8*# % [s], _ mins * 60s/min -- trials that sets start and
% end times

%% Plotting raw fNIRS data (entire session)
fig_num = fig_num+1;
figure(fig_num);
hold on;
grid on;

% plot green rectangles to represent trial periods
for j = 1:numTrials
    rectangle('position', [trial(i,1) -8 ...
            trial(i,end)-trial(i,1) 16], 'FaceColor', [0.5 1 0.5 0.5]); % not too sure about -8 and 16
end

% plot HbO as red lines and HbR as blue lines
plot(fnirsTimes, HbOraw, 'r');
plot(fnirsTimes, HbRraw, 'b');

title(strcat('Entire ', cond, ' Session: Raw Hemoglobin Data'));
xlabel('Time (s)');
ylabel('Relative Concentration (mmol/L)');

xlim([trial(1) trial(end)]);
ylim([-6 6]);

hold off;
% AFOSR Pipeline README by Abby: "Data is displayed as changes in hemoglobin over time (hence the negative
% and positive values)."

%% Bandpass filtering

% Set sampling rate to nominal rate (whatever LSL did - see xdf structs)
fnirsSrate = str2double(fnirs_rov.info.nominal_srate);

% Create struct with data, time, and sampling rate
% data and time:
hbO.data = double(HbOraw');
hbR.data = double(HbRraw');
hbO.time = fnirsTimes';
hbR.time = fnirsTimes';
% sampling rate:
hbO.Fs = fnirsSrate;
hbR.Fs = fnirsSrate;

% Setting up filter using nirstoolbox
jobs = eeg.modules.BandPassFilter();
jobs.lowpass = 0.500; % Ted Huppert recommends ~0.4-0.5 Hz
jobs.highpass = 0.016; % ^ recommended

% Running the job
HbO_filtered_struct = jobs.run(hbO);
HbR_filtered_struct = jobs.run(hbR);

%% Transposing the data back to its original orientation
HbO_filtered = HbO_filtered_struct.data'; % extracts the data field from the HbO_filtered_struct structure, & ' is the transpose operator and this transposed data is assigned to HbO_filtered variable
time_filtered = HbO_filtered_struct.time'; % extracts time field from the HbO_filtered_struct structure, etc....
HbR_filtered = HbR_filtered_struct.data'; % extracts data field from the HbR_filtered_struct structure, etc....

%% Plotting FILTERED fNIRS data - entire session

fig_num = fig_num+1; % initializes fig no. 
figure(fig_num);
hold on;
grid on;

% Plot green rectangles to represent trial periods
% is "trial" a variable from another function / main script??
for i = 1:numTrials
    rectangle('position',[trial(i,1) -8 ...
        trial(i,end)-trial(i,1) 16],'FaceColor',[0.5 1 0.5 0.5]);  % -8 and 16 again
end

% Plot transposed HbO and HbR as red lines and HbR as blue lines
plot(time_filtered,HbO_filtered,'r');
plot(time_filtered,HbR_filtered,'b');

title(strcat('Entire ', cond, 'Session: Filtered Hemoglobin Data'));
xlabel('Time (s)');
ylabel('Relative Concentration (mmol/L)');

xlim([trial(1) trial(end)]);
ylim([-4 4]);

% if trialPlots == 1
%     saveas(gcf,strcat(path,'Entire Session, Filtered fNIRS','.png'));
% end

hold off;

%% Plotting by trial
% Find subtask time intervals
[nav_times, nav_dur, arm_times, arm_duration, vs_times] = SubtaskTimes(subject, condition);

for i = 1:numTrials
        % finding start and end time of trial in fNIRS indices
        sidx = find(time_filtered>trial(i,1),1);
        eidx = find(time_filtered<trial(i,end),1,'last');

    % creating vectors of trial-specific data
    HbO_epoch_data = HbO_filtered(:,sidx:eidx);
    HbR_epoch_data = HbR_filtered(:,sidx:eidx);
    epoch_time = time_filtered(sidx:eidx);

    % plotting
    fig_num = fig_num+1;
    figure(fig_num);
    hold on;
    grid on;

    plot(epoch_time, HbO_epoch_data, 'r');
    plot(epoch_time, HbR_epoch_data, 'b');

    title(strcat('Trial ',num2str(i), strcat(': Filtered Hemoglobin (', cond, ' Condition)')));
    xlabel('Time (s)');
    ylabel('Relative Concentration (mmol/L)');

    xlim([trial(i,1) trial(i,end)]);
    ylim([-4 4]);
    
    % % saving figure
    %   if trialPlots == 1
    %     saveas(gcf,strcat(path,num2str(i),', Rover Filtered fNIRS','.png'));
    % end
end

