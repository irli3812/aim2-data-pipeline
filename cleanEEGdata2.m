function EEGdata = cleanEEGdata2(path2eeglab,data_path,eeg_path,XDFfile,streams,...
    baselineStarts,trialStarts,trialEnds,eyeData,nTrials,experiment,makePlots)

%, EEGdata1,EEGdata2,EEGdata3

%% TO Dos
% delete makeEventTableEEG.m?
% Write code to generate EasyLoc if it doesn't exist
% write code to analyze each baseline and last 20

% EEG Data starts at time t=0;


%% Make these inputs
here_path = pwd;


%% Define these per study
eeg_channels_used = [1:8,10,12:14,16:17,19:20]; % adjust this!
eeg_channels_used = [1:8,21,23,24,27,29:32]; % adjust this!
n=1; % number of saved datasets (unsure if necessary - Kieran)
time1 = 0;
epochs = {'baseline','activity', 'final'}; % final gave an error on one trial deep in EEGlab

%% Set Up data locations
% Find .easy file
easy_search = {'*.easy','*\*.easy','*\*\*.easy'};
for i = 1:length(easy_search)
    EEGregex = fullfile(data_path,easy_search{i}); 
    EEGfilename = dir(EEGregex);
    if isempty(EEGfilename)
        if i == length(easy_search)
            error('.easy file not found. Ensure your data is data is located in the following folder or one of its immediate subfolders:\n%s\n', data_path)
        else
            continue;
        end
    else
        break;
    end
end

EEGfile = fullfile(EEGfilename.folder,EEGfilename.name);

% Find .loc file
LOCregex = fullfile(path2eeglab,'EasyLoc'); 
LOCfilename = dir(LOCregex);
LOCfile = fullfile(LOCfilename.folder,LOCfilename.name);

% write event table to text file for use in EEG Analysis
% Remove 
EVENTfile = makeEventTableEEG(streams,eeg_path,baselineStarts,trialStarts,trialEnds,experiment);
if ~isempty(eyeData)
    [FRPfile, time1] = makeEYEEventTableEEG(streams, data_path, eyeData, experiment);
end

% analyse trial by trial because events (including trial start times)
% are removed when artefacts in EEG data are removed
cd(path2eeglab)
%% Open EEGLab and import Data
% change path to eeglab location
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% load XDF
EEG = pop_loadxdf(XDFfile, 'streamtype', 'EEG', 'exclude_markerstreams', {});
EEG_time1 = str2num(EEG.etc.info.first_timestamp); % get EEG start time
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, n,'setname','first_import', ...
    'gui','off'); n=n+1; % Saves progress, increments save counter
EEG = eeg_checkset( EEG );  % checks for consistency

% load events
EEG = pop_importevent( EEG, 'event',char(EVENTfile),'fields',{'latency','type','position'},'skipline',1,'timeunit',1);
EEG = eeg_checkset( EEG );

% load Eye events  - typically takes a while :--)
% need to subtract time1 later since EEG starts at t=0 (unlike eye data)
if ~isempty(eyeData)
    % EEG = pop_importevent( EEG, 'event',char(FRPfile),'fields',{'latency','type','position'},'skipline',1,'timeunit',1);
    % EEG = eeg_checkset( EEG );
end

% load locations from EasyLoc
dipfit_path = fullfile(path2eeglab,'plugins\dipfit\standard_BEM\elec\standard_1005.elc');
EEG.chanlocs=pop_chanedit(EEG.chanlocs, 'load',{LOCfile, 'filetype', 'loc'});
EEG = eeg_checkset( EEG );

if makePlots
    time = EEG.times;
    nChan = EEG.nbchan; 
    figure;
    for i = 1:nChan
        ax{i} = subplot(4,8,i);
        plot(time,EEG.data(i,:));
        title(EEG.chanlocs(i).labels)
        linkaxes([ax{:}],'x')
    end
    sgtitle('All Raw EEG Channels')
end

% Downselect to channels of interest
EEG = pop_select( EEG, 'channel',eeg_channels_used );
EEG = eeg_checkset( EEG );

% compute average reference
% EEGLAB: "artifact cleaning using clean_rawdata usually works better on averaged reference data"
% EEG = pop_reref( EEG,[]);

if makePlots
    time = EEG.times;
    nChan = EEG.nbchan; 
    figure;
    for i = 1:nChan
        ax{i} = subplot(4,4,i);
        plot(time,EEG.data(i,:));
        title(EEG.chanlocs(i).labels)
        linkaxes([ax{:}],'x')
    end
    sgtitle('Downselected Raw EEG Channels')
end

% eeglab suggests cleaning before epoching 
% giving me an error deep down in filtfilt_fast() -- can be solved
% by closing and reopening MATLAB
% FlatlineCriterion: rm channel if it flatlines for more than X seconds
% ChannelCriterion: rm channel if it is less than X correlated w nearby
% channels [0-1]
% LineNoiseCriterion: rm channel if it has high fq noise w std dev higher
% than X

