classdef synthetic_measurement < nirs.modules.AbstractModule
    %% Combines ChannelStats data into a common space
    %
    properties
        commonprobe = 'combine';
        FwdModel = [];
    end
    methods
        function obj = synthetic_measurement( prevJob )
            obj.name = 'synthetic measurement';
            if nargin > 0
                obj.prevJob = prevJob;
            end
        end
        
        function data = runThis( obj, data )
            if(~isa(obj.commonprobe,'nirs.core.Probe') && ...
                    ~isa(obj.commonprobe,'nirs.core.Probe1020'))
                probe=combineprobes(data);
            else
                probe=obj.commonprobe;
            end
            for i = 1:numel(data)
                disp([num2str(i) ' of ' num2str(length(data))]);
                data(i)=synthetic_meas(data(i),probe, obj.FwdModel);
            end
        end
    end
    
end


function probe = combineprobes(data)


ndet=0;
nsrc=0;
link=[];
optodes=[];
for i = 1:numel(data)
    thislink=data(i).probe.link;
    thislink.source=thislink.source+nsrc;
    thislink.detector=thislink.detector+ndet;
    
    thisoptodes=data(i).probe.optodes;
    for j=1:size(data(i).probe.detPos,1)
        dI=['0000' num2str(j)];
        dI=dI(end-3:end);
        dI2=['0000' num2str(j+ndet)];
        dI2=dI2(end-3:end);
        
        lst=find(ismember(thisoptodes.Name,['Detector-' dI]));
        thisoptodes.Name{lst}=['Detector-' dI2];
    end
    
    for j=1:size(data(i).probe.srcPos,1)
        dI=['0000' num2str(j)];
        dI=dI(end-3:end);
        dI2=['0000' num2str(j+nsrc)];
        dI2=dI2(end-3:end);
        
        lst=find(ismember(thisoptodes.Name,['Source-' dI]));
        thisoptodes.Name{lst}=['Source-' dI2];
    end
    link=[link; thislink];
    optodes=[optodes; thisoptodes];
    ndet=ndet+size(data(i).probe.detPos,1);
    nsrc=nsrc+size(data(i).probe.srcPos,1);
    
end


probe=data(1).probe;
probe.optodes=optodes;
probe.link=link;

if(isa(data(1).probe,'nirs.core.Probe1020'))
    warning('this will not work if the underlying probe mesh differ');
    
    optodes=[];
    for i = 1:numel(data)
        thislink=data(i).probe.link;
        thislink.source=thislink.source+nsrc;
        thislink.detector=thislink.detector+ndet;
        
        thisoptodes=data(i).probe.swap_reg.optodes;
        for j=1:size(data(i).probe.swap_reg.detPos,1)
            dI=['0000' num2str(j)];
            dI=dI(end-3:end);
            dI2=['0000' num2str(j+ndet)];
            dI2=dI2(end-3:end);
            
            lst=find(ismember(thisoptodes.Name,['Detector-' dI]));
            thisoptodes.Name{lst}=['Detector-' dI2];
        end
        
        for j=1:size(data(i).probe.swap_reg.srcPos,1)
            dI=['0000' num2str(j)];
            dI=dI(end-3:end);
            dI2=['0000' num2str(j+nsrc)];
            dI2=dI2(end-3:end);
            
            lst=find(ismember(thisoptodes.Name,['Source-' dI]));
            thisoptodes.Name{lst}=['Source-' dI2];
        end
        link=[link; thislink];
        optodes=[optodes; thisoptodes];
        ndet=ndet+size(data(i).probe.detPos,1);
        nsrc=nsrc+size(data(i).probe.srcPos,1);
        
    end
    probe.optodes_registered=optodes;
end


end


function ChanStatsNew = synthetic_meas(ChanStats,NewProbe,FwdModel)
% This function converts the ChannelStats info from the imput into the
% space of the NewProbe.  If the forward model is not provided, the
% semi-infinte slab model with default parameters is used.
%
%
%% Example:
% data=nirs.testing.simData;
% job=nirs.modules.Resample();
% job=nirs.modules.OpticalDensity(job);
% job=nirs.modules.AR_IRLS(job);
% SubjStats = job.run(data);
% newprobe=data.probe;
% newprobe.optodes.X=newprobe.optodes.X+15*randn(height(newprobe.optodes),1);
% newprobe.optodes.Y=newprobe.optodes.Y+15*randn(height(newprobe.optodes),1);
% NewSubjStats = synthetic_meas(SubjStats,newprobe);

%% Construct the forward model for the old and new probe

