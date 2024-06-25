% Call the function with subject number 319
[fnirs_cor, fnirs_rov, events_cor, events_rov, path1, path2] = extract_events('319');

% Display the output paths to verify the files loaded
disp(['Path 1: ', path1]);
disp(['Path 2: ', path2]);

% Display the extracted events and fNIRS data
disp('Corollary Events:');
disp(events_cor);
disp('Rover Events:');
disp(events_rov);
disp('Corollary fNIRS Data:');
disp(fnirs_cor);
disp('Rover fNIRS Data:');
disp(fnirs_rov);