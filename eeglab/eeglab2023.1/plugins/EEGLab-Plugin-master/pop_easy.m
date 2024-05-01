% Read EASY file format
%
% pop_easy() - import data from an Easy data file.
%
% Input variables:
% file: filepath of the .easy file you want to load.
% acc: logical varibale, should be 0 or 1, to load or not the accelerometer
% information. It's 0 by default.
% locs: logical variable, should be 0 or 1, to load or not the
% locations information. It's 0 by default and is incompatible with
% accelerometer data.
% channels_selected: channls you want to load in string format: '1,2,3'
% If the paramter is empty [] it will load all the channels. 
%
% Usage:
%   >> EEGOUT = pop_easy(); % pop-up window to interactevely choose
%   the filepath and to load or not the accelerometer channel.
%   >> EEGOUT = pop_easy(filepath); % no pop-up window, reads the file and assume
%   that you don't want the accelerometer data.
%   >> EEGOUT = pop_easy(filepath,1); % no pop-up window reads the file and
%   the accelerometer data if available.
%   >> EEGOUT = pop_easy(filepath,0,1); % no pop-up window reads the file and
%   the electrodes location data.
%   >> EEGOUT = pop_easy(filepath,0,1,'1,2,5'); % no pop-up window reads the file and
%   the electrodes location data, and reads the data from channels 1,2 and 5. 
%
% Graphic interface:
%   "Easy file" - [Edit box] Data file to import to EEGLAB.
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
% .Info file in the same folder and with the same name as the .easy file.
% If not provided some default values will be used.
%
% Author: Jaume Banús (2015) | Javier Acedo (2018) | Roger Puig (2019) | Diego Lozano-Soldevilla (2021)
% v 1.1: Compatible with the old and new easy files.
% v 1.2: Added conversion from nV to uV and version number.
% v 1.3: Bugfix: Markers greater than 255 not read in easy files.
% v 1.4: Bugfix: if only 255-packet-lost markers present data is not loaded.
% v 1.5: Bugfix: file not loaded when 255-lost-packet marker and others are present.
% v 1.6: Bugfix: check whether EEG channel order matches .locs channel order and few improvements

function [EEG, command] = pop_easy(file,acc,locs,channels_selected)

EEG = [];
command = '';

