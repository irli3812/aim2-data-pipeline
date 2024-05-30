dir = 'Y:\files\AFOSR\Consented Experiment Data\003\2022-05-02_007'; %fnirs data

%first load your data
raw = nirs.io.loadDirectory(dir);
%%
%resample (if you want)
% 
%job=nirs.modules.Resample ;
%job.Fs = 240;
%rs=job.run(raw) ;

%job=nirs.modules.TrimBaseline;
%job.preBaseline=30;
%job.postBaseline=30;
%rs2=job.run(rs);

job=nirs.modules.OpticalDensity;
od=job.run(raw);
%job.cite

job=nirs.modules.BeerLambertLaw;
hb=job.run(od);
%job.cite

 %job=nirs.modules.AddAuxRegressors;
 %mot_corr=job.run(hb);
% job.cite
% 
% job=nirs.modules.AddShortSeperationRegressors;
% short_sep=job.run(mot_corr)
% job.cite
% 
% job.AddShortSepRegressors = true; %not sure if need this in addition to prev job
%SubjStats=job.run(short_sep) 

%must have homer2 folder in your matlab folder
%jobs = nirs.modules.Run_HOMER2;
%jobs.fcn = 'hmrBandpassFilt'; % indicate the function for applying the bandpass filter
%jobs.vars.lpf = .5; %0.5; % define the low-pass cut-off frequency
%jobs.vars.hpf = 0.01; % define the high-pass cut-off frequency (0 for no high-pass filter)

% to do it without homer 2 you can use this instead
jobs = eeg.modules.BandPassFilter()
jobs.lowpass= .5;
jobs.highpass=0.01;

Hb_filtered = jobs.run(hb);

%Here, I then go into the filtered hb data in matlab, copy it to excel 
% and plot it. You can also plot in matlab, I just prefer excel for plotting
%one channel of the time. 



% jobs = nirs.modules.DiscardStims();
% jobs.listOfStims = {...
%     'stim_channel12' 
%     'stim_channel100' 
%     'stim_channel200' 
%     };

%rs3 = jobs.run(Hb_filtered);

% rs3 = nirs.design.change_stimulus_duration(rs3, 'stim_channel5', 20);
% rs3 = nirs.design.change_stimulus_duration(rs3, 'stim_channel6', 20);


% jobs = nirs.modules.RenameStims();
% jobs.listOfChanges = {...
%     'stim_channel1' 'select100'
%     'stim_channel2' 'select200'
%     'stim_channel3' 'confirm'
%     'stim_channel4' 'trial_end'
%     'stim_channel5' 'fixation_start'
%     'stim_channel6' 'trial_start'
%     };
% 

%HB_filtered = jobs.run(rs3);




%low = (trust<(mean(trust)));
%high = (trust>(mean(trust)));
%HB_filtered2 = changingDuration(HB_filtered);
%%
% 002 - mean
% 003 - cutoff is 2.5 
% 004 - 3.5, 6.5 
% 005 - split at 7 

%low = (trust<(mean(trust)));
%high = (trust>(mean(trust)));
% low = trust < 7;
% high = trust > 7;

%HB_filtered_trust = splitHighandLow(HB_filtered2, high, low)

%%
% figure()
% hist(trust);
% xlabel('trust score')
% ylabel('frequency')
% 
% figure
% plot(trust, 'o-', 'LineWidth',2); 
% xline([8])%, 14, 15, 18, 20, 22])
% xlabel('trial number')
% ylabel('trust score')
% legend('trust', 'unreliable trial')
% 
% %%
% 
% jobs=nirs.modules.GLM();
%     
% jobs=nirs.modules.ExportData(jobs);
% jobs.Output='SubjStats';
% %data=jobs.run(HB_filtered_trust);
% data=jobs.run(concatData)
% % Display Results
% 
% %SubjStats(1).draw('tstat', [-10,10], 'p<0.05');
% 
% %high v low contrast
% c=[0 0 1 -1];
% 
% ContrastSubj = SubjStats(1).ttest(c); % compute t-test
% % Plot results on a scale of -10 to 10
% % Apply q value threshold of 0.05
% ContrastSubj.draw('tstat', [-5 5], 'p < 0.05') % apply threshold
% 
% 
% %demographics = nirs.createDemographicsTable(data)
% job = nirs.modules.MixedEffects;
% job.formula = 'beta ~ -1 + cond + (1|subject)';
% 
% GroupStatsME = job.run(SubjStats);
% ConstrastGroup = GroupStatsME.ttest(c)
% ConstrastGroup.draw('tstat', [-5 5], 'p < 0.05')
% %%
% 
% job = nirs.modules.Connectivity();
% job.divide_events = true;
% job.min_event_duration = 5; 
% job.ignore = 0;
% job.corrfcn=@(data)nirs.sFC.ar_corr(data,'4x',true);
% ConnStats = job.run(HB_filtered_trust);
% ConnStats(1).draw('R',[-1 1],'p<0.005');
% 
% %%
% job = nirs.modules.MixedEffectsConnectivity();
% 
% GroupConnStats = job.run(ConnStats);
% GroupConnStats.draw('R',[-.5 .5],'p<0.05')
% GraphGroup=GroupConnStats.graph('Z:hbo','p<0.005');
