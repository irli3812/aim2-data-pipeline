%% SubtaskTimes Function

function [nav_times, nav_dur, arm_times, arm_duration, vs_times] = SubtaskTimes(subject, cond)
% SubtaskTimes processes the event times and durations for navigation, robotic arm, and observation tasks based on the subject and condition.
%
% Inputs:
%   - subject: Identifier for the subject
%   - cond: Condition (e.g., 'fnirs_rov' or 'fnirs_cor')
%
% Outputs:
%   - nav_times: A 2xN array containing start and end times of navigation tasks
%   - nav_dur: A 1xN array containing the duration of each navigation task
%   - arm_times: A 2xN array containing start and end times of robotic arm tasks
%   - arm_duration: A 1xN array containing the duration of each robotic arm task
%   - vs_times: A 2xN array containing start and end times of observation tasks

% Load or select the appropriate dataset based on subject and cond
% Here we assume the dataset is a structure named based on the condition

[fnirs_cor, fnirs_rov, events_cor, events_rov, ~, ~] = extract_events(subject);
if cond == 'c'
    cond = fnirs_cor;
    eventtype = events_cor;
elseif cond == 'r'
    cond = fnirs_rov;
    eventtype = events_rov;
end

% Find indices of nav, robot arm, vs task start and stop
nav_start = find(strcmp(cond.time_series, 'Navigation Task Started') == 1);
nav_end = find(strcmp(cond.time_series, 'Navigation Task Ended') == 1);
arm_start = find(strcmp(cond.time_series, 'Robotic Arm Task Started') == 1);
arm_end = find(strcmp(cond.time_series, 'Robotic Arm Task Ended') == 1);
vs_start = find(strcmp(cond.time_series, 'Observation Task Started') == 1);
vs_end = find(strcmp(cond.time_series, 'Observation Task Ended') == 1);

% Remove duplicates from nav_end
for i = 2:length(nav_end)
    if(nav_end(i) - nav_end(i-1) == 1)
        nav_end(i-1) = [];
    end
end

% Initialize times arrays
nav_times = zeros(2, length(nav_end));
arm_times = zeros(2, length(arm_end));
vs_times = zeros(2, length(vs_end));
nav_dur = zeros(1, length(nav_end));

% find actual timestamps associated with all of these events
% should always be 8 trials
nav_times = zeros(2,length(nav_end));
arm_times = zeros(2,length(arm_end));
vs_times = zeros(2,length(vs_end));

for i=1:length(nav_end)
    nav_times(1,i) = eventtype.time_stamps(nav_start(i));
    nav_times(2,i) = eventtype.time_stamps(nav_end(i));
    nav_dur(i) = nav_times(2,i)-nav_times(1,i);
end

for i=1:length(arm_end)
    arm_times(1,i) = eventtype.time_stamps(arm_start(i));
    arm_times(2,i) = eventtype.time_stamps(arm_end(i));
end

arm_duration = arm_times(2,:)-arm_times(1,:)-23.0756; % 23.0756 = calculated time for robot arm deploy/stowage

for i=1:length(vs_end)
    vs_times(1,i) = eventtype.time_stamps(vs_start(i));
    vs_times(2,i) = eventtype.time_stamps(vs_end(i));
end