function meas = measurement( obj )
%MEASUREMENT Summary of this function goes here
%   Detailed explanation goes here

% TODO change fft to properly due a dtft
% for now, choose proper timeStep
fbin = obj.Fm*1e6 * obj.timeStep * obj.nTimeGates;
assert( fbin - fix(fbin) < 1e-9 )
fbin = fix(fbin);

% get a probe in proper format
probe = obj.probe;

% either simulate all dets once or all sources once
% swap if their are less dets than srcs
if size( probe.detPos,1 ) < size( probe.srcPos,1 )
    probe = probe.swapSD();
end

% copy fwdModel object with proper probe
thisObj = obj;
thisObj.probe = probe;


% preallocation
data = complex( zeros(1,size(probe.link,1),'single') );

for itype=unique(probe.link.type)'
    % for each source compute flux
    for iSrc = 1:size(probe.srcPos,1)
        cfg = thisObj.getConfig( [iSrc itype],'source');
        cfg=rmfield(cfg,'detpos');
        cfg.method='grid';
        cfg.srctype='pencil';
        cfg=mmclab(cfg,'prep');
        tic,
        flux = mmclab(cfg); % stupid way to suppress mcxlab output
        for iRep = 2:obj.nRepetitions
            [tmp] = mmclab(cfg)
            flux.data = (iRep-1)/iRep * flux.data + tmp.data/iRep;
        end
        t = toc;
        disp(['Completed forward model for source ' num2str(iSrc) '(' num2str(itype) ') of ' num2str(size(probe.srcPos,1)) ' in ' num2str(t) ' seconds.'])
        
        flux.data = flux.data/thisObj.nPhotons; %/obj.image.dim(1)^3;
        flux.data = fft( flux.data,[],4 );
        
        fluence = flux.data(:,:,:,fbin+1);
        
        lst = find( probe.link.source == iSrc & probe.link.type==itype);
        
        DMMC_AABB_origin=min(cfg.node); %spatial offset of the DMMC AABB
        DMMC_voxel_origin=DMMC_AABB_origin+0.5; %centroid of the 1st voxel for DMMC AABB
        DMMC_AABB_dimension=size(fluence);
        [yy,xx,zz]=meshgrid(DMMC_voxel_origin(1,2):(DMMC_voxel_origin(1,2)+DMMC_AABB_dimension(1,2)-1),...
            DMMC_voxel_origin(1,1):(DMMC_voxel_origin(1,1)+DMMC_AABB_dimension(1,1)-1),...
            DMMC_voxel_origin(1,3):(DMMC_voxel_origin(1,3)+DMMC_AABB_dimension(1,3)-1));
        
        pos = probe.detPos( probe.link.detector(lst),:);
        k=dsearchn([xx(:) yy(:) zz(:)],pos);
        
        
        
        %         thisR = nirs.utilities.quad_interp(pos,real(log(fluence)),3);
        %         thisI = nirs.utilities.quad_interp(pos,imag(log(fluence)),3);
        %         pos = fix(pos);
        %         data(lst) = fluence( sub2ind(size(fluence),pos(:,1),pos(:,2),pos(:,3)) );
        data(lst) = fluence(k);
        
    end
end
meas = nirs.core.Data( data, 0,obj.probe,  obj.Fm);

end

