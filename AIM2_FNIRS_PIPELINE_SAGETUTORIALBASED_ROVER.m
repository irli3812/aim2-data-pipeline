%% TRINITY AIM 2 - fNIRS Data Analysis for Rover Data
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
% toolboxpath = 'C:\Users\Iris Li\Desktop\fNIRS\'; % INPUT location of nirstoolbox* 
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
nirspath = 'Z:\files\MATRIKS\lbonarrigo\SubjectData\nirs\';
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
    'stim_channel1', 'Navigation Task Started'; % 150s maximum - usually less
    'stim_channel2', 'Navigation Task Ended'; % 0s
    'stim_channel4', 'Robot Arm Task Started'; %
    'stim_channel5', 'Robot Arm Task Ended';
    'stim_channel6', 'Observation Task Started';
    'stim_channel7', 'Rock Selected';
    'stim_channel15', 'Observation Task Ended';
    };
j = nirs.modules.Resample ( j );
j.Fs = 4;

% convert to optical density and then
% hemoglobin.  The two modules must be done in order.
j = nirs.modules.OpticalDensity( j );

% Convert to hemoglobin.
j = nirs.modules.BeerLambertLaw( j );

% Finally, run the pipeline on the raw data and save to a new variable.
hb = j.run( data );

% change stimulus duration, oftentimes the default duration is incorrect to
% what you setup in Unity
stimNames = unique(nirs.getStimNames(hb))
stimCount = length(stimNames)
for stimIDX = 1:stimCount
    hb = nirs.design.change_stimulus_duration(hb,stimNames(stimIDX),70); %add code in 70s spot to 

end
%% create subject specific stats

% Filter to show the GUI to see the hb data, the timeseries data.
nirs.viz.nirsviewer(hb);

% TURN OFF filtering if exploring and analyzing glm data, the toolbox will
% filter the data for you
jobs=nirs.modules.GLM();

jobs=nirs.modules.ExportData(jobs);
jobs.Output='SubjStats';
data=jobs.run(hb); % this runs the glm
%% Contrasts
% Analyze differences between conditions for one subject in hbo and hbr
% Specify contrast vector
c = [0 0 1 -1]; %contrast the 2nd (Y:group1) and 4th (Y:group1) conditions.

% Calculate stats with the ttest function
ContrastStats = GroupStats.ttest(c);
ContrastStats.draw('tstat', [-5 5], 'p < 0.05');

