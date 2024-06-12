function [fnirs_cor,fnirs_rov,events_cor,events_rov,path1,path2] = extract_events(subject)
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
    
    %% COROLLARY
    % populate raw xdf file in MATLAB (for events)
    xdf_cor = load_xdf(path1); % loads into MATLAB

     %find index corresponding to Unity_Markers
    found = 0;
    found_fnirs = 0;
    x = 1;
    while(~found && ~found_fnirs)
        if(strcmp(xdf_cor{1,x}.info.name,'Unity_Markers'))
            found = 1;
            markers = x;
        elseif(strcmp(xdf_cor{1,x}.info.name,'Aurora'))
             found_fnirs = 1;
             aurora = x;
        else
            x=x+1;
        end
    end
    events_cor = xdf_cor{1,markers}; % unity events with times!
    fnirs_cor = xdr_cor{1,aurora}; % aurora/fnirs data 
    
    %% ROVER
    % populate raw xdf file in MATLAB (for events)
    xdf_rov = load_xdf(path2); % loads into MATLAB
    
    found = 0;
    found_fnirs = 0;
    x = 1;
    while(~found && ~found_fnirs)
        if(strcmp(xdf_cor{1,x}.info.name,'Unity_Markers'))
            found = 1;
            markers = x;
        elseif(strcmp(xdf_cor{1,x}.info.name,'Aurora'))
             found_fnirs = 1;
             aurora = x;
        else
            x=x+1;
        end
    end
    events_rov = xdf_cor{1,markers}; % unity events with times!
    fnirs_rov = xdr_cor{1,aurora}; % aurora/fnirs data 
end