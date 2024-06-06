function [events_corollary,events_rover] = extract_events(subject)
% extract_events.m
% purpose: extract event flags from corollary (001) and rover (002) xdf files
% input: subject number as a string (or no input, in which case you will be
% asked for a subject number)
    if(~subject)
        subject = input("Which subject number do you want to run? ",'s'); % for now, this asks for a specific subject number 
    end

    xdfpath = 'Z:\files\MATRIKS\lbonarrigo\SubjectData\xdf\'; 
    filename1 = strcat('sub-P',subject,'_ses-S001_task-Default_run-001_eeg.xdf');
    filename2 = strcat('sub-P',subject,'_ses-S002_task-Default_run-001_eeg.xdf');
    path1 = strcat(xdfpath,filename1);
    path2 = strcat(xdfpath,filename2);
    
    
    % dataset name (first iteration)
    dataset = strcat('s',subject,'_raw');
    
    %% COROLLARY
    % populate raw xdf file in MATLAB (for events)
    xdf1 = load_xdf(path1); % loads into MATLAB

     %find index corresponding to Unity_Markers
    found = 0;
    x = 1;
    while(~found)
        if(strcmp(xdf1{1,x}.info.name,'Unity_Markers'))
            found = 1;
            markers = x;
        else
            x=x+1;
        end
    end
    events_corollary = xdf1{1,markers}; % unity events with times!
    
    %% ROVER
    % populate raw xdf file in MATLAB (for events)
    xdf2 = load_xdf(path2); % loads into MATLAB
    
    found = 0;
    x = 1;
    % find the index corresponding to Unity_Markers
    while(~found)
        if(strcmp(xdf2{1,x}.info.name,'Unity_Markers'))
            found = 1;
            markers = x;
        else
            x=x+1;
        end
    end
    events_rover = xdf2{1,markers}; % unity events with times!
end