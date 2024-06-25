%% TRINITY AIM 2 - EEG POWER ANALYSIS        
% eeg_power.m
%
% Purpose: To read in EEG data and conduct power analyses for ONE subject.
%
% Inputs: subject number as a string, not integer
%
% Requirements:
% - connection to Shuttle Server as Z: drive
% - download load_xdf MATLAB code from GitHub
% - eeglab2023.1 must be stored in ./../eeglab/
%
% Authors: Luca Bonarrigo, Iris Li
%
% Created: 3/21/2023
% Last edited: 6/12/2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Housekeeping
clc; clear; close all;
set(0,'defaultTextInterpreter', 'latex'); 

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
eeglabpath = '.\..\eeglab\'; % INPUT location of eeglab
addpath('./xdf-Matlab-master');

%% CHECKPOINT
done = false;
while(~done)
    check = input("Are you on CU Boulder VPN or WiFi? (Y/N) ",'s');
    if(check=='Y')
        done = true;
        disp('Loading in EEG data...');
    else
        done = false;
        disp('Once on CU Boulder VPN or WiFi, press any key within the MATLAB terminal to continue.')
        pause();
    end
end

%% ask for subject number
subject = input("Which subject number do you want to run? ",'s'); % for now, this asks for a specific subject number 

%% 2.1: open XDF and save event values from triggers to a new MATLAB array

[~,~,events_cor,events_rov,path_rov,path_cor] = extract_events(); %should this not be extract_events(subject)?
    
% dataset name (first iteration)
dataset = strcat('s',subject,'_raw');

% populate raw xdf file in EEGLAB
EEG = pop_loadxdf(path_rov); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',dataset,'gui','off'); % save dataset with new name

%% 2.2: pull in and reorder channel locations 
% read default 32 easy channel locations into the xdf file using dipfit
dipfitpath = strcat(eeglabpath,'eeglab2023.1\plugins\dipfit\standard_BEM\elec\standard_1005.elc');
defaultchans = 'Z:\files\MATRIKS\lbonarrigo\EEGLAB_Pipeline_Loc_Files\32_chan_locs'; % in Shuttle server
EEG=pop_chanedit(EEG, 'lookup', dipfitpath, 'load',{defaultchans,'filetype','loc'});
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

% remove 12 unused channels, keep 1-20
dataset = strcat(dataset,'_20ch');
EEG = pop_select( EEG, 'channel',{'P7','P4','Cz','Pz','P3','P8','O1','O2','T8','F8','C4','F4','Fp2','Fz','C3','F3','Fp1','T7','F7','Oz'});
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',dataset,'gui','off'); % save dataset with new name
twentychans = 'Z:\files\MATRIKS\lbonarrigo\EEGLAB_Pipeline_Loc_Files\20_chan_locs'; % in Shuttle server (new .loc, includes all 20 ch)
EEG=pop_chanedit(EEG, 'load',{twentychans,'filetype','loc'});
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

% rotate axes so channels are in correct locations and plot
EEG=pop_chanedit(EEG, 'nosedir','+Y');
figure; topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);

%% 2.3: filter out artifacts and clean out noise
% FIR filter
maxfreq = 40; % noise above this frequency filters out (Hz)
minfreq = 1; % noise below this frequency filters out (Hz)
EEG = pop_eegfiltnew(EEG, 'locutoff', minfreq, 'hicutoff', maxfreq);
dataset = strcat(dataset,'_filt');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',dataset,'gui','off'); % save dataset with new name

% Clean rawdata and ASR
EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'gui','off'); % save dataset with same name as before

% Plot cleaned data
pop_eegplot( EEG, 1, 1, 1);

%% 2.4: run Independent Component Analysis (ICA)
pop_eegplot( EEG, 1, 1, 1);
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = pop_iclabel(EEG, 'default');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

% let operator know when done to do manual rejection
%eeglab redraw;
f = msgbox("WHEN DONE WITH MANUAL ICA REJECTION, PRESS ANY KEY WITHIN THE MATLAB TERMINAL. DO NOT KEYPRESS UNTIL DONE WITH ICA!");
f = msgbox("ICA finished running. Go to Tools>Classify Components Using ICLabel>Label Components to flag and remove components manually.");

eeglab redraw;

disp('WHEN DONE WITH MANUAL ICA REJECTION, PRESS ANY KEY WITHIN THE MATLAB TERMINAL.')
pause();

% at this point, operator should go through everything and flag components
% for rejection manually. once ready, they should run the next section

%% CHECKPOINT
done = false;
while(~done)
    check = input("Are you done with ICA component rejection? (Y/N) ",'s');
    if(check=='Y')
        done = true;
        disp('Moving on with power analyses...');
    else
        done = false;
        disp('WHEN DONE WITH MANUAL ICA REJECTION, PRESS ANY KEY WITHIN THE MATLAB TERMINAL.')
        pause();
    end
end

%% 2.5: Divide dataset by trials and subtask
% find indices of nav, robot arm, vs task start and stop
nav_start = find(strcmp(events_rov.time_series,'Navigation Task Started')==1);
nav_end = find(strcmp(events_rov.time_series,'Navigation Task Ended')==1);
arm_start = find(strcmp(events_rov.time_series,'Robotic Arm Task Started')==1);
arm_end = find(strcmp(events_rov.time_series,'Robotic Arm Task Ended')==1);
vs_start = find(strcmp(events_rov.time_series,'Observation Task Started')==1);
vs_end = find(strcmp(events_rov.time_series,'Observation Task Ended')==1);
rock_select = find(strcmp(events_rov.time_series,'Rock Selected')==1);

% nav end remove duplicates
for i=2:length(nav_end)
    if(nav_end(i)-nav_end(i-1)==1)
        nav_end(i-1)=[];
    end
end

%%
% other unused but potentially relevant event triggers:
% 'Player reached 40 trials'
% 'Player did not reach proficiency'
% 'Lvl 0 reached: training video'
% 'Training video started'

% find actual timestamps associated with all of these events
% should always be 8 trials
nav_times = zeros(2,length(nav_end));
arm_times = zeros(2,length(arm_end));
vs_times = zeros(2,length(vs_end));

for i=1:length(nav_end)
    nav_times(1,i) = events_rov.time_stamps(nav_start(i));
    nav_times(2,i) = events_rov.time_stamps(nav_end(i));
    nav_dur(i) = nav_times(2,i)-nav_times(1,i);
end

for i=1:length(arm_end)
    arm_times(1,i) = events_rov.time_stamps(arm_start(i));
    arm_times(2,i) = events_rov.time_stamps(arm_end(i));
end

arm_duration = arm_times(2,:)-arm_times(1,:)-23.0756; % 23.0756 = calculated time for robot arm deploy/stowage

for i=1:length(vs_end)
    vs_times(1,i) = events_rov.time_stamps(vs_start(i));
    vs_times(2,i) = events_rov.time_stamps(vs_end(i));
end


%% 2.6: Power Analysis
% run a power analysis for EVERY subtask within each trial (ie, run 24
% analyses nominally: 3 subtasks x 8 trials)

% TO BE FIXED