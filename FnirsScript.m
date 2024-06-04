%% AUTHORS:     Sarah Leary
% LAST EDITED: 2/2/23
% PROJECT:     AFOSR TRUST
% PURPOSE:     Analyzing fNIRS data.
% NOTES:       Rows 2:21 are raw voltage data when gamma = 760
%              Rows 22:41 are raw voltage data when gamma = 850
%              Rows 42:61 are HbO, Rows 62:81 are HbR

disp('Analyzing fNIRS data...')

%% Adding nirstoolbox to path
addpath(nirstoolbox_path)

%% Separating data
HbO_raw = fnirsData(42:61,:);
HbR_raw = fnirsData(62:81,:);

%% Adding time delay to fNIRS times
fnirsTimes = fnirsTimes - 6; % DURIP ADDED 6 seconds, recommended 3-8 s

%% Plotting raw fNIRS data (entire session)
fig_num = fig_num+1;
figure(fig_num);
hold on;
grid on;

for i = 1:numTrials
    rectangle('position',[trial(i,1) -6 ...
        trial(i,end)-trial(i,1) 12],'FaceColor',[0.5 1 0.5 0.5]);
end

plot(fnirsTimes,HbO_raw,'r');
plot(fnirsTimes,HbR_raw,'b');

title('Entire Session: Raw Hemoglobin Data');
xlabel('Time, s');
ylabel('Relative Concentration, mmol/L');

xlim([trial(1) trial(end)]);
ylim([-6 6]);

hold off;

%% Bandpass filtering
% Ted Huppert in lectures recommends cutoff frequency at 0.016 (high pass)
% and ~0.4-0.5 Hz (low pass)
% DURIP uses a bandpass 0.01 - 0.5 Hz with NIRS toolbox
% This gets rid of heart rate data as well (~1 Hz)

% Using NIRS toolbox to filter the data
% Creating a struct with data, time, and sampling frequency
hbO.data = double(HbO_raw');
hbR.data = double(HbR_raw');
hbO.time = fnirsTimes';
hbR.time = fnirsTimes';
hbO.Fs = fnirsSrate;
hbR.Fs = fnirsSrate;

% setting up filter using nirs toolbox
jobs = eeg.modules.BandPassFilter();
jobs.lowpass = 0.500;
jobs.highpass = 0.016;

% running the job
HbO_filtered_struct = jobs.run(hbO);
HbR_filtered_struct = jobs.run(hbR);

% transposing the data
HbO_filtered = HbO_filtered_struct.data';
time_filtered = HbO_filtered_struct.time';
HbR_filtered = HbR_filtered_struct.data';

%% Plotting filtered fNIRS data (entire session)
fig_num = fig_num+1;
figure(fig_num);
hold on;
grid on;

for i = 1:numTrials
    rectangle('position',[trial(i,1) -6 ...
        trial(i,end)-trial(i,1) 12],'FaceColor',[0.5 1 0.5 0.5]);
end

plot(time_filtered,HbO_filtered,'r');
plot(time_filtered,HbR_filtered,'b');

title('Entire Session: Filtered Hemoglobin Data');
xlabel('Time, s');
ylabel('Relative Concentration, mmol/L');

xlim([trial(1) trial(end)]);
ylim([-6 6]);

if trialPlots == 1
    saveas(gcf,strcat(path,'Entire Session, Filtered fNIRS','.png'));
end

hold off;

%% Plotting by trial
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

    plot(epoch_time,HbO_epoch_data,'r');
    plot(epoch_time,HbR_epoch_data,'b');

    title(strcat('Trial',num2str(i),': Filtered Hemoglobin'));
    xlabel('Time, s');
    ylabel('Relative Concentration, mmol/L');

    xlim([trial(i,1) trial(i,end)]);
    ylim([-6 6]);

    % saving figure
    if trialPlots == 1
        saveas(gcf,strcat(path,num2str(i),', Filtered fNIRS','.png'));
    end

end

%% Version 2: Active HbO and HbR
[FNIRS_FEATURES.version2] = FNIRS_ANALYSIS(epochStart,epochEnd,...
    HbO_filtered,HbR_filtered,time_filtered,chanNames,2,...
    trial,numTrials,numSlider);

%% Version 4: Active - Baseline
[FNIRS_FEATURES.version4] = FNIRS_ANALYSIS(epochStart,epochEnd,...
    HbO_filtered,HbR_filtered,time_filtered,chanNames,4,...
    trial,numTrials,numSlider);

%% Version 11: Active/Baseline
[FNIRS_FEATURES.version11] = FNIRS_ANALYSIS(epochStart,epochEnd,...
    HbO_filtered,HbR_filtered,time_filtered,chanNames,11,...
    trial,numTrials,numSlider);

%% Saving fNIRS Features
save(strcat('./Data/FeaturesS',num2str(SID),'/FNIRS_Features'),"FNIRS_FEATURES");

%% Checkpoint
disp('fNIRS data cleaned and features extracted.')