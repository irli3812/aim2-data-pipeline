classdef Data
    %% DATA - Holds EEG data.
    % 
    % Properties: 
    %     description  - description of data (e.g. filename)
    %     data         - ntime x nchan array of NIRS data
    %     probe        - a Probe object containing measurement geometry
    %     time         - a vector containing the time
    %     Fs           - sampling frequency
    %     stimulus     - a Dictionary object containing stimulus info
    %                    (e.g. stimulus('tapping') returns a StimulusEvents Object)
    %     demographics - a Dictionary object containing demographics info
    %                    (e.g. demographics('age') returns 28)
    % 
    %     
    %  Methods:
    %     draw - displays the time series data and stimulus timings
    
    properties
        description
        data               % channel time series in columns
        probe;             % object describing geometry
        time               % vector of time points
        stimulus        = Dictionary();	% struct containing stim vectors (vectors, names, types)
        demographics    = Dictionary();	% table containing demographics (names, values)
    end
    
    properties( Dependent = true )
        Fs = 0;             % sampling frequency in Hz
    end

    methods
        function obj = Data( data, time, probe, stimulus, demographics, description )
            %% Data - Creates a Data object.
            % 
            % Args:
            %     data         - (optional) ntime x nchan array of NIRS data
            %     time         - (optional) a vector containing the time
            %     probe        - (optional) a Probe object containing measurement geometry
            %     Fm           - (optional) modulation frequency (0 for CW NIRS)
            %     stimulus     - (optional) a Dictionary object containing stimulus info
            %     demographics - (optional) a Dictionary object containing demographics info
            %     description  - (optional) description of data (e.g. filename)

            if nargin > 0, obj.data         = data;         end
            if nargin > 1, obj.time         = time;         end
            if nargin > 2, obj.probe        = probe;        end
            if nargin > 3, obj.stimulus     = stimulus;     end
            if nargin > 4, obj.demographics = demographics; end
            if nargin > 5, obj.description  = description;  end
        end
        
        function obj = set.stimulus( obj, stim )
           assert( isa(stim,'Dictionary') )
           obj.stimulus = stim;
        end
        
        function obj = set.demographics( obj, demo )
           assert( isa(demo,'Dictionary') )
           obj.demographics = demo;
        end
        
        function obj = set.time( obj, time )
           assert( isvector(time) )
           obj.time = time(:);
        end
        
        function out = get.Fs( obj )
            if length(obj.time) > 1
                out = 1 / ( obj.time(2) - obj.time(1) );
            else
                out = NaN;
            end
        end
        
        function out = sorted( obj, colsToSortBy )
            %% returns sorted channels of data by column in probe.link
            out = obj;
            if nargin < 2
                colsToSortBy = {'electrode', 'type'};
            end
            if(length(obj)>1)
                for idx=1:length(obj)
                    out(idx)=sorted(obj(idx),colsToSortBy );
                end
                return
            end
            [out.probe.link, idx] = sortrows(out.probe.link, colsToSortBy);
            out.data = out.data(:,idx);
        end
        
        function varargout=draw( obj, lstChannels )
            %% draw - Plots the probe geometry.
            % 
            % Args:
            %     lstChannels - list of channels to show
             if nargin == 1
                lstChannels = 1:size(obj(1).data,2);
            end
            if(isempty(lstChannels))
                % draw a plot, but then turn it off to only show the stim
                % marks
                lstChannels=1;
                showplot=false;
            else
                showplot=true;
            end
            if(isempty(obj(1).data))
                lstChannels=[];
            end
            
            
            if(length(obj)>1)
                figure;
                a=round(sqrt(length(obj)));
                b=ceil(sqrt(length(obj)));
                for i=1:length(obj)
                    subplot(a,b,i);
                    obj(i).draw(lstChannels);
                    legend off;
                end
                return
            end
            
            t = obj.time;
            d = obj.data(:,lstChannels);
            
            % get stim vecs
            s = []; k = obj.stimulus.keys;
            for i = 1:length( obj.stimulus.keys )
                s = [s obj.stimulus.values{i}.getStimVector( t )];
            end
            

            % plots
            gca; hold on;
            
            % data min/max/size
            dmax = max( d(:) );
            dmin = min( d(:) );
            dsize = (dmax-dmin);
            
            % plot stim blocks if available
            if ~isempty(s) 
                s=s./(ones(size(s,1),1)*mad(s));
                % min/max of axes
                pmin = dmin - 0.3*dsize;
                pmax = dmax + 0.2*dsize;

                % adjust amplitude so stims are visible
                s = 0.15*dsize*s + dmin - 0.25*dsize;
                
                % plot
                plot( t, s, 'LineWidth', 3 );
                
                % legend
                l = legend(k{:});
                set(l,'Interpreter', 'none');
            else
                % min/max of axes
               	pmin = dmin - 0.1*dsize;
                pmax = dmax + 0.1*dsize;
            end
            
            % plot data
            h=plot( t, d );
            
            if(~showplot)
                set(h,'visible','off');
            end
            xlabel( 'seconds' );
            
            % axes limits
            xlim( [min(t) max(t)] );
            if pmin == pmax
                ylim(pmin + [-1 1]);
            else
                ylim( [pmin pmax] );
            end
            
            if(nargout>0)
                varargout{1}=h;
            end
          
        end
        
    end
end

