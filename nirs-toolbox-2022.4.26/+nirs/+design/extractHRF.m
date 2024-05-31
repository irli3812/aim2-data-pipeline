function HRF = extractHRF(Stats,basis,duration,Fs,type)
% This function returns the impulse response or HRF 
% from a nirs.core.ChannelStats variable  
%
% Inputs:
%     Stats -  a nirs.core.ChannelStats or nirs.core.ImageStats variable
%     basis - the basis function used to compute the stats
%     duration (optional) - convolves the IRF (default =1/Fs)
%     Fs - the sample rate to use (default = 4Hz)

if(nargin<5)
    type={'hrf'};
end

if(~iscell(type))
    type={type};
end

if(nargin<4)
    Fs = 4;
end
if(nargin<3 | isempty(duration))
    duration=1/Fs;
end

if(~isa(basis,'Dictionary'))
    b=Dictionary();
    b('default')=basis;
    basis=b;
end

if(length(Stats)>1)
    for idx=1:length(Stats)
         HRF(idx) = nirs.design.extractHRF(Stats(idx),basis,duration,Fs,type);
    end
    return;
end

conditions=Stats.conditions;
conditions = sort_names(conditions);

if(isa(duration,'Dictionary'))
    dur=zeros(duration.count,1);
    for idx=1:duration.count
        s=duration(duration.keys{idx});
        dur(idx)=s.dur;
    end
end


lenHRF=90;
t=[0:1/Fs:(max(dur)+lenHRF)*length(duration.count)];
stimulus=Dictionary();
for idx=1:duration.count
    stim=nirs.design.StimulusEvents(duration.keys{idx},0,dur(idx),1);
    lst=find(ismember({conditions{:,2}},duration.keys{idx}));
    for j=1:length(lst)
        stimulus(conditions{lst(j),1})=stim;
    end
end
[X, names,offset] = nirs.design.createDesignMatrix( stimulus, t, basis);



StimMapping=zeros(length(conditions),2);

for i=1:size(conditions,1)
    a=ismember(stimulus.keys,{conditions{i,1}});
    StimMapping(i,1)=find(a);
    if(size(conditions,2)>1 && ~isempty(str2num(conditions{i,end})))
        StimMapping(i,2)=str2num(conditions{i,end});
    else
        StimMapping(i,2)=1;
    end
end

tbl=Stats.table;

if(~iscellstr(tbl.type))
    tbl.type=arrayfun(@(x)cellstr(num2str(x)),tbl.type);
end

if(~ismember('source',Stats.probe.link.Properties.VariableNames) & ...
        ismember('ROI',Stats.probe.link.Properties.VariableNames))
    [tbl2,~,lst]=unique(table(tbl.ROI, tbl.type,'VariableNames',{'ROI','type'}));
else
    [tbl2,~,lst]=unique(table(tbl.source, tbl.detector, tbl.type,'VariableNames',{'source','detector','type'}));
    
end
 
 
data=[]; var=table;
for j=1:height(tbl2)
    t=tbl(lst==j,:);
    
    
    for ii=1:stimulus.count
        lst2=find(StimMapping(:,1)==ii);
        
        c=sort_names(Stats.conditions(lst2,:));
        
        i=find(ismember(t.cond,Stats.conditions(lst2,:)));
        
        if(strcmp(type,'hrf'))
            H = X(:,lst2)*t.beta(i);
        else
            H = X(:,lst2)*t.tstat(i);
        end
        data=[data H];
    end
    
    
    tt=tbl2(j,:);
    tt=repmat(tt,stimulus.count,1);
    tt.type=strcat(tt.type,repmat('_',stimulus.count,1),stimulus.keys(:));
    var=[var; tt];
end


% tbl3=table(tbl.source,tbl.detector,strcat(tbl.type,repmat('-',height(tbl),1),cond),'VariableNames',{'source','detector','type'});
% [i,j]=ismember(tbl3,var);
% var=var(j,:);
% data=data(:,j);

% Cut off all the zeros at the end
[i,~]=find(X~=0);
i=mod(i,(max(dur)+lenHRF)*Fs);
npts = fix(min(max(i)+10,(max(dur)+lenHRF)*Fs));

HRF=nirs.core.Data();
HRF.description=['HRF from basis: ' Stats.description];
HRF.probe=Stats.probe;
HRF.time=[0:npts-1]'/Fs-offset/Fs;

HRF.probe.link=var;
HRF.data=data(1:npts,:);

if(isempty(Stats.demographics))
    Stats.demographics=Dictionary();
end
HRF.demographics=Stats.demographics;


stimulus=Dictionary();
for idx=1:duration.count
    stim=nirs.design.StimulusEvents(conditions{idx},.001,dur(idx),1);
    stimulus(duration.keys{idx})=stim;
end

HRF.stimulus=stimulus;

return


function newnames = sort_names(conditions)

numparts=length(strfind(conditions{1},':'))+1;

parts = cell(length(conditions),numparts);
for i=1:length(conditions)
    n=conditions{i};
    for j=1:numparts
        [parts{i,j},n]=strtok(n,':');
    end
end

isnum=false(numparts,1);
for i=1:numparts
    isnum(i)=(~isempty(str2num(parts{1,i})));
end

lst=[find(~isnum); find(isnum)];
lst1=[find(~isnum)];

newnames=cell(length(conditions),length(lst));
for i=1:size(parts,1)
    newnames{i,1}='';
    for j=1:length(lst1)
        newnames{i,1}=[newnames{i,1} ':' parts{i,lst1(j)}];
    end
    newnames{i,1}(1)=[];
    for j=1:length(lst)
        newnames{i,j+1}=parts{i,lst(j)};
    end
end
