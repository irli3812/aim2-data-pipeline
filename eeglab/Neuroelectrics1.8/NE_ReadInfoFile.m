function [NChannels,EEGSampRate,ChannelList,Pnts,Trigs] = NE_ReadInfoFile(Info_file,Triggers)

formatSpec = '%s';
delimiter = '\n';
fileID = fopen(Info_file);
info = textscan(fileID,formatSpec,'Delimiter',delimiter);
fclose(fileID);
info = info{1};

if strcmp(info{1},'Step Details') % Maybe in the future we will need to make something different for each version
    ver = 2; % New easy files
else
    ver = 1;
end

Mat_ver = version('-release');
Mat_ver = str2double(Mat_ver(1:end-1));

% Get number of channels
idx = strfind(info,'Total number of channels:');
[idx,~] = find(not(cellfun('isempty',idx)));
NChannels = info{idx};

if Mat_ver <= 2013
    k = strfind(NChannels,':');
    NChannels = str2double(NChannels(k+2:end));
else
    NChannels = strsplit(NChannels,':');
    NChannels = textscan(NChannels{2},'%f');
    NChannels = NChannels{1};
end

% Get EEG Sample Rate
idx = strfind(info,'EEG sampling rate:');
[idx,~] = find(not(cellfun('isempty',idx)));
EEGSampRate = info{idx};
if Mat_ver <= 2013
    k = strfind(EEGSampRate,':');
    k2 = strfind(EEGSampRate,'Samples');
    EEGSampRate = str2double(EEGSampRate(k+2:k2-1));
else
    EEGSampRate = strsplit(EEGSampRate,':');
    EEGSampRate = textscan(EEGSampRate{2},'%f');
    EEGSampRate = EEGSampRate{1};
end

% Get Channel List
ChannelList = cell([NChannels,1]);
for n=1:NChannels
    idx = strfind(info,'Position:');
    if ~isempty(find(not(cellfun('isempty',idx))))
        idx = strfind(info,'Position:');
        [idx,~] = find(not(cellfun('isempty',idx)));
        Channel = info{idx(n)};
        k = strfind(Channel,':');
        Channel = Channel(k+2:end);
    else
        idx = strfind(info,['Channel ',num2str(n),':']);
        [idx,~] = find(not(cellfun('isempty',idx)));
        Channel = info{idx};
        if Mat_ver <= 2013
            k = strfind(Channel,':');
            Channel = (Channel(k+2:end));
        else
            Channel = strsplit(Channel,': ');
            Channel = Channel{2};
        end
    end
    ChannelList{n} = Channel;
end

% Get numebr of EEG Points
idx = strfind(info,'Number of records of EEG:');
[idx,~] = find(not(cellfun('isempty',idx)));
Pnts = info{idx};
if Mat_ver <= 2013
    k = strfind(Pnts,':');
    Pnts = str2double(Pnts(k+2:end));
else
    Pnts = strsplit(Pnts,':');
    Pnts = textscan(Pnts{2},'%f');
    Pnts = Pnts{1};
end

% Get Trigger information
idx = strfind(info,'Trigger information');
[idx,~] = find(not(cellfun('isempty',idx)));
if isempty(idx) % In the new infi not implemented yet
    % No trigger information
    Trigs = [];
else
    Trigs = cell([Triggers,1]);
    for n = 1:Triggers
        trig = info{idx+1+n};
        trig = trig(2:end);
        Trigs{n} = trig;
    end
end


end