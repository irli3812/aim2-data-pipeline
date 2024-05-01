% Read NEDF file format
%
% pop_nedf() - import data from a Nedf data file.
%
% Input variables:
% file: filepath of the .nedf file you want to load.
% acc: logical varibale, should be 0 or 1, to load or not the accelerometer
% information. It's 0 by default.
% locs: logical variable, should be 0 or 1, to load or not the
% locations information. It's 0 by default and is incompatible with
% accelerometer data.
% channels_selected: channls you want to load in string format: '1,2,3']
% If the paramter is empty [] it will load all the channels. 
%
% Usage:
%   >> EEGOUT = pop_nedf(); % pop-up window to interactevely choose
%   the filepath and to load or not the accelerometer channel.
%   >> EEGOUT = pop_nedf(filepath); % no pop-up window, reads the file and assume
%   that you don't want the accelerometer data.
%   >> EEGOUT = pop_nedf(filepath,1); % no pop-up window reads the file and
%   the accelerometer data if available.
%   >> EEGOUT = pop_nedf(filepath,0,1); % no pop-up window reads the file and
%   the electrodes location data.
%   >> EEGOUT = pop_nedf(filepath,0,1,'1,2,5'); % no pop-up window reads the file and
%   the electrodes location data, and reads the data from channels 1,2 and
%   5. 
%
% Graphic interface:
%   "Nedf file" - [Edit box] Data file to import to EEGLAB.
%
%   "Import Accelerometer Channels" - [Edit box] Import accelerometer
%   channels to read, x,y,z data.
%
%   "Load Channel locations" - [Edit box] Import channels location data.
%
%   "Channel Indices" - [Edit box] Select the indices of the channels you
%   want to load, as: 1,2,5... if the box is empty all the channels will be
%   loaded. 
%
% Outputs:
%   EEG      - modified EEG dataset structure
%
% Dependencies:
% xml4mat mathworks toolbox. The folder with this functions must be located
% in the folder of the NE plugin.
%
% Authors: Jaume Banús (2015), Javier Acedo (2018)
% v.1.1 Compatible with NEDF files 1.1/1.2/1.3.
% v.1.2 Bug fix: NEDF1.3 with only EEG not loaded.
% v 1.3 Bug fix: Triggers with values higher than 255 not loaded.
% v 1.4 Added: compatibility with NEDF version 1.4

function [EEG,command] = pop_nedf(file,acc,locs,channels_selected)

EEG = [];
command = '';

if ~exist('file','var')
    %## Create popup window to load file and optionally select accelerometer channels
    
    commandload = [ '[filename, filepath] = uigetfile(''.nedf'', ''Select a text file'');' ...
        'if filename ~=0,' ...
        '   set(findobj(''parent'', gcbf, ''tag'', tagtest), ''string'', [ filepath filename ]);' ...
        'end;' ...
        'clear filename filepath tagtest;' ];
    commandsetfiletype = [ 'filename = get( findobj(''parent'', gcbf, ''tag'', ''globfile''), ''string'');' ...
        'tmpext = findstr(filename,''.'');' ...
        'tmpext = lower(filename(tmpext(end)+1:end));' ...
        'switch tmpext, ' ...
        '  case ''mat'', set(findobj(gcbf,''tag'', ''loclist''), ''value'',5);' ...
        '  case ''fdt'', set(findobj(gcbf,''tag'', ''loclist''), ''value'',3);' ...
        '  case ''txt'', set(findobj(gcbf,''tag'', ''loclist''), ''value'',2);' ...
        'end; clear tmpext filename;' ];
    
    geometry    = { [1.3 0.8 .8 0.5] 1 1 1 1 1 [1 1] 1 1 1 1 1};
    uilist = {  ...
        { 'Style', 'text', 'string', 'NEDF file', 'horizontalalignment', 'right', 'fontweight', 'bold' }, ...
        { }, { 'Style', 'edit', 'string', '', 'horizontalalignment', 'left', 'tag',  'globfile' }, ...
        { 'Style', 'pushbutton', 'string', 'Browse', 'callback', ...
        [ 'tagtest = ''globfile'';' commandload commandsetfiletype ] },{}, ...
        { 'Style', 'checkbox', 'string', 'Import Accelerometer Channels', 'horizontalalignment', 'right', 'fontweight', 'bold'},{} ...
        {'Style', 'checkbox', 'string', 'Load channel locations','horizontalalignment','right','fontweight','bold'},{} ...
        { 'Style', 'text', 'string', 'Channel Indices', 'horizontalalignment', 'right', 'fontweight', 'bold' }, ...
        { 'Style', 'edit', 'string', '', 'horizontalalignment', 'left'}, {},...
        {'Style','text','string','Introduce the channel indices which you want to visualize, if empty all channels will be loaded. Ex: 5,6,7','horizontalalignment','right'},{},...
        {'Style','text','string','Reminder: Accelerometer information cannot be visualized if you load the channels locations and vice versa','horizontalalignment','right'},{}};
    
    results = inputgui( geometry, uilist, 'pophelp(''pop_nedf'');', 'Import Nedf dataset info -- pop_nedf()');
    file = results{1};
    acc = results{2};
    locs = results{3};
    channels_selected = results{4};
