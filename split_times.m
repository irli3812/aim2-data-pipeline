function [nav_times,nav_dur,arm_times,arm_dur,vs_times,vs_dur] = split_times(events,type)

    % check whether corollary or rover
    if type=='rov'
        events_rov = events;
    
        % find indices of nav, robot arm, vs task start and stop
        nav_start = find(strcmp(events_rov.time_series,'Navigation Task Started')==1);
        nav_end = find(strcmp(events_rov.time_series,'Navigation Task Ended')==1);
        arm_start = find(strcmp(events_rov.time_series,'Robotic Arm Task Started')==1);
        arm_end = find(strcmp(events_rov.time_series,'Robotic Arm Task Ended')==1);
        vs_start = find(strcmp(events_rov.time_series,'Observation Task Started')==1);
        vs_end = find(strcmp(events_rov.time_series,'Observation Task Ended')==1);
        rock_select = find(strcmp(events_rov.time_series,'Rock Selected')==1);
        
        % nav end remove duplicates
        idx = [];
        for i=2:length(nav_end)
            if(nav_end(i)-nav_end(i-1)==1)
                idx(end+1)=i-1;
            end
        end
        nav_end(idx)=[];
        
        %%
        % other unused but potentially relevant event triggers:
        % 'Player reached 40 trials'
        % 'Player did not reach proficiency'
        % 'Lvl 0 reached: training video'
        % 'Training video started'
        
        % find actual timestamps associated with all of these events
        % should always be 8 trials
        nav_times = zeros(2,length(nav_end));
        arm_times = zeros(2,length(arm_end));
        vs_times = zeros(2,length(vs_end));
        
        for i=1:length(nav_end)
            nav_times(1,i) = events_rov.time_stamps(nav_start(i));
            nav_times(2,i) = events_rov.time_stamps(nav_end(i));
            nav_dur(i) = nav_times(2,i)-nav_times(1,i);
        end
        
        for i=1:length(arm_end)
            arm_times(1,i) = events_rov.time_stamps(arm_start(i));
            arm_times(2,i) = events_rov.time_stamps(arm_end(i));
            arm_dur(i) = arm_times(2,i)-arm_times(1,i)-23.0756; % 23.0756 = calculated time for robot arm deploy/stowage
        end
        
        
        for i=1:length(vs_end)
            vs_times(1,i) = events_rov.time_stamps(vs_start(i));
            vs_times(2,i) = events_rov.time_stamps(vs_end(i));
            vs_dur(i) = vs_times(2,i)-vs_times(1,i);
        end
    elseif type=='cor'
        events_cor = events;
    
        % find indices of nav, robot arm, vs task start and stop
        nav_start = find(contains(events_cor.time_series,'Trial Started'));
        nav_end = find(strcmp(events_cor.time_series,'Task 1 Ended')==1);
        arm_start = find(strcmp(events_cor.time_series,'Task 1 Ended')==1);
        arm_end = find(strcmp(events_cor.time_series,'Task 2 Ended')==1);
        vs_start = find(strcmp(events_cor.time_series,'Task 2 Ended')==1);
        vs_end = find(strcmp(events_cor.time_series,'Task 3 Ended')==1);

        % find actual timestamps associated with all of these events
        % should always be 8 trials
        nav_times = zeros(2,length(nav_end));
        arm_times = zeros(2,length(arm_end));
        vs_times = zeros(2,length(vs_end));
        
        for i=1:length(nav_end)
            nav_times(1,i) = events_cor.time_stamps(nav_start(i));
            nav_times(2,i) = events_cor.time_stamps(nav_end(i));
            nav_dur(i) = nav_times(2,i)-nav_times(1,i);
        end
        
        for i=1:length(arm_end)
            arm_times(1,i) = events_cor.time_stamps(arm_start(i));
            arm_times(2,i) = events_cor.time_stamps(arm_end(i));
            arm_dur(i) = arm_times(2,i)-arm_times(1,i)-23.0756; % 23.0756 = calculated time for robot arm deploy/stowage
        end
        
        
        for i=1:length(vs_end)
            vs_times(1,i) = events_cor.time_stamps(vs_start(i));
            vs_times(2,i) = events_cor.time_stamps(vs_end(i));
            vs_dur(i) = vs_times(2,i)-vs_times(1,i);
        end
    end


end