% Only do the high pass filter
EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion',...
    'off','LineNoiseCriterion','off','Highpass',[0.25 0.75] ,'BurstCriterion',...
    'off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');

% Only interpolate bad data regions
EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion',...
    'off','LineNoiseCriterion','off','Highpass','off','BurstCriterion',20,...
    'WindowCriterion','off','BurstRejection','off','Distance','Riemannian');

% Original (you should go through rejecting bad channels and bad portions
% of data before running ICA.)
% EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',80,'ChannelCriterion',0.8,...
%     'LineNoiseCriterion',4,'Highpass',[0.25 0.75],'BurstCriterion',20,...
%     'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian', ...
%     'WindowCriterionTolerances',[-Inf 7] );

%{ %Testing different cleanings
% No Flatline Criterion
% EEG1 = pop_clean_rawdata(EEG, 'FlatlineCriterion',80,'ChannelCriterion',0.8,...
%     'LineNoiseCriterion',4,'Highpass',[0.25 0.75],'BurstCriterion',20,...
%     'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian', ...
%     'WindowCriterionTolerances',[-Inf 7] );
% 
% % No Channel Criterion
% EEG2 = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0,...
%     'LineNoiseCriterion',4,'Highpass',[0.25 0.75],'BurstCriterion',20,...
%     'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian', ...
%     'WindowCriterionTolerances',[-Inf 7] );
% 
% % High Line Noise Criterion
% EEG3 = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,...
%     'LineNoiseCriterion',100,'Highpass',[0.25 0.75],'BurstCriterion',20,...
%     'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian', ...
%     'WindowCriterionTolerances',[-Inf 7] );
%}

% recompute average reference interpolating missing channels (and removing
% them again after average reference - STUDY functions handle them automatically)
% EEG = pop_reref( EEG,[],'interpchan',[]);

% EEG2 = EEG;

% run ICA reducing the dimension by 1 to account for average reference 
plugin_askinstall('picard', 'picard', 1); % install Picard plugin
EEG = pop_runica(EEG, 'icatype','icatype', 'runica', 'extended',1,'interrupt','off');

% EEG3 = EEG;

% % run ICLabel and flag artifactual components
EEG = pop_iclabel(EEG, 'default');
EEG = pop_icflag( EEG,[NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);

%% Iterate through all trials and process EEG data

startTimes = [baselineStarts' trialStarts' trialEnds'-20];
endTimes = [trialStarts' trialEnds' trialEnds'];

EEGdata = getEEGepochs(ALLEEG, EEG, EEG_time1,epochs, startTimes, endTimes, nTrials, n, makePlots);
% EEGdata1 = getEEGepochs(ALLEEG, EEG1, EEG_time1,epochs, startTimes, endTimes, nTrials, n, makePlots);
% EEGdata2 = getEEGepochs(ALLEEG, EEG2, EEG_time1,epochs, startTimes, endTimes, nTrials, n, makePlots);
% EEGdata3 = getEEGepochs(ALLEEG, EEG3, EEG_time1,epochs, startTimes, endTimes, nTrials, n, makePlots);

% return to pipeline folder
cd(here_path);
end

function EEGdata = getEEGepochs(ALLEEG, EEG, EEG_time1,epochs, startTimes, endTimes, nTrials, n, makePlots)
    EEGdata = table();
    for k = 1:length(epochs)
        EEGdata.(epochs{k}) = cell(nTrials,1);
        for i = 1:nTrials
    % for k = 1:3
    %     EEGdata.(epochs{k}) = cell(nTrials,1);
    %     for i = 1:6
    % for k = 3:length(epochs) % for testing the error in subject 2...
    %     EEGdata.(epochs{k}) = cell(nTrials,1);
    %     for i = 7:nTrials
            fprintf('Analysing EEG data from trial %d %s.\n', i, epochs{k});
        
            % downselect to time period for trial 'i'
            % EEG time starts at zero here...
            t1 = startTimes(i,k)-EEG_time1;
            t2 = endTimes(i,k)-EEG_time1;
            EEGtrial = pop_select( EEG, 'time',[t1 t2] );
            EEGtrial = eeg_checkset( EEGtrial );
            
            % Save Progress
            [ALLEEG EEGtrial CURRENTSET] = pop_newset(ALLEEG, EEGtrial, n,'setname', ...
                'downselected_data','gui','off'); n=n+1;
            
            % plot EEG to check
            if makePlots
                pop_eegplot( EEGtrial, 1, 1, 1);
            end
    
            EEGtrial = eeg_checkset( EEGtrial );
            
            
            % visualize spectral density
            if makePlots % giving me an error w subject 5... (1/18/24)
                figure; pop_spectopo(EEGtrial, 1, [0 EEGtrial.xmax], 'EEG' , 'freq', [3 6 11 20 30], 'freqrange',[1 35],'electrodes','off');
            end
        
            % Save Trial Data
            EEGdata.(epochs{k}){i} = EEGtrial;
    
            % EEGdata{i} = EEGtrial;
            clear EEGtrial
        end
    end
end
