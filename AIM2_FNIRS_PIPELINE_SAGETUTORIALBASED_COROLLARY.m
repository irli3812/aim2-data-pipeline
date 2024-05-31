%% TRINITY AIM 2 - fNIRS Data Analysis for Corollary Data
% AIM2_FNIRS_PIPELINE_SAGETUTORIALBASED
%
% Purpose: Analyze a single fNIRS file
%
% Inputs: 
% - location of nirstoolbox
% - subject number
% - session number
%
% Requirements:
% - connection to Shuttle Server as Z: drive
% - *nirs-toolbox-2022.4.26 must be stored in .\..\fNIRS\
%   - this must also be the working directory
%
% Author: Iris Li
%
% Created: 3/30/2024
% Last edited: 5/30/2024
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
close all; clear all; clc;
%% Requirement 1: NIRS toolbox must be downloaded and added to directory path for this to work
toolboxpath = 'C:\Users\Iris Li\Desktop\fNIRS\'; % INPUT location of nirstoolbox* 
% if exist(toolboxpath, 'dir')
%     % Generate path string for the toolbox directory and its subfolders
%     nirstoolbox = genpath(toolboxpath);
% 
%     % Set the folder as the working directory
%     cd(nirstoolbox);
%     disp(['Working directory set to: ', nirstoolbox]);
% 
% else
%     % Display an error message if the folder doesn't exist
%     error(['NIRS toolbox path', toolboxpath, ' does not exist.']);
% end
%% Upload .nirs data file
% nirspath = 'Z:\files\MATRIKS\lbonarrigo\SubjectData\nirs\pilot_nbacks\';
% subno = input('Which subject number (of 3 digits) do you want to run? ', 's'); % for now, this asks for a specific subject number
% session = input('Which session (of 1 digit) of this subject do you want to run? ', 's');
% data = strcat(subno,'_ses-S00',session,'_fnirs');
% raw = strcat(nirspath,data);
% disp(raw);
% %import nirs.io.loadDotNirs.*  %<-- in an attempt to fix "Unable to resolve the name nirs.io."
% dataraw = nirs.io.loadDotNirs(fullfile(raw)); %THIS COMMAND IS NOT WORKING 12:34 in tutorial

% dir='C:\Users\Iris Li\Desktop\fNIRS\nirs-toolbox-2022.4.26\2023-12-11_001.nirs';
import nirs.io.loadDotNirs.*;
% raw = nirs.io.loadDirectory(dir);
data = fullfile(pwd,"\711_ses_S001_fnirs");
raw =  nirs.io.loadDotNirs(data);
%% FYI
% openvar('data');
% resample (if you want)
% 
%job=nirs.modules.Resample ;
%job.Fs = 240;
%rs=job.run(raw) ;
%% Preprocessing Pipeline
j = nirs.modules.RemoveStimless( );

% Filter Data
j = eeg.modules.BandPassFilter();
j.lowpass= .5;
j.highpass = 0.01;

%% Stimuli

% change the name of stimuli
j = nirs.modules.RenameStims( j );
% ASR
j.listOfChanges = {
    'stim_channel1', 'First Trial Started';
    'stim_channel2', 'Task 1 Ended'
    'stim_channel3', 'Task 2 Ended';
    'stim_channel4', 'Task 3 Ended';
    'stim_channel5', 'Next Trial Started';
    };
j = nirs.modules.Resample ( j );
j.Fs = 4;

% IF NEEDED?: Many times you can have files excessive baselines before the start or at
% the end of an experiment for various reasons.  Here we can trim the data
% so that there is a max of 30 seconds of pre and post baseline.  This will
% cut off the time points earlier then 30s before the first stim event in the data and 30s AFTER the last stim event.
% j = nirs.modules.TrimBaseline( j );
% j.preBaseline  = 30;
% j.postBaseline = 30;
% or j.postBaseline = []; would keep all the data AFTER the last stim event
% and only discard the pre-event times.

% Before doing regression we must convert to optical density and then
% hemoglobin.  The two modules must be done in order. (lines up w/ AFOSR
% line 17)
j = nirs.modules.OpticalDensity(j);
od = j.run(raw); % Runs and saves to a new variable.

% Convert to hemoglobin.
j = nirs.modules.BeerLambertLaw(j);
hb = j.run(raw); % Runs and saves to a new variable.

% change stimulus duration, oftentimes the default duration is incorrect to
% what you setup in psychtoolbox (?)
hb = nirs.design.change_stimulus_duration(hb, 'First Trial Started', 100); % MAX TIME - 20s max per trial, 5 total trials for task 1 (TCT)
hb = nirs.design.change_stimulus_duration(hb, 'Task 1 Ended', 20); % aka task 2 (MMR) starts
hb = nirs.design.change_stimulus_duration(hb, 'Task 2 Ended', 20); % aka task 3 (VS) starts
hb = nirs.design.change_stimulus_duration(hb, 'Task 3 Ended', 0);
hb = nirs.design.change_stimulus_duration(hb, 'Next Trial Started', 100);
%% create subject specific stats

% Filter to show the GUI to see the hb data, the timeseries data.
nirs.viz.nirsviewer( hb );

% TURN OFF filtering if exploring and analyzing glm data, the toolbox will
% filter the data for you
jobs=nirs.modules.GLM();

jobs=nirs.modules.ExportData(jobs);
jobs.Output='SubjStats';
data=jobs.run(hb); % this runs the glm

%% Group level (n/a?)

% Run the statistical model to analyze what we care about
% j = nirs.modules.MixedEffects( );
% 
% % This specifies the formula for the different conditions. 
% % condition is a fixed effect, subject is a random effect (since data is 
% % repeated measures), no intercept term
% j.formula = 'beta ~ -1 + cond + (1|subject)';
% 
% GroupStats = j.run(SubjStats);
%% Contrasts
% Analyze differences between conditions for one subject in hbo and hbr
% Specify contrast vector
c = [0 0 1 -1]; %contrast the 2nd (Y:group1) and 4th (Y:group1) conditions.

% Calculate stats with the ttest function
ContrastStats = GroupStats.ttest(c);
ContrastStats.draw('tstat', [-5 5], 'p < 0.05');