end
%### Load data
display(' ');
fprintf('Reading NEDF format using NEUROELECTRICS toolbox...\n');
display(' ');

fileId = fopen(file);
A = fread(fileId); % read file as a column of bytes
foo = find(A==0); % PRESUMABLY, bytes = 0 are binary values (end of XML)
xml = A(1:foo(1));
XML = char(xml)';
XML = strrep(XML,' ','');
addpath([cd filesep 'xml4mat']);
[struct_header, var_name] = xml2mat(XML);
struct_header.RecordName = var_name;
rmpath([cd filesep 'xml4mat']);

if isfield(struct_header,'NEDFversion') % The new NEDF files include the NEDF version field
    ver = num2str(struct_header.NEDFversion);
    switch ver
        case '1.2'
            [struct_data, struct_header] = NE_LoadNedf(file);
            NChannels = str2double(struct_header.TotalNumberOfChannels);
        case {'1.3', '1.4'}
            [struct_data, struct_header] = NE_LoadNedf_1_3(file);
            NChannels = str2double(struct_header.EEGSettings.TotalNumberOfChannels);
    end
else
    ver = '1.1';
    [struct_data, struct_header] = NE_LoadNedf(file);
    NChannels = str2double(struct_header.TotalNumberOfChannels);
%     TriggerInfo = struct2cell(struct_header.TriggerInformation);
end

ver

ChannelList = cell([NChannels,1]);
Data = struct_data.EEG;

for idx = 1:NChannels
    switch ver
        case {'1.3', '1.4'}
            if isfield(struct_header.EEGSettings,'EEGMontage')
                fields = fieldnames(struct_header.EEGSettings.EEGMontage);
                ChannelList{idx} = getfield(struct_header.EEGSettings.EEGMontage,fields{idx});
            else
                ChannelList{idx} = ['Channel ' num2str(idx)];
            end
        case '1.2'
            if isfield(struct_header,'EEGMontage')
                fields = fieldnames(struct_header.EEGMontage);
                ChannelList{idx} = getfield(struct_header.EEGMontage,fields{idx});
            else
                ChannelList{idx} = ['Channel ' num2str(idx)];
            end
        case '1.1'
            if isfield(struct_header,'EEGMontage')
                fields = fieldnames(struct_header.EEGMontage);
                ChannelList{idx} = getfield(struct_header.EEGMontage,fields{idx});
            else
                ChannelList{idx} = ['Channel ' num2str(idx)];
            end
    end
end

Enobio = NChannels;

if ~exist('acc','var')
    acc = 0;
end

if ~exist('locs','var')
    locs = 0;
end

if acc && locs
    display('Is not possible load channel location information and visualize accelerometer information at the same time');
    display('Visualization of acceleremeter informaiton has been disabled');
    display(' ');
    acc = 0;
end

% Check if user wants accelerometer infomration
if acc
    Acc = struct_data.Accelerometer;
    if isempty(Acc)
        display('No accelerometer data available!!');
        display('NEDF file will be loaded only with the channels information!');
        display(' ');
    else
        ChannelList = cat(1,ChannelList,{'x';'y';'z'});
        NChannels = NChannels+3; % x,y,z info
        Data = [Data,Acc];
    end
