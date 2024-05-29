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
    'stim_channel1', 'Navigation Task Started';
    'stim_channel2', 'Navigation Task Ended'
    'stim_channel4', 'Robot Arm Task Started';
    'stim_channel5', 'Robot Arm Task Ended';
    'stim_channel6', 'Observation Task Started';
    'stim_channel7', 'Rock Selected';
    'stim_channel15', 'Observation Task Ended';
    };
j = nirs.modules.Resample ( j );
j.Fs = 4;