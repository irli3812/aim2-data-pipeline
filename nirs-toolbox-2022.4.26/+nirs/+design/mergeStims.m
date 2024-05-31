function out = mergeStims( stims, name )
    
    onset   = [];
    dur     = [];
    amp     = [];
    
    % loop through stims and concat onset, dur, amp
    for i = 1:length(stims)
        
        if(~isfield(stims{i},'amp'))
            stims{i}.amp=ones(size(stims{i}.onset));
        end
        
        
        onset   = [onset; stims{i}.onset(:)];
        dur     = [dur; stims{i}.dur(:)];
        amp     = [amp; stims{i}.amp(:)];
    end
    
    % create output
    out = nirs.design.StimulusEvents();
    
    out.name    = name;
    out.onset   = onset;
    out.dur     = dur;
    out.amp     = amp;
end