if(nargin<3 || isempty(FwdModel))
    
    if(~isa(NewProbe,'nirs.core.Probe1020'))
        % No forward model provided, then build the slab version
        minX = min(min(ChanStats.probe.optodes.X),min(NewProbe.optodes.X));
        maxX = max(max(ChanStats.probe.optodes.X),max(NewProbe.optodes.X));
        dX = (maxX-minX)/3;
        minY = min(min(ChanStats.probe.optodes.Y),min(NewProbe.optodes.Y));
        maxY = max(max(ChanStats.probe.optodes.Y),max(NewProbe.optodes.Y));
        dY = (maxY-minY)/3;
        
        [X,Y,Z]=meshgrid([minX-dX:dX/30:maxX+dX],[minY-dY:dY/30:maxY+dY],[-10]);
        
        mesh=nirs.core.Mesh;
        mesh.nodes=[X(:) Y(:) Z(:)];
    else
        mesh=NewProbe.getmesh;
        %mesh=mesh(end);
    end
    lambda=unique(NewProbe.link.type);
    if(~isnumeric(lambda))
        lambda=808;
    end
    FwdModel=nirs.forward.ApproxSlab;
    FwdModel.mesh=mesh;
    FwdModel.prop=nirs.media.tissues.brain(.7,50,lambda);
    FwdModel.Fm=0;
end

% TODO: Do some FwdModel checking here


ChanStats=sorted(ChanStats,{'type','source','detector','cond'});
NewProbe.link=sortrows(NewProbe.link,{'type','source','detector'});

% if(~isa(ChanStats.probe,'nirs.core.Probe1020'))
%     FwdModel.probe=ChanStats.probe;
% else
%     FwdModel.probe=ChanStats.probe.swap_reg;
% end


[Lold]=FwdModel.jacobian('spectral');
Lold=[Lold.hbo Lold.hbr];

% if(isnumeric(FwdModel.probe.link.type))
%     [Lold]=FwdModel.jacobian('spectral');
%     Lold=[Lold.hbo Lold.hbr];
% else
%      % If hemoglobin was supplied, fake it with a 808 wavelength
%     [a,~,lst]=unique(FwdModel.probe.link.type);
%     FwdModel.probe.link.type=repmat(808,height(FwdModel.probe.link),1);
%     Lold=FwdModel.jacobian;
%     L=zeros(length(lst),length(a)*size(Lold.mua,2));
%     for i=1:length(a)
%         L(find(lst==i),(i-1)*size(Lold.mua,2)+1:i*size(Lold.mua,2))=Lold.mua(find(lst==i),:);
%     end
%     Lold=sparse(L)*1E6;
% end


% if(~isa(NewProbe,'nirs.core.Probe1020'))
%     FwdModel.probe=NewProbe;
% else
%     FwdModel.probe=NewProbe.swap_reg;
% end

[Lnew]=FwdModel.jacobian('spectral');
Lnew=[Lnew.hbo Lnew.hbr];
    
% if(isnumeric(FwdModel.probe.link.type))
%     [Lnew]=FwdModel.jacobian('spectral');
%     Lnew=[Lnew.hbo Lnew.hbr];
% else
%     % If hemoglobin was supplied, fake it with a 808 wavelength
%     [a,~,lst]=unique(FwdModel.probe.link.type);
%     FwdModel.probe.link.type=repmat(808,height(FwdModel.probe.link),1);
%     Lnew=FwdModel.jacobian;
%     L=zeros(length(lst),length(a)*size(Lnew.mua,2));
%     for i=1:length(a)
%         L(find(lst==i),(i-1)*size(Lnew.mua,2)+1:i*size(Lnew.mua,2))=Lnew.mua(find(lst==i),:);
%     end
%     Lnew=sparse(L)*1E6;
% end



if(isa(ChanStats,'nirs.core.Data'))
    error('not supported data type');
end

ChanStatsNew=ChanStats;
ChanStatsNew.probe=NewProbe;

cond=ChanStats.conditions;
if(length(cond)>1)
    error('not fully tested')
end

W=inv(chol(ChanStats.covb));

[U,S,V]=nirs.math.mysvd(Lold);

L=U*S;
Lnew=Lnew*V;

% Not sure why this ReML code is not working (might be related to scaling
% for MUA forward models??

% [m,n]=size(L);
% 
% m=m/2; n=n/2;
% Q={blkdiag(speye(n,n),zeros(n,n)) blkdiag(zeros(n,n),speye(n,n))};
% R={W'*ChanStats.covb*W};
% 
% xo=zeros(n*2,1);
% [lambda,Beta,Stats]=nirs.math.REML(W*ChanStats.beta,W*L,xo,R,Q);
% 
% ChanStatsNew.beta=Lnew*Beta;
% ChanStatsNew.covb=Lnew*Stats.tstat.covb*Lnew';

L=Lnew*pinv(W*S*U)*W;


% [Uold, Unew, V, Sold, Snew] = gsvd(Lold, Lnew);
% stalbe_param = 1e-6;
% L = Unew * Snew / (Sold + stalbe_param * eye(size(Sold))) * Uold';


ChanStatsNew.beta=L*ChanStats.beta;
ChanStatsNew.covb=L*ChanStats.covb*L';

cond=repmat(cond,height(ChanStatsNew.probe.link),1);
ChanStatsNew.variables=[ChanStatsNew.probe.link table(cond)];

end
