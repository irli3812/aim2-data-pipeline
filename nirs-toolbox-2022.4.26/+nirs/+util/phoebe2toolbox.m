function probe1020=phoebe2toolbox(filename,lambda)

filename=strtok(filename,'.');
load([filename '.SD'],'-MAT','SD');

if ~isfield(SD,'Lambda')
    if(nargin>1)
        SD.Lambda=lambda;
    else
        SD.Lambda = [690 830];
        warning('Assuming wavelengths = [690 830]');
    end
end

% register it via phoebe
handles=[];
load_atlas;
[ handles ] = load_dig_pts( handles, [filename '.txt']);
SD.SrcPos=handles.src_pts;
SD.DetPos=handles.det_pts;



probe=nirs.util.sd2probe(SD);

% load the atlas model from Phoebe
load('scalp_model');
mesh=nirs.core.Mesh(vertices(:,2:4),faces(:,2:4));

fid=table({'nas';'rpa';'lpa'},fiducials(:,1),fiducials(:,2),fiducials(:,3),repmat(cellstr('10-20'),3,1),repmat(cellstr('mm'),3,1),...
    'VariableNames',{'Name','X','Y','Z','Type','Units'}); 
mesh=mesh.addfiducials(fid);
mesh.transparency = .4;

probe1020=nirs.core.Probe1020;
probe1020.optodes_registered=probe.optodes;
probe1020.link=probe.link;
probe1020=probe1020.register_mesh2probe(mesh,false);

XYZ=[probe.optodes.X probe.optodes.Y probe.optodes.Z];

probe1020.optodes=probe.optodes;

[probe1020.optodes.X,probe1020.optodes.Y]=probe1020.convert2d(XYZ);
probe1020.optodes.Z(:)=0;


