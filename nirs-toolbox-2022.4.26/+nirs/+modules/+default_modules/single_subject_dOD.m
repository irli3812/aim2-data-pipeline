function jobs = single_subject_dOD
jobs=nirs.modules.ImportData();
jobs.Input='raw';
jobs=nirs.modules.RemoveStimless(jobs);

jobs = nirs.modules.FixNaNs(jobs);
jobs = nirs.modules.Resample(jobs);
jobs.Fs = 5; % resample to 5 Hz

jobs = nirs.modules.OpticalDensity( jobs );
jobs = nirs.modules.ExportData(jobs);
jobs.Output='dOD';
jobs = nirs.modules.TrimBaseline( jobs );
jobs.preBaseline   = 30;
jobs.postBaseline  = 30;
jobs = nirs.modules.GLM(jobs );
jobs = nirs.modules.ExportData(jobs);
jobs.Output='SubjStats';