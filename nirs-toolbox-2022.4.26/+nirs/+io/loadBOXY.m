function data = loadBOXY(filenames,SD,CalibrationFile,CalibrationPhantom)
% Inputs:
%   calibration_file = file name or data file
%                      may be cell array of multiples files/data
%  PhantomProperties = Struct of phantom properties
%        PhantomProperties.Lambda - list of wavelengths (any order)
%        PhantomProperties.MUA -  absorption value (one per wavelength)
%        PhantomProperties.MUS -  scattering value (one per wavelength)
%                       must be cell array if multiple files are used
       
warning('nirs.io.loadBOXY.m function has hardcoded wavelength info specific for my ISS system; please edit');

wavelengthlst{1}=[1 16 17 32];  %676
wavelengthlst{2}=[2 15 18 31];  %690
wavelengthlst{3}=[3 14 19 30]; %750
wavelengthlst{4}=[4 13 20 29 ]; %788
wavelengthlst{5}=[5 12 21 28]; %800
wavelengthlst{6}=[6 11 22 27]; %808
wavelengthlst{7}=[7 10 23 26]; %830
wavelengthlst{8}=[8 9 24 25];

lambda=[676 690 750 788 800 808 830 788.1];

    if ischar( filenames )
        filenames = {filenames};
    end
    
    if(nargin==4)
        WF = calibrate_from_phantom(CalibrationFile,CalibrationPhantom)
    else
        if(nargin==3)
            warning('Both calibration file (BOXY) and Properties need to be assigned');
        end
        
        WF=[];
    end
    
    data = nirs.core.Data.empty;
    
    % iterate through cell array
    for iFile = 1:length(filenames)
        try
            % load data as a struct
            ISSdata = ReadBoxyData(filenames{iFile},WF,wavelengthlst,lambda);
            
            ml=ISSdata.Data.MeasurementList;
            
            laserPos=zeros(32,1);
            wav=zeros(32,1);
            for j=1:length(SD.LaserPos)
                laserPos(SD.LaserPos{j})=j;
            end
            for j=1:length(wavelengthlst)
                wav(wavelengthlst{j})=lambda(j);
            end
            
            
            ml(:,3)=laserPos(ml(:,1));
            ml(:,4)=wav(ml(:,1));
            
            link=table(ml(:,3),ml(:,2),ml(:,4),'VariableNames',{'source','detector','type'});
            lst=~ismember(ml(:,[3 2]),SD.MeasList,'rows');
           link(lst,:)=[];
           
            probe=nirs.core.Probe(SD.SrcPos,SD.DetPos,link);
            
            
            
            dist=zeros(size(ml,1),1);
            for i=1:length(dist)
                dist(i)=ISSdata.Distances(ml(i,2),ml(i,1));
            end
            
            ISSdata.Data.AC(lst,:)=[];
            ISSdata.Data.DC(lst,:)=[];
            ISSdata.Data.Phase(lst,:)=[];
            ISSdata.Distances(lst)=[];
            
            
            
            %convert ISSdata to the new class structure
            data(iFile)=nirs.core.Data;
            data(iFile).description=filenames{iFile};
            data(iFile).time=ISSdata.Data.time;
            
            data(iFile).probe.fixeddistances=dist;
            data(iFile).Fm=ISSdata.SD.ModFreq;
            
            
            
%             ac = abs( data.data(:,lst) );
%             phs = angle( data.data(:,lst) );
            ISSdata.Data.Phase=phase_unwrap(ISSdata.Data.Phase,ISSdata.Distances',data(iFile).Fm);
            d=ISSdata.Data.AC.*(cos(ISSdata.Data.Phase)+1i*sin(ISSdata.Data.Phase));
            data(iFile).data=d';
            data(iFile).data=[data(iFile).data ISSdata.Data.DC'];
            
            probe.link=[probe.link; probe.link];
            
            %aux data
                a=ISSdata.Data.Aux';
              
                for i=1:size(a,2)
                    name{i,1}=['aux-' num2str(i)];
                end
                aux=nirs.core.GenericData(a,ISSdata.Data.time,table(name,repmat({'aux'},length(name),1),'VariableNames',{'name','type'}));
                aux.description=data(iFile).description;
                data(iFile).auxillary('aux')=aux;
               
               for i=1:size(ml,1)
                    ISSdata.CalibrationValues.WF;
                    WF.Term(i,1)=ISSdata.CalibrationValues.WF.Term(ml(i,2),ml(i,1));
                    WF.Factor(i,1)=ISSdata.CalibrationValues.WF.Factor(ml(i,2),ml(i,1));
                    
               end
                WF.Term(lst)=[];
                WF.Factor(lst)=[];
                
                WF.Term=[WF.Term; WF.Term];
                WF.Factor=[WF.Factor; WF.Factor];
                               
                data(iFile).auxillary('calibration')=WF;
                
                data(iFile).auxillary('ISS Aquistion Info')=ISSdata.ACQinfo;
                
                ModFreq=ones(height(probe.link),1)*110;  % hardcoded 110Hz for ISS Boxy

                ModFreq(end/2+1:end)=0;
                probe.link=[probe.link table(ModFreq)];                
                
                
                if(isfield(SD,'MeasGroup'))
                    Group=zeros(height(probe.link),1);
                    for i=1:height(probe.link)
                        Group(i,1)=SD.MeasGroup(find(SD.MeasList(:,1)==probe.link.source(i) & SD.MeasList(:,2)==probe.link.detector(i)));
                    end
                    probe.link=[probe.link table(Group,'VariableNames',{'MeasurementGroup'})];
                end
                
                probe.link=[probe.link table(WF.Term,WF.Factor,true(size(WF.Term)),'VariableNames',{'Calibration_Term','Calibration_Factor','Calibration_Applied'})];
                
                data(iFile).probe=probe;
               
        catch err
            if(~exist('ISSdata') || ~isfield(ISSdata,'Data') || isempty(ISSdata.Data))
                 disp('Empty file found (skipping):');
                 disp(filenames{iFile});
            else
                warning(err.message)
            end
            
        end
        
        
    end

return


