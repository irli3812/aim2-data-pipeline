function [ struct_data, struct_header ] = NE_LoadNedf(path)
%----------------------------------------------------------
% EEGStarlab Toolbox
% (C) Neuroelectrics Barcelona S.L.
% anton.albajes-eizagirre@neuroelectrics.com
%----------------------------------------------------------
% Loads a NEDF file with EEG and/or Stim data into two structs with signals and header
%
% This function loads a Neuroelectric's NEDF file and returns two structs, one with 
% the data signals, and the other with the NEDF file. Works with both Enobio (EEG)
% and Starstim (Stim) devices files. 
%
%----------------------------------------------------------
%Inputs
% nedfPath: string containing the absolute path to the nedf file to load.
%----------------------------------------------------------
%Outputs
% struct_data: struct with data from the NEDF eeg streams. Struct contains:
%   - EEG: SDC with EEG stream
%   - Stim: SDC with Stim stream
%   - External: SDC with external stream
%   - Accelerometer: SDC with accelerometer stream
% struct_header: struct with the content of the xml header
%----------------------------------------------------------
% Dependency: XML4MAT http://www.mathworks.com/matlabcentral/fileexchange/6268-xml4mat-v2-0
%----------------------------------------------------------
% Version   Date        Author  Changes 
% v1        2014/10/10  AAE     Initial version 
% v1.1      2015/01/25  AAE     Fixed sample scale bug and performance
%                               optimisation
% v1.2      2015/01/30  AAE     Changed function/file name to NE_LoadNedf
% v1.3      2015/03/05  AAE     Fixed bugs flagged in validation of v1.2
%----------------------------------------------------------
% EX.
%
% [data,header] = NE_LoadNedf('/home/neuroelectrics/recording.nedf')
%----

% Here goes the code of the function
    fileId = fopen(path);
    A = fread(fileId);  % read file as a column of bytes
    fclose(fileId);     % close the file
    foo = find(A==0); % PRESUMABLY, bytes = 0 are binary values (end of XML)
    xml = A(1:foo(1));
    addpath('xml4mat');
    XML = char(xml)';
    XML = strrep(XML,' ','');
%%%%

    [struct_header, var_name] = xml2mat(XML);
    struct_header.RecordName = var_name;
    if isfield(struct_header,'NEDFversion')
        if strcmp(struct_header.NEDFversion,'1.2')
            nChanEeg = str2num(struct_header.NumberOfEEGChannels);
            nChan = str2num(struct_header.TotalNumberOfChannels);
            nRecordsEeg = str2num(struct_header.NumberOfRecordsOfEEG);
            deviceClass = struct_header.DeviceClass;    
        end
    else     
        nChanEeg = str2num(struct_header.NumberOfEEGChannels);
        nChan = str2num(struct_header.TotalNumberOfChannels);
        nRecordsEeg = str2num(struct_header.NumberOfRecordsOfEEG);
        deviceClass = struct_header.DeviceClass; 
    end
