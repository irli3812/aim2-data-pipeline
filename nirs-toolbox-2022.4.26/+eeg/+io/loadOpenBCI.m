function data = loadOpenBCI(filename,fs)
% This function loads OpenBCI (txt) EEG data
% Please delete the first six rows in the txt file

if(nargin<2)
    fs=250;
end

addnotch=true;

Fs_raw = 250;

data = load(filename);

n=round(Fs_raw/fs);

d = data(2:end,2:9);
aux = data(2:end,10);

if(addnotch)
    for i=60:60:Fs_raw/2
        d1 = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',i-5,'HalfPowerFrequency2',i+5, ...
               'DesignMethod','butter','SampleRate',Fs_raw);
        d = filtfilt(d1,d);
    end
end



d=resample(double(d'),1,n)';
fs=250/n;

data=eeg.core.Data;
data.probe=eeg.core.Probe;

nchan=size(d,2);

data.probe.link=table([1:nchan]',...
    repmat({'eeg'},nchan,1),'VariableNames',{'electrode','type'});

data.data=d;
data.time=[0:size(d,1)-1]/fs;
data.description=which(filename);

stim = findstim(aux,Fs_raw,data.time); 
data.stimulus=stim;
data.description=filename;
end

function stim = findstim(aux,Fs_raw,t)

aux2=aux;
stim=Dictionary;

s=diff(aux(:,1));
s=s-s(1);
s=s./sqrt(var(s));
lst=find(s>20);
lst(find(diff(lst)<50))=[];
aux(:,1)=0;
aux([lst lst+1 lst+2],1)=1;
onsets=lst;
%onsets2 = onsets;
%onsets2([2:2:end]) = [];
%durs = diff(onsets);
%durs([2:2:end]) = [];

if(length(onsets)>30)
        st=nirs.design.StimulusEvents;
        st.name=['aux'];
        k=dsearchn(t,onsets/Fs_raw);
        st.onset=t(k);
        st.dur=ones(size(st.onset))*2*mean(diff(t));
        st.amp=ones(size(st.dur));
        stim(st.name)=st;
end
    

end