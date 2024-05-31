function probe2JSON(probe,filename)
% 
% if(isa(probe,'nirs.core.Probe'))
%     % this is a 2D probe and nothing to do
%     return
% end


if(strcmp(class(probe),'nirs.core.Probe1020'))
    
    link=probe.link;
    writetable(link,[filename '_channels.tsv'],'FileType','text','Delimiter','\t');
    
    optodes=probe.optodes;
    optodes.name=optodes.Name; optodes.Name=[];
    optodes.type=optodes.Type; optodes.Type=[];
    optodes.x=optodes.X; optodes.X=[];
    optodes.y=optodes.Y; optodes.Y=[];
    optodes.z=optodes.Z; optodes.Z=[];
    optodes.units=optodes.Units; optodes.Units=[];
    writetable(optodes,[filename '_optodes2D.tsv'],'FileType','text','Delimiter','\t');

    optodes=probe.optodes_registered;
    optodes.name=optodes.Name; optodes.Name=[];
    optodes.type=optodes.Type; optodes.Type=[];
    optodes.x=optodes.X; optodes.X=[];
    optodes.y=optodes.Y; optodes.Y=[];
    optodes.z=optodes.Z; optodes.Z=[];
    optodes.units=optodes.Units; optodes.Units=[];
    
    writetable(optodes,[filename '_optodes.tsv'],'FileType','text','Delimiter','\t');
    
    mesh=probe.getmesh;
    fidc=mesh(1).fiducials;
    
    fid=fopen([filename '_coordsystem.json'],'w');
    
    fprintf(fid,'{\n');
    fprintf(fid,'\t"NIRSCoordinateSystem": "%s",\n','MNI');
    fprintf(fid,'\t"NIRSCoordinateUnits": "%s",\n','mm');
    fprintf(fid,'\t"AnatomicalLandmarkCoordinates": {\n');
    for i=1:height(fidc)-1
        fprintf(fid,'\t\t"%s": [%f,\t%f,\t%f],\n',fidc.Name{i},fidc.X(i),fidc.Y(i),fidc.Z(i));
    end
    fprintf(fid,'\t\t"%s": [%f,\t%f,\t%f]\n',fidc.Name{end},fidc.X(end),fidc.Y(end),fidc.Z(end));
    fprintf(fid,'\t},\n');
    fprintf(fid,'\t"AnatomicalLandmarkCoordinateSystem": "%s",\n','T1w');
    fprintf(fid,'\t"AnatomicalLandmarkCoordinateUnits": "%s",\n','mm');
    fprintf(fid,'\t"IntendedFor": "%s",\n',['anat/T1w.nii.gz']);
    fprintf(fid,'}');
    fclose(fid);
elseif(strcmp(class(probe),'eeg.core.Probe'))
    
    electrodes=probe.electrodes;
    electrodes.X=[];
    electrodes.Y=[];
    electrodes.Z=[];
    electrodes.Units=[];
    electrodes.name=electrodes.Name; electrodes.Name=[]; 
    electrodes.type=repmat({'EEG'},height(electrodes),1);
    electrodes.units=repmat({'scaled'},height(electrodes),1);
    electrodes.status=repmat({'unknown'},height(electrodes),1);
    electrodes.status_description=repmat({' '},height(electrodes),1);
    
    writetable(electrodes,[filename '_channels.tsv'],'FileType','text','Delimiter','\t');   
    
    
    electrodes=probe.electrodes;
    electrodes.x=electrodes.X; electrodes.X=[];
    electrodes.y=electrodes.Y; electrodes.Y=[];
    electrodes.z=electrodes.Z; electrodes.Z=[];
    electrodes.units=electrodes.Units; electrodes.Units=[];
    writetable(electrodes,[filename '_electrodes.tsv'],'FileType','text','Delimiter','\t');
    
   
else
    link=probe.link;
    writetable(link,[filename '_channels.tsv'],'FileType','text','Delimiter','\t');
    
    
    optodes=probe.optodes;
    optodes.name=optodes.Name; optodes.Name=[];
    optodes.type=optodes.Type; optodes.Type=[];
    optodes.x=optodes.X; optodes.X=[];
    optodes.y=optodes.Y; optodes.Y=[];
    optodes.z=optodes.Z; optodes.Z=[];
    optodes.units=optodes.Units; optodes.Units=[];
    writetable(optodes,[filename '_optodes.tsv'],'FileType','text','Delimiter','\t');
    
end


return