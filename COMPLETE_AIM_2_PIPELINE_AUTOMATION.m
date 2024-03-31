%% STARTING WITH LOCATING DATA FILES, IF WE WANT TO MAKE IT AUTOMATED FOR 20 SUBJECTS
% DRAFT:
    %% SPECIFY EXPERIMENT AND USER
    experiment = 'TRINITY_Aim2_N-Back_Analysis';
    %% Initialize Data Locations and Subject Numbers
    if strcmp(experiment, 'TRINITY_Aim2_N-Back_Analysis')
        subjString = {'P001', 'P002'};
        generalDataPath = 'Z:\files\MATRIKS\lbonarrigo\Nback_test\pilot_nbacks';
        nSessions = 1;
        if nSessions > 1
            sessionFolders = {'Session 1','Session 2'};
        end
        nTrials = 1;
        here_path = pwd;
        nSubs = length(subjString);
    end
    
    %% Self Running Options
    if strcmp(experiment, 'TRINITY_Aim2_N-Back_Analysis')
        runEEGlab = 1; % set to 1 to run EEGlab analysis on EEG data
    end
    if runEEGlab == 1
         path2eeglab = fullfile(path2Psychophys,'ExternalCode','eeglab2021.1'); %?
    end