%%%%

    % check the version of NEDF to calculate the header padding.
    binStart = 5120;    % binary data will always start at byte 5120
    if isfield(struct_header,'NEDFversion')
        if strcmp(struct_header.NEDFversion,'1.2')
            binStart = 10240   % binary data will always start at byte 10240
        end
    end
    binData = A(binStart+1:end);
    binHeader = 1;
    
    % check if there's an Accelerometer data stream in the NEDF file
     if isfield(struct_header,'NumberOfChannelsOfAccelerometer')
          nChanAcc = str2num(struct_header.NumberOfChannelsOfAccelerometer);
    else
        nChanAcc=0;
    end
    
    nChanExt = 0;
    % check if there's an external channel data stream in the NEDF file
    if(struct_header.AdditionalChannelStatus~='OFF')
        nChanExt = 1;
    end
    counterEeg = 1;
    counterStim = 1;
    counterExt = 1;
    counterTrig = 1;
    counterAcc = 5;
    lastSampleAcc=zeros(nChanAcc,1);
    nSamplesStim = 0;
    
    % if the device is a StarStim, with Stim data stream, we'll get two samples
    % of stim for each one of EEG
    if strcmp(deviceClass,'StarStim')
        nSamplesStim = 2;
    end
    
    
    % check if the header includes a stim data stream. If so, get how many
    % records the stim data stream has
    % if stim stream is not included in the header, set number of samples of
    % stim to get by iteration to 0.
    stimMode = 0;
    if isfield(struct_header,'NumberOfRecordsOfStimulation')
        nRecordsStim = str2num(struct_header.NumberOfRecordsOfStimulation);
        stimMode = 1;
    else
        nRecordsStim = 2; % we set number a fake number for stim records, so it won't interfere with the EEG loading with an early stop. 
        nSamplesStim = 0;
    end
    struct_data.Triggers = [];
    % flag that will be used to check when one of the streams (EEG or Stim) has
    % come to an end
    moreData = 1;

    struct_data.Accelerometer = zeros(nRecordsEeg-1,nChanAcc);
    % reading one record less than reported due to NEDF codification (sometimes
    % there are missmatches
    struct_data.EEG = zeros(nRecordsEeg-1,nChan);
    struct_data.Stim = zeros((nRecordsEeg-1)*nSamplesStim,nChan);
    struct_data.Triggers = zeros(nRecordsEeg-1,1);
    struct_data.External = zeros(nRecordsEeg-1,nChanExt);
    debugIndex = 1;
    stimModeEEGStarted = 0; % if we are in stimulation file mode and EEG data already started
    stimModeStimStarted = 0; % if we are in stimulation file mode and Stim data already started
    
    while(moreData)
        debugIndex = debugIndex+1;
        % there will be one sample in the accelerometer stream per 5 samples in
        % the EEG stream
        if counterAcc == 5
            counterAcc = 1;
            for a= 1:nChanAcc
                if isfield(struct_header,'NEDFversion')
                    %binHeader
                    [lastSampleAcc(a), binHeader] = getSampleAcc(binData,binHeader,struct_header.NEDFversion);
                    %'accel¿?'
                else 
                    [lastSampleAcc(a), binHeader] = getSampleAcc(binData,binHeader,'0');
                end
                %lastSampleAcc(a)    
            end
        else
            counterAcc = counterAcc + 1;
        end

        % read EEG sample
        for e=1:nChan
            [sample,binHeader] = getSampleEEG(binData,binHeader,stimMode);
%            e
%            sample
            struct_data.EEG(counterEeg,e) = sample;
%            counterEeg
            %if sample~= -1
                stimModeEEGStarted = 1;
            %end
        end
        if stimModeEEGStarted==1
            counterEeg = counterEeg+1;
        end

        % if we already read all the available EEG records, stop the reading
        % loop
        if counterEeg >= nRecordsEeg
            moreData = 0;
        end

        % there will be nSamplesStim in the stim stream per one sample in the
        % EEG stream (currently 2 stim / 1 eeg)
        for ns = 1:nSamplesStim
            for s=1:nChan
                [sample,binHeader] = getSampleStim(binData,binHeader);
                struct_data.Stim(counterStim,s) = sample;
                if sample~=1
                    stimModeStimStarted = 1;
                end
            end
        end
        if stimModeStimStarted
            counterStim = counterStim+1;
        end

        % if we already read all the available Stim records, stop the
        % reading loop
        if counterStim >= nRecordsStim
            moreData = 0;
        end
        
        % if there is data in the external channel stream, read nChan samples
        for x=1:nChanExt
            [sample,binHeader] = getSampleEEG(binData,binHeader);
            struct_data.External(counterExt,x) = sample;
        end
        counterExt = counterExt +1;
        if or(stimMode==0,stimModeEEGStarted==1)
            for a=1:nChanAcc
                struct_data.Accelerometer(counterEeg-1,a) = lastSampleAcc(a);
            end

            %%%
            if length(binData) > (binHeader)
                if isfield(struct_header,'NEDFversion')
                    if strcmp(struct_header.NEDFversion,'1.2')
                        % load 32-byte integer from the trigger stream
                        struct_data.Triggers(counterTrig,1) = uint32(binData(binHeader));
                        binHeader = (binHeader + 3);
                    end
                else
                    % load one-byte integer from the trigger stream
                    struct_data.Triggers(counterTrig,1) = uint8(binData(binHeader));
                end
            else
                struct_data.Triggers(counterTrig,1) = 0;
            end
            counterTrig = counterTrig +1;
                %%%
        end
        binHeader = binHeader+1;
    end

    % cleanup empty fields (accelerometer when not present, stim when not present, external when not present, etc.)
    if nSamplesStim==0
        struct_data.Stim = [];
    end
    if nChanAcc==0
        struct_data.Accelerometer = [];
    end
    if nChanExt==0
        struct_data.External = [];
    end
    % correcting reported data lengths in header
    if size(struct_data.EEG,1)>0
        struct_header.NumberOfRecordsOfEEG = size(struct_data.EEG,1);
    end
    if size(struct_data.Stim,1)>0
        struct_header.NumberOfRecordsOfStimulation = size(struct_data.Stim,1);
    end
    
    struct_header
    struct_header.StartDateEEG
end

% function that will read one sample of one channel of the accelerometer
% stream..
function [sample, header] = getSampleAcc(data, header, nedf_version)
%    header
%    data(header)
    if length(data) > (header+2)
        byte1 = int32(uint8(data(header)));         header = header+1;
        byte2 = int32(uint8(data(header)));         header = header+1;
        if not(strcmp(nedf_version, '1.2'))
            byte3 = int32(uint8(data(header)));     header = header+1;
            sample = byte1*65536 + byte2*256 + byte3;
            range = 16777216;       % 0x1000000
        else 
            sample = byte1*256+byte2;
            range = 65536;          % 0x10000
        end
        
        if(byte1>=128)
            sample = (sample - range);
        end
    else
        sample = 0;
    end
end

% function that will read one sample of one channel of the eeg stream
% data will be in three bytes 2-complemented and then scaled
function [sample, header] = getSampleEEG(data, header, flagstim )
%    header
%    data(header)

    if nargin <3
        flagstim = 0;
    end
    if length(data) > (header+3)
        byte1 = int32(uint8(data(header)));         header = header+1;
        byte2 = int32(uint8(data(header)));         header = header+1;
        byte3 = int32(uint8(data(header)));         header = header+1;

        sample = 65536*byte1 + 256*byte2 + byte3;
        if(byte1>=128)
            sample = (sample - 16777216); 
        end
        if(or(flagstim==0,sample~=-1))
            sample = sample*(2.4*1000000000.0/6.0/8388607.0);
        end
    else
        sample = 0;
    end
end

% function that will read one sample of one channel of the stimulation stream
% data will be in three bytes 2-complemented. According to sampled NEDF
% files, data will not be scaled.
function [sample, header] = getSampleStim(data, header)
    byte1 = double(uint8(data(header)));            header=header+1;
    byte2 = double(uint8(data(header)));            header = header+1;
    byte3 = double(uint8(data(header)));            header = header+1;

    sample = byte1*65536+byte2*256+byte3;
    if(byte1>=128)
        sample = (sample - 16777216); 
    end
   % sample = sample;
end
