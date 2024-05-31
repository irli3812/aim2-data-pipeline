classdef AR_IRLS_MixedEffects < nirs.modules.AbstractGLM
%% AR_IRLS - Performs first-level per file GLM analysis.
% 
% Options:
%     basis       - a Dictionary object containing temporal bases using stim name as key
%     verbose     - flag to display progress
%     trend_func  - a function that takes in a time vector and returns trend regressors
%     
% Example:
%     j = nirs.modules.AR_IRLS();
%     
%     b = Dictionary();
%     b('default') = nirs.design.basis.Canonical(); % default basis
%     b('A')       = nirs.design.basis.Gamma();     % a different basis for condition 'A'
%     
%     j.basis = b;
%     
%     j.trend_func = @(t) nirs.design.trend.legendre(t, 3); % 3rd order polynomial for trend
%     
% Note: 
%     trend_func must at least return a constant term unless all baseline periods are
%     specified explicitly in the stimulus design with BoxCar basis functions
    properties
        ListofEffects;
    end
    methods
        function obj = AR_IRLS_MixedEffects( prevJob )
            if nargin > 0, obj.prevJob = prevJob; end
            
            obj.name = 'GLM via AR(P)-IRLS';
            obj.basis('default') = nirs.design.basis.Canonical();
            obj.citation=['Barker, Jeffrey W., Ardalan Aarabi, and Theodore J. Huppert.'...
                '"Autoregressive model based algorithm for correcting motion and serially '...
                'correlated errors in fNIRS." Biomedical optics express 4.8 (2013): 1366-1379.'];
            obj.ListofEffects={'trends','short-seperation','derivatives'};
                
        end
        
        function S = runThis( obj, data )
            vec = @(x) x(:);
            
            for i = 1:numel(data)
                % get data
                d  = data(i).data;
                t  = data(i).time;
                Fs = data(i).Fs;
                
                probe = data(i).probe;
                
                % make sure data is in order
                
                if(~isempty(strfind(class(probe),'nirs')))
                    [probe.link, idx] = nirs.util.sortrows(probe.link, {'source', 'detector','type'});
                elseif(~isempty(strfind(class(probe),'eeg')))
                    [probe.link, idx] = nirs.util.sortrows(probe.link, {'electrode','type'});
                else
                    error('data type not supported');
                end
                    d = d(:, idx);
                
                % get experiment design
                [X, names] = obj.createX( data(i) );
                C = obj.getTrendMatrix( t );
                
                X(find(isnan(X)))=0;
                
                % check model
                obj.checkRank( [X C] )
                obj.checkCondition( [X C] )
                
                isRE=zeros(size(X,2)+size(C,2),1);
                if(ismember('trends',obj.ListofEffects));
                    isRE(size(X,2)+1:end)=1;
                end
                isRE(end)=0; % don't include the DC term in this
                if(ismember('short-seperation',obj.ListofEffects));
                    for ii=1:size(data(1).data,2)
                        lst{ii}=['SS_PCA' num2str(ii)];
                    end
                    
                    isRE(ismember(names,lst))=2;
                end
                
                
%                 if(rank([X C]) < size([X C],2) & obj.goforit)
%                     disp('Using PCA regression model');
%                     [U,s,V]=nirs.math.mysvd([X C]);
%                     lst=find(diag(s)>eps(1)*10);
%                     V=V(:,lst);
%                     stats = nirs.math.ar_irls( d, U(:,lst)*s(lst,lst), round(4*Fs) );
%                     stats.beta=V*stats.beta;
%                     for j=1:size(stats.covb,3)
%                         c(:,:,j)=V*squeeze(stats.covb(:,:,j))*V';
%                     end
%                     stats.covb=c;
%                 else
                
                    % run regression
                    stats = nirs.math.ar_irls_priors( d, [X C],isRE,round(4*Fs),4.685,probe.link.type );
                %end
                
                % put stats
                ncond = length(names);
                nchan = size(data(i).probe.link, 1);
                
                link = repmat( probe.link, [ncond 1] );
                cond = repmat(names(:)', [nchan 1]);
                cond = cond(:);
               
                if(~isempty(strfind(class(probe),'nirs')))
                    S(i) = nirs.core.ChannelStats();
                elseif(~isempty(strfind(class(probe),'eeg')))
                    S(i) = eeg.core.ChannelStats();
                else
                    warning('unsupported data type');
                    S(i) = nirs.core.ChannelStats();
                end
                S(i).variables = [link table(cond)];
                S(i).beta = vec( stats.beta(1:ncond,:)' );
                
                covb = zeros( nchan*ncond );
                for j = 1:nchan
                   idx = (0:ncond-1)*nchan + j;
                   covb(idx, idx) = stats.covb(1:ncond, 1:ncond, j);
                end
                
                S(i).covb = covb;
                
                S(i).dfe  = stats.dfe(1);
                
                S(i).description = data(i).description;
                
                S(i).demographics   = data(i).demographics;
                S(i).probe          = probe;
                
                stim=Dictionary;
                for j=1:data(i).stimulus.count;
                    ss=data(i).stimulus.values{j};
                    if(isa(ss,'nirs.design.StimulusEvents'))
                        s=nirs.design.StimulusEvents;
                        s.name=ss.name;
                        s.dur=mean(ss.dur);
                        stim(data(i).stimulus.keys{j})=s;
                    end
                end
                
                S(i).basis.base=obj.basis;
                S(i).basis.Fs=Fs;
                S(i).basis.stim=stim;
                
                % print progress
                if(obj.verbose)
                 obj.printProgress( i, length(data) )
                end
            end

        end
        
        
        function prop = javaoptions(obj)
            
            prop=javaoptions@nirs.modules.AbstractGLM(obj);
            opts=obj.options;
            
            diction=nirs.util.createDictionaryFromToolset('nirs.design.basis');
            DictionaryProp=javatypes('enum',{diction.values});
            set(DictionaryProp,'Name','basis','Value','test');
            set(DictionaryProp,'Category','Misc');
            set(DictionaryProp,'Description','Select the canonical basic function');
            prop(find(ismember(opts,'basis')))=DictionaryProp;
            
            
            
            
        end
        
    end
    
end

