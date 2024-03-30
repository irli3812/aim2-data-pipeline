clear;
clc;
%% NIRS toolbox must be downloaded and added to directory path for this to work
toolboxpath = 'C:\Users\Iris Li\Desktop\fNIRS_nback_analysis\nirs-toolbox-2022.4.26';
if exist(toolboxpath, 'dir')
    % Generate path string for the toolbox directory and its subfolders
    toolboxPaths = genpath(toolboxpath);
    
    % Add the generated paths to the MATLAB path
    addpath(toolboxPaths);
    
    disp(['NIRS toolbox ', toolboxpath, ' and its subfolders added to the MATLAB path.']);
else
    % Display an error message if the folder doesn't exist
    error(['NIRS toolbox ', toolboxpath, ' does not exist.']);
end
%% Working Directory
% Specify the folder path you want to set as the working directory
folderPath = 'C:\Users\Iris Li\Desktop\fNIRS_nback_analysis';

% Check if the folder exists
if exist(folderPath, 'dir')
    % Set the folder as the working directory
    cd(folderPath);
    disp(['Working directory set to: ', folderPath]);
else
    % Display an error message if the folder doesn't exist
    error(['Folder ', folderPath, ' does not exist.']);
end
%% load data
raw = nirs.io.loadDotNirs(fullfile(pwd, "\2023-12-11_001.nirs"));
%openvar('raw');

%% Preprocessing Pipeline
j = nirs.modules.RemoveStimless( );

% Filter Data
j = eeg.modules.BandPassFilter();
j.lowpass= .5;
j.highpass=0.01;

% Before doing regression we must convert to optical density and then
% hemoglobin.  The two modules must be done in order.
j = nirs.modules.OpticalDensity( j );

% Convert to hemoglobin.
j = nirs.modules.BeerLambertLaw( j );

% Finally, run the pipeline on the raw data and save to anew variable.
hb = j.run( raw );
