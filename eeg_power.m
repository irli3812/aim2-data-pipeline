function [] = eeg_power(subject)%% TRINITY AIM 2 - EEG POWER ANALYSIS        
% eeg_power.m
%
% Purpose: To read in EEG data and conduct power analyses for ONE subject.
%
% Inputs: subject number as a string, not integer
%
% Authors: Luca Bonarrigo, Iris Li
%
% Created: 3/21/2023
% Last edited: 4/9/2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Housekeeping
clc; clear; close all;
set(0,'defaultTextInterpreter', 'latex'); 

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
eeglabpath = '.\..\'; % INPUT location of eeglab

%% 2.1: open XDF and save event values from triggers to a new MATLAB array
xdfpath = 'Z:\files\MATRIKS\lbonarrigo\SubjectData\xdf\'; 
% to modify this to work for multiple subjects, comment the following line:
subject = input("Which subject number do you want to run? ",'s'); % for now, this asks for a specific subject number 
filename = strcat('sub-P',subject,'_ses-S001_task-Default_run-001_eeg.xdf');
path = strcat(xdfpath,filename);

% dataset name (first iteration)
dataset = strcat('s',subject,'_raw');

% populate raw xdf file in MATLAB (for events)
xdf = load_xdf(path); % loads into MATLAB
events = xdf{1,8}; % unity events with times!

% populate raw xdf file in EEGLAB
EEG = pop_loadxdf(path); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',dataset,'gui','off'); % save dataset with new name

%% 2.2: pull in and reorder channel locations 
% read default 32 easy channel locations into the xdf file using dipfit
dipfitpath = strcat(eeglabpath,'eeglab\eeglab2023.1\plugins\dipfit\standard_BEM\elec\standard_1005.elc');
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
eeglab redraw;
f = msgbox("WHEN DONE WITH MANUAL ICA REJECTION, PRESS ANY KEY WITHIN THE MATLAB TERMINAL. DO NOT KEYPRESS UNTIL DONE WITH ICA!");
f = msgbox("ICA finished running. Go to Tools>Classify Components Using ICLabel>Label Components to flag and remove components manually.");

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


%% 2.6: Power Analysis
end