%## Create popup window to load file and optionally select accelerometer channels
if ~exist('file','var')
    commandload = [ '[filename, filepath] = uigetfile(''.easy'', ''Select a text file'');' ...
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
    
    geometry    = { [1.3 0.8 0.8 0.5] 1 1 1 1 1 [1 1] 1 1 1 1 1};
    uilist = {  ...
        { 'Style', 'text', 'string', 'Easy file', 'horizontalalignment', 'right', 'fontweight', 'bold' }, ...
        { }, { 'Style', 'edit', 'string', '', 'horizontalalignment', 'left', 'tag',  'globfile' }, ...
        { 'Style', 'pushbutton', 'string', 'Browse', 'callback', ...
        [ 'tagtest = ''globfile'';' commandload commandsetfiletype ] },{}, ...
        { 'Style', 'checkbox', 'string', 'Import Accelerometer Channels', 'horizontalalignment', 'right', 'fontweight', 'bold'},{} ...
        { 'Style', 'checkbox', 'string', 'Load channel locations','horizontalalignment','right','fontweight','bold'},{} ...
        { 'Style', 'text', 'string', 'Channel Indices', 'horizontalalignment', 'right', 'fontweight', 'bold' }, ...
        { 'Style', 'edit', 'string', '', 'horizontalalignment', 'left'}, {},...
        { 'Style','text','string','Introduce the channel indices which you want to visualize, if empty all channels will be loaded. Ex: 5,6,7','horizontalalignment','right'},{},...
        { 'Style','text','string','Reminder: Accelerometer information cannot be visualized if you load the channels locations and vice versa','horizontalalignment','right'},{}};
    
    results = inputgui( geometry, uilist, 'pophelp(''pop_easy'');', 'Import Easy dataset info -- pop_easy()');
    
    %### Load data
    file = results{1}; % filepath
    acc = results{2};
    locs = results{3};
    channels_selected = results{4};
end
display(' ');
fprintf('Reading EASY format using NEUROELECTRICS toolbox...\n');
display(' ');

Data = load(file);

Mat_ver = version('-release');
Mat_ver = str2double(Mat_ver(1:end-1));

if Mat_ver <= 2013
    k = strfind(file,'.easy');
    name = file(1:k-1);
else
    name = strsplit(file,'.easy');
    name = name{1};
end

Info_file = [name,'.info'];% get .info file filepath

Triggers = unique(Data(:,end-1));

% if Triggers > 9
%     Triggers = 9;
%     display('Waring!, this file contains more than 9 triggers. Names of the 10th until the last trigger are not available in easy file types!');
%     display('The triggers names will be Trig+TriggerNumber by default');
% end
% default_trigger = 'Trig';

if exist([Info_file],'file') % check if .info file with the same name exist or no
    [NtotalChannels,EEGSampRate,ChannelList,Pnts,Trigs,device_class,NChannelsRec] = NE_ReadInfoFile(Info_file,9);
    if Pnts ~= size(Data,1)
        Pnts = size(Data,1);
    end
else
  % here we need to throw and error since the .info file contains details
  % that cannot be ingnored: device_class or the number of recorded,
  % channels plus the Channel names
    error('.info file cannot be found');
end
% NChannels may be updated during the channel selection and NtotalChannels
% will be used to classify the device_class
NChannels = NtotalChannels;

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
    if NChannels + 3 > size(Data,2) -2
        display('No accelerometer data available!!');
        display('file will be loaded only with the channels information!');
        display(' ');
    else
        ChannelList = cat(1,ChannelList,{'x';'y';'z'});
        NChannels = NChannels+3; % x,y,z info
    end
end

% deal with the possibility that the user did not used all EEG channels
% for the recording, just few of them. I'm not aware of any stardard
% EEG sensor that begins with Ch (see https://github.com/fieldtrip/fieldtrip/blob/master/template/electrode/standard_1005.elc)
% '^Ch\w*\d\> matches a word starting with Ch at the beginning of the text and do end with a numeric digit.
emptychan=[];
for c=1:size(ChannelList,1)
  if ~isempty(regexp(ChannelList{c,1},'^Ch\w*\d\>','match'))
    emptychan(c)=1;
  else
    emptychan(c)=0;
  end
end

if size(find(emptychan==0),2)~=NChannelsRec
  error('wrong identification of empty channels')
end

if ~isempty(channels_selected)
    channels_selected_num = sort(str2num(channels_selected));
    NChannels = length(channels_selected_num);
    ChannelList = cat(1,ChannelList(channels_selected_num));
    
    idxe = find(emptychan==1);
    emp = find(ismember(channels_selected_num,idxe)==1);
    ful = find(ismember(channels_selected_num,idxe)==0);
    if ~isempty(emp)
      ad = repmat(',%.f',1,size(emp,2)-1);
      fprintf('\n *************************************************\n');
      fprintf([' Ignoring channel(s) : %.f' ad '\n'],channels_selected_num(emp))
      fprintf(' because they are empty\n')
      fprintf(' *************************************************\n\n');
    end
    channels_selected_num = channels_selected_num(ful);
    ChannelList = ChannelList(ful);
    Data_EEG = Data(:,channels_selected_num);
    
    ad = repmat(',%s',1,NChannels-1);
    fprintf('\n *************************************************\n');
    fprintf([' Selecting channel order: %s \n'],num2str(channels_selected_num))
    fprintf([' resulting: %s' ad],ChannelList{:})
    fprintf('\n *************************************************\n\n');
    
    NChannels = size(ChannelList,1);
    
    if acc
        Data_EEG = cat(2,Data_EEG,Data(:,end-4:end-2)); % Trig and latency last columns
    end
    Data_EEG = Data_EEG';

else
    channels_selected_num = find(emptychan==0);
    NChannels = length(channels_selected_num);
    ChannelList = cat(1,ChannelList(channels_selected_num));
    
    emp = find(emptychan==1);
    if ~isempty(emp)
      ad = repmat(',%.f',1,size(emp,2)-1);
      fprintf('\n *************************************************\n');
      fprintf([' Ignoring channel(s) : %.f' ad '\n'],emp)
      fprintf(' because they are empty\n')
      fprintf(' *************************************************\n\n');
    end
    ChannelList = ChannelList(channels_selected_num);
    Data_EEG = Data(:,channels_selected_num);
    
    ad = repmat(',%s',1,NChannels-1);
    fprintf('\n *************************************************\n');
    fprintf([' Selecting channel order: %s \n'],num2str(channels_selected_num))
    fprintf([' resulting: %s' ad],ChannelList{:})
    fprintf('\n *************************************************\n\n');
    
    NChannels = size(ChannelList,1);
    
    Data_EEG = Data(:,1:NChannels)'; 
end

%### Fill EEG dataset
EEG = eeg_emptyset;

EEG.data = Data_EEG ./ 1000; % uV data. Data of easy in nV
EEG.nbchan = NChannels;
EEG.pnts = Pnts;
EEG.trials = 1;
EEG.srate  = EEGSampRate;
EEG.setname = 'Easy File';
EEG.filepath = file;

% device_class can be: STARSTIM (EEG only mode), STARSTIM, ENOBIO
switch device_class  
    case 'ENOBIO'
      if NtotalChannels==8
        display('Warning!!');
        display('No location file available!');
        display(' ');
        locs = 0;
      elseif NtotalChannels==20
        display('Warning!!');
        display('The location of the EXT channel depend on the user, so you must add it manually!');
        display('By default is located at the same position as Cz, if you want to change it you have to modify the .locs file');
        % using fullfile avoid filesep issues between windows and linux users
        locsfile = fullfile('Locations','Enobio19Chan.locs');
        display(' ');
      elseif NtotalChannels==32
        locsfile = fullfile('Locations','Enobio32.locs');
      else
        display('Warning!');
        display('The number of channels is not correct! Check your files!');
      end
      
      case {'STARSTIM' , 'STARSTIM (EEG only mode)'}
      if NtotalChannels==20
        display('Warning!!');
        display('The location of the EXT channel depend on the user, so you must add it manually!');
        display('By default is located at the same position as Cz, if you want to change it you have to modify the .locs file');
        % using fullfile avoid filesep issues between windows and linux users
        locsfile = fullfile('Locations','Starstim20.locs');
        display(' ');
      elseif NtotalChannels==32
        locsfile = fullfile('Locations','Starstim32.locs');
      else
        display('Warning!');
        display('The number of channels is not correct! Check your files!');
      end
  otherwise
    error('not recognized device class')
end

if locs
  fprintf('\n *************************************************\n');
  fprintf(' Loading locs file: %s',locsfile)
  fprintf('\n *************************************************\n\n');
  
  [eloc, chlabels] = readlocs(locsfile);
  % sort the eloc channels back into the default EEG channel order
  [tmp,I] = ismember_bc(lower(ChannelList),lower(chlabels'));
  if ~(isempty(find(I==0)))
    error(['EEG.chanlocs order and ' device_class ' channel identity differ. Please check .info channel labels and the .locs file labels']);
  end
  
  eloc = eloc(I);
  if ~isequal({eloc.labels}',ChannelList)
    error(['EEG.chanlocs order and ' device_class ' channel order are different']);
  end
    EEG.chanlocs = eloc;
else
    EEG.chanlocs = struct('labels', cellstr(ChannelList));
end

EEG = eeg_checkset(EEG);

% Events --------
TrigData = Data(:,end-1);
numEvents = TrigData(TrigData > 0 & TrigData ~= 255);
if numel(numEvents) > 0
    type = cell([numel(numEvents),1]);
    lat = cell([numel(numEvents),1]);
    lat_ms = cell([numel(numEvents),1]);
    %     lat_s = cell([numel(numEvents),1]);
    pos_list = [];
    for n = 1:numel(numEvents)
        pos_t = find(TrigData == numEvents(n));
        if numel(pos_t) > 1
            num = sum(ismember(pos_t,pos_list));
            lat{n,1} = pos_t(num+1);
            lat_ms{n,1} = Data(pos_t(num+1),end) - Data(1,end); % latency ms
            %             lat_s{n} = (Data(pos_t(num+1),end) - Data(1,end))/1000; % latency s
            pos_list = [pos_list;pos_t(num+1)];
        else
            lat{n,1} = pos_t;
            lat_ms{n,1} = Data(pos_t,end) - Data(1,end); % latency ms
            %             lat_s{n} = (Data(pos_t,end) - Data(1,end))/1000; % latency s
            pos_list = [pos_list;pos_t];
        end
        type{n,1} = num2str(numEvents(n));
    end
    EEG.event = struct('type',type,'latency',lat,'latency_ms',lat_ms);
end

EEG = eeg_checkset(EEG);

if isempty(channels_selected)
  print_chansel = '''';
else
  print_chansel = channels_selected;
end
command = sprintf('EEG = pop_easy(''%s'',%.f,%.f,''%s'');',file,acc,locs,print_chansel);

end