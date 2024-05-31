close all; clear all; clc; 

% This file analyzes a single data file between four conditions during a
% fixation cross experiment, NIRS toolbox has better demos but I think they
% can be overwhelming at first

% NIRStoolbox must be downloaded and added to directory path for this to
% work

%% load data
% this function loads a specific .nirs file (based on file location)
%raw =  nirs.io.loadDotNirs(fullfile(pwd,"\Pilot Data\BySingle\ASR\2022-12-18_002.nirs"));
% raw =  nirs.io.loadDotNirs(fullfile(pwd,"\2022-11-02_001.nirs"));

% This file can remove specific triggers, reducing conditions if you need to 
raw = modifyData2(raw);

%% preprocessing pipeline
j = nirs.modules.RemoveStimless( );

%Filter Data
% j = eeg.modules.BandPassFilter();
% j.lowpass= .5;
% j.highpass=0.01;

% Another way to filter data
% %must have homer2 folder in your matlab folder
% jobs = nirs.modules.Run_HOMER2;
% jobs.fcn = 'hmrBandpassFilt'; % indicate the function for applying the bandpass filter
% jobs.vars.lpf = 0.5; % define the low-pass cut-off frequency
% jobs.vars.hpf = 0.01; % define the high-pass cut-off frequency (0 for no high-pass filter)
% Hb_filtered = jobs.run(hb);

%remove certain stims (stims are conditions as NIRS toolbox views it)
j = nirs.modules.DiscardStims();
j.listOfStims = {...
    'stim_channel200' 
    'stim_channel300' 
    'stim_channel400' 
    'stim_channel600' 
    'stim_channel700' 
    'stim_channel800' 
    'stim_channel1000' 
    'stim_channel1100' 
    'stim_channel1200' 
    'stim_channel1400' 
    'stim_channel1500' 
    'stim_channel1600' 
    };

% change the name of stimuli
j = nirs.modules.RenameStims( j );
% ASR
j.listOfChanges = {
    'stim_channel100', 'Optimal'; 
    'stim_channel500', 'Sham';
    'stim_channel900', 'Low';
    'stim_channel1300', 'High'};
% VSR
% j.listOfChanges = { 
%     'stim_channel100', 'Optimal'; 
%     'stim_channel500', 'Low';
%     'stim_channel900', 'Sham';
%     'stim_channel1300', 'High'};
j = nirs.modules.Resample( j );
j.Fs = 4;  

% Many times you can have files excessive baselines before the start or at
% the end of an experiment for various reasons.  Here we can trim the data
% so that there is a max of 30 seconds of pre and post baseline.  This will
% cut off the time points earlier then 30s before the first stim event in the data and 30s AFTER the last stim event.
j = nirs.modules.TrimBaseline( j );
j.preBaseline  = 30;
j.postBaseline = 30;
% or j.postBaseline = []; would keep all the data AFTER the last stim event
% and only discard the pre-event times.

% Before doing regression we must convert to optical density and then
% hemoglobin.  The two modules must be done in order.
j = nirs.modules.OpticalDensity( j );

% Convert to hemoglobin.
j = nirs.modules.BeerLambertLaw( j );

% Finally, run the pipeline on the raw data and save to anew variable.
hb = j.run( raw );

% change stimulus duration, oftentimes the default duration is incorrect to
% what you setup in psychtoolbox
hb = nirs.design.change_stimulus_duration(hb, 'Optimal', 30);
hb = nirs.design.change_stimulus_duration(hb, 'Sham', 30);
hb = nirs.design.change_stimulus_duration(hb, 'Low', 30);
hb = nirs.design.change_stimulus_duration(hb, 'High', 30);


%% create subject specific stats

% This function will show the GUI to see the hb data, this is timeseries
% data. You should filter data for time series data
nirs.viz.nirsviewer( hb );  

% I am running this job on the hemoglobin variable, but I could have also
% done so on any nirs.core.Data variable (e.g. optical density)

% TURN OFF filtering if exploring and analyzing glm data, the toolbox will
% filter the data for you
jobs=nirs.modules.GLM();
    
jobs=nirs.modules.ExportData(jobs);
jobs.Output='SubjStats';
data=jobs.run(hb); % this runs the glm


%% Group level

% Now, let's run the statistical model to analyze what you care about
j = nirs.modules.MixedEffects( );

% We must specify the formula for the different conditions. 
% condition is a fixed effect, subject is a random effect (since data is 
% repeated measures), no intercept term
j.formula = 'beta ~ -1 + cond + (1|subject)';


% Run the group level. This could take awhile depending on your computer, 
% this is if you are doing group analysis.
GroupStats = j.run(SubjStats);
% The output of this is anouther ChannelStats class variable (just like our
% previous SubjStats).  


%% Contrasts
% This is how you analyze differences between conditions for one subject in
% hbo and hbr
% Next, specify a contrast vector
c = [0 0 1 -1];
% This means we want to contrast the 2nd (Y:group1) and 4th (Y:group1)
% conditions.  

% % or we can specify a bunch of contrasts:
% c = [eye(5);  % all 5 of the original variables
%     0 1 0 -1 0; % X - Y for group 1
%     0 0 1 0 -1; % X - Y for group 2
%     0 1 -1 0 0; % G1 - G2 for X
%     0 0 0 1 -1]; % G1 - G2 for Y

% Calculate stats with the ttest function
ContrastStats = GroupStats.ttest(c);
ContrastStats.draw('tstat', [-5 5], 'p < 0.05');

% ContrastStats is yet anouther ChannelStats variable and has all the same methods
% and fields as the other ones we have seen.