end

if ~isempty(channels_selected)
    channels_selected = sort(str2double(channels_selected));
    NChannels = length(channels_selected);
    ChannelList = cat(1,ChannelList(channels_selected));
    Data_EEG = Data(:,channels_selected);
    if acc
        Data_EEG = cat(2,Data_EEG,Data(:,end-4:end-2)); % Trig and latency last columns
    end
    Data_EEG = Data_EEG';
else
   Data_EEG = Data(:,1:NChannels)'; 
end

EEG = eeg_emptyset;

EEG.nbchan          = NChannels;
switch ver
    case '1.1'
        EEG.srate           = str2double(struct_header.EEGSamplingRate);
    case '1.2'
        EEG.srate           = str2double(struct_header.EEGSamplingRate);
    case {'1.3', '1.4'}
		EEG.srate           = str2double(struct_header.EEGSettings.EEGSamplingRate);
		if isfield(struct_header,'STIMSettings')
			EEG.srate           = str2double(struct_header.STIMSettings.EEGSamplingRate);
		end
end
EEG.data            = Data_EEG ./ 1000; % uV data. Data of NEDF in nV;
EEG.pnts            = size(EEG.data,2); 
EEG.trials          = 1; 
EEG.setname 		= 'NEDF file';
EEG.filepath        = file;
EEG.xmin            = 0; 

switch Enobio
    case 8
        display('Warning!!');
        display('No location file available!');
        display(' ');
        locs = 0;
    case 20
        display('Warning!!');
        display('The location of the EXT channel depend on the user, so you must add it manually!');
        display('By default is located at the same position as Cz, if you want to change it you have to modify the .locs file');
        display(' ');
        
        file = 'Locations\Enobio19Chan.locs';
    case 32
        file = 'Locations\Enobio32.locs';
    otherwise
        display('Warning!');
        display('The number of channels is not correct! Check your files!');
end

if locs
    EEG.chanlocs = readlocs(file);
else
    EEG.chanlocs = struct('labels', cellstr(ChannelList));
end

EEG = eeg_checkset(EEG);

% Eventss
if max(struct_data.Triggers) > 0
    TrigData = struct_data.Triggers;
    %Trigs = (TrigData(TrigData > 0 & TrigData < 255)); % 254 is error
	Trigs = (TrigData(TrigData > 0 & TrigData ~= 255)); % 254 is error
    numEvents = unique(TrigData(TrigData > 0 & TrigData ~= 255)); % 254 is error
    %     if numel(Trigs) > 9
    %         display('Waring!, this file contains more than 9 triggers. Names of the 10th until the last trigger are not available in easy file types!');
    %         display('The triggers names will be Trig+TriggerNumber by default');
    %     end
    type = cell([numel(Trigs),1]);
    lat = cell([numel(Trigs),1]);
    lat_ms = cell([numel(Trigs),1]);
    %     lat_s = cell([numel(numEvents),1]);
    pos_list = [];
    for n = 1:numel(Trigs)
        pos_t = find(TrigData == Trigs(n));
        if numel(pos_t) > 1
            num = sum(ismember(pos_t,pos_list));
            lat{n,1} = pos_t(num+1);
            lat_ms{n,1} = (pos_t(num+1) / EEG.srate) * 10^3; % latency
            %             lat_s{n} = (pos_t(num+1) / str2double(struct_header.EEGSamplingRate)); % latency
            pos_list = [pos_list;pos_t(num+1)];
        else
            lat{n,1} = pos_t;
            lat_ms{n,1} = (pos_t / EEG.srate) * 10^3; % latency
            %             lat_s{n} = (pos_t / str2double(struct_header.EEGSamplingRate)); % latency
            pos_list = [pos_list;pos_t];
        end
        type{n,1} = num2str(Trigs(n));
    end
    EEG.event = struct('type',type,'latency',lat,'latency_ms',lat_ms);
end

command = sprintf('EEG = pop_nedf(''%s'');', file);

end