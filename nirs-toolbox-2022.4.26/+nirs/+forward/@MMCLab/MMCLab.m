classdef MMCLab
    %MMCFWDMODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    
    properties
       probe;
       prop;
       mesh; 
        directory = [getenv('TMPDIR') filesep 'tmp'...
            filesep num2str(randi(2^32-1))];

        Fm =0;
        
        nPhotons = 1e8;
        nTimeGates = 40;
        timeStep = 1/100e6/300;
        nRepetitions = 1;
      
    end
    
    properties(SetAccess = private)
        nLayers;
        cleanup = true;
    end
    
    methods
        %% Constructor
        function obj = MMCLab(mesh, prop, probe, Fm )
            if nargin > 0, obj.mesh = mesh; end
            if nargin > 1, obj.prop = prop; end
            if nargin > 2, obj.probe = probe; end
            if nargin > 3, obj.Fm = Fm; end
        end
        
        %% Set/Get
        function obj = set.probe(obj,probe)
            if(~isa(probe,'nirs.core.Probe1020'))
                warning('probe must be a 3D registered probe');
            end
            if(all(probe.optodes.Z==0) & isa(probe,'nirs.core.Probe1020'))
                disp('warning: changing probe to 3D using "swap_reg" function');
                probe=probe.swap_reg;
            end
            obj.probe=probe;
        end
        
        
        function obj = set.directory( obj, d )
            assert( ischar( d ) )
            obj.directory = d;
            obj.cleanup = false;
        end
        
        %% Methods
        saveFluence( obj );
        meas = measurement( obj );
        meas = timeResolvedMeas( obj );
        [J,meas] = jacobian( obj,type );
        cfg = getConfig( obj, idx, idxType );
        
    end
    

        
end

