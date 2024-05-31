function probe1020 = registerprobe1020(probe,headsize,seperateflag,extrapoints)
% This function registers a probe to the 10-20 system

% This function was intended to register a 2D probe, not to re-register a 3D
% probe to a different head size.  If you give me a 3D probe, then call the
% proper version of the function
if(isa(probe,'nirs.core.Probe1020'))
    oldheadsize=probe.get_headsize;
    tbl1020=nirs.util.list_1020pts('?');
    oldtbl1020=nirs.util.register_headsize(oldheadsize,tbl1020);
    newtbl1020=nirs.util.register_headsize(headsize,tbl1020);
    Tform=nirs.registration.cp2tform(oldtbl1020,newtbl1020);
    
    probe1020=nirs.registration.applytform(probe,Tform);
    return;
end


if(nargin>2 && ~isempty(headsize) && isa(headsize,'nirs.core.Mesh'))
    Anatmesh=headsize;
    headsize=nirs.registration.getheadshape(Anatmesh(1));
else
    Anatmesh=[];
end

if(nargin>1 & ~isempty(headsize))
    probe1020 = nirs.core.Probe1020([],headsize);
else
    probe1020 = nirs.core.Probe1020;
end

if(~isempty(Anatmesh))
    probe1020=probe1020.set_mesh(Anatmesh);
end

if(nargin<3 || isempty(seperateflag))
    seperateflag=false;
end

probe.optodes.X=probe.optodes.X-mean(probe.optodes.X);
probe.optodes.Y=probe.optodes.Y-mean(probe.optodes.Y);
probe.optodes.Z=probe.optodes.Z-mean(probe.optodes.Z);

probe1020.link=probe.link;
probe1020.optodes=probe.optodes;

mesh=probe1020.getmesh;

if(nargin>3)
    mesh(1)=mesh(1).addfiducials(extrapoints);
end

if(seperateflag)
    % This handles disjointed probes (e.g. bihemisphere probes) by
    % splitting the probe into multiple parts (based on the link).  Each
    % part should have at least one anchor point.  All anchor points in
    % other parts are then changed to attractors
    
    % First split the probe
    conn=zeros(size(probe.srcPos,1),size(probe.detPos,1));
    conn(sub2ind(size(conn),probe.link.source,probe.link.detector))=1;
    
    detxdet=(conn'*conn*conn'*conn*conn'*conn~=0);
    srcxsrc=(conn*conn'*conn*conn'*conn*conn'*conn*conn'~=0);
    
    %Now find the clusters
    unacounted=[1:size(probe.detPos,1)];
    cluster={};
    i=1;
    while(length(unacounted)>0)
        lst=find(detxdet(unacounted(1),:));
        cluster{i}=lst;
        unacounted(ismember(unacounted,lst))=[];
        i=i+1;
    end
    srcPos=probe.srcPos;
    detPos=probe.detPos;
    disp(['Probe divided into ' num2str(length(cluster)) ' groups']);
    
    for i=1:length(cluster)
        disp([' registering group ' num2str(i)]);
        det=probe.detPos(cluster{i},:);
        lstlink=ismember(probe.link.detector,cluster{i});
        link=probe.link(lstlink,:);
        src=probe.srcPos(unique(link.source),:);
        p(i)=nirs.core.Probe(src,det,link);
        
        %now add fiducials
        fid=probe.optodes(ismember(probe.optodes.Type,{'FID-anchor','FID-attractor'}),:);
        xyz=[fid.X fid.Y fid.Z];
        [k,d]=dsearchn([p(i).srcPos; p(i).detPos],xyz);
        [~,id]=min(d);
        fid.Type=repmat({'FID-attractor'},height(fid),1);
        fid.Type{id}='FID-anchor';
        s=sort(d);
        lst=find(d>s(3)*1.5);
        fid(lst,:)=[];
        p(i).optodes=[p(i).optodes; fid];
        p(i) = nirs.util.registerProbe2Mesh(mesh(1),p(i));
        
        srcPos(unique(link.source),:)=p(i).srcPos;
        detPos(cluster{i},:)=p(i).detPos;
        f=p(i).optodes(ismember(p(i).optodes.Type,{'FID-anchor','FID-attractor'}),:);
%        ff(:,1,i)=f.X;
%        ff(:,2,i)=f.Y;
%        ff(:,3,i)=f.Z;
        
    end
    fid=probe.optodes(ismember(probe.optodes.Type,{'FID-anchor','FID-attractor'}),:);
    probe=nirs.core.Probe(srcPos,detPos,probe.link);
   
else
    probe = nirs.util.registerProbe2Mesh(mesh(1),probe);

end

    
probe1020.optodes_registered=probe.optodes;


