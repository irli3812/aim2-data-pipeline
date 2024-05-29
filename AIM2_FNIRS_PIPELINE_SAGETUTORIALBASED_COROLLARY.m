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
% Last edited: 4/30/2024
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Housekeeping
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
%% upload .nirs data file
nirspath = 'Z:\files\MATRIKS\lbonarrigo\SubjectData\nirs\pilot_nbacks\';
subno = input('Which subject number (of 3 digits) do you want to run? ', 's'); % for now, this asks for a specific subject number
session = input('Which session (of 1 digit) of this subject do you want to run? ', 's');
rawfile = strcat(subno,'_ses-S00',session,'_fnirs.nirs');
filepath = strcat(nirspath,rawfile);
% import nirs.io.loadDotNirs.*  <-- in an attempt to fix "Unable to resolve the name nirs.io."
data = nirs.io.loadDotNirs(filepath); %THIS COMMAND IS NOT WORKING
openvar('data');

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
% hemoglobin.  The two modules must be done in order.
j = nirs.modules.OpticalDensity( j );

% Convert to hemoglobin.
j = nirs.modules.BeerLambertLaw( j );

% Finally, run the pipeline on the raw data and save to a new variable.
hb = j.run( data );

% change stimulus duration, oftentimes the default duration is incorrect to
% what you setup in psychtoolbox
% hb = nirs.design.change_stimulus_duration(hb, 'Navigation Task Started', 60);
% hb = nirs.design.change_stimulus_duration(hb, 'Robotic Arm Task Started', 60);
% hb = nirs.design.change_stimulus_duration(hb, 'Obsevation Task Started', 60);