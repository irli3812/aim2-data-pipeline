function data = loadMEGSTC(filenames,srcfiff_file)

% if a single filename, put it in a cell
if ischar( filenames )
    filenames = {filenames};
end

if(nargin<2)
    srcfiff_file=[];
end

if(~iscell(srcfiff_file))
    srcfiff_file={srcfiff_file};
end


for i=1:length(filenames)
    f{i}=filenames{i}(1:strfind(filenames{i},'h.stc')-2);
end
filenames2=cell(length(f),2);

for i=1:length(f)
    filenames2{i,1}=[f{i} 'lh.stc'];
    filenames2{i,2}=[f{i} 'rh.stc'];
end
filenames=filenames2;


if(length(srcfiff_file)==1)
    srcfiff_file=repmat(srcfiff_file,size(filenames,1),1);
end


data = dtseries.core.Data;
data(:)=[];

% iterate through cell array
for iFile = 1:size(filenames,1)
    disp(['Reading ' filenames{iFile,1}]);
    stcL=mne_read_stc_file(filenames{iFile,1});
    disp(['Reading ' filenames{iFile,2}]);
    stcR=mne_read_stc_file(filenames{iFile,2});
    
    [p,f,ext]=fileparts(srcfiff_file{iFile});
    if(strcmp(ext,'.gz'))
        disp(['unzipping file ' srcfiff_file{iFile}]);
        gunzip(srcfiff_file{iFile});
        space=mne_read_source_spaces(fullfile(p,f));
        delete(fullfile(p,f));
    else
        space=mne_read_source_spaces(srcfiff_file{iFile});
    end
    mesh=nirs.core.Mesh(space(1).rr,space(1).use_tris);
    mesh(2)=nirs.core.Mesh(space(2).rr,space(2).use_tris);
    mesh(1)=nirs.util.mesh_remove_unused(mesh(1));
    mesh(2)=nirs.util.mesh_remove_unused(mesh(2));
    
    t=stcL.tmin+[0:size(stcL.data,2)-1]'*stcL.tstep;
    
    d=[stcL.data; stcR.data]';
    
    data(iFile).description=filenames{iFile};
    data(iFile).time=t;
    
    if(size(d,1)>size(d,2))
        proj=speye(size(d,2),size(d,2));
        data(iFile).data=d;
    else
        
        lst=find(~any(isnan(d),1));
        [u,s,v]=nirs.math.mysvd(d(:,lst));
        proj=zeros(size(d,2),size(s,1));
        proj(lst,:)=v;
        proj=sparse(proj);
        
        data(iFile).data=u*s;
    end
    data(iFile).projectors=proj;
    data(iFile).cov=speye(size(data(iFile).data,2),size(data(iFile).data,2));
    
%     vertex=[find(ismember(space(1).vertno,double(stcL.vertices)))';
%         find(ismember(space(2).vertno,double(stcR.vertices)))'];
    vertex=[1:length(space(1).vertno) 1:length(space(2).vertno)]';
    
    surface=[ones(size(stcL.vertices)); 2*ones(size(stcR.vertices))];
    type=repmat(cellstr('megstc'),size(d,2),1);
    data(iFile).mesh=dtseries.core.Mesh(mesh,table(vertex,type));
    data(iFile).mesh.link=[data(iFile).mesh.link table(surface)];
end
