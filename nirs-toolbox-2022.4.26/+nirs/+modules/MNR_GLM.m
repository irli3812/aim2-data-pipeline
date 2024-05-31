classdef MNR_GLM < nirs.modules.AbstractGLM
%% multinomial regression model..
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
        formula='Y~cond';
        within_variables=[];
        FitMethod='REML';
     end
    
     
    methods
        function obj = MNR_GLM( prevJob )
            if nargin > 0, obj.prevJob = prevJob; end
            
            obj.name = 'GLM with repeated measurements model';
            obj.basis('default') = nirs.design.basis.Canonical();
%             obj.citation=['Barker, Jeffrey W., Ardalan Aarabi, and Theodore J. Huppert.'...
%                 '"Autoregressive model based algorithm for correcting motion and serially '...
%                 'correlated errors in fNIRS." Biomedical optics express 4.8 (2013): 1366-1379.'];
            
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
                    if(~ismember('source',probe.link.Properties.VariableNames) & ...
                    ismember('ROI',probe.link.Properties.VariableNames))
                        [probe.link, idx] = nirs.util.sortrows(probe.link, {'ROI','type'});
                    else
                        [probe.link, idx] = nirs.util.sortrows(probe.link, {'source', 'detector','type'});
                    end
                elseif(~isempty(strfind(class(probe),'eeg')))
                    [probe.link, idx] = nirs.util.sortrows(probe.link, {'electrode','type'});
                else
                    error('data type not supported');
                end
                
                d = d(:, idx);
                % get experiment design
              
                [X, names, offset,metadata] = nirs.design. ...
                        createDesignMatrixRM(data(i).stimulus,data(i).time, obj.basis );
                C = obj.getTrendMatrix( t );
                
               
                tbl=metadata;
                str='(';
               
                for j=1:length(names)
                    str=[str names{j} '+'];
                   
                end
                str=[str(1:end-1) ')'];
              
                if(istable(X))
                    tbl=[tbl X];
                else
                    for j=1:length(names)
                        tbl.(names{j})=X(:,j);
                        
                    end
                end
                
                formula=obj.formula;
                if(~isempty(strfind(formula,'cond')))
                    formula=[formula(1:strfind(formula,'cond')-1) str formula(strfind(formula,'cond')+4:end)];
                end
               
          
                
                tbl=remove_unrepresented_levels(tbl);
                
                lst=[];
                for ii=1:length(tbl.Properties.VariableNames)
                    for jj=1:height(tbl)
                        if(iscell(tbl.(tbl.Properties.VariableNames{ii})(jj)) && ...
                                isempty(tbl.(tbl.Properties.VariableNames{ii}){jj}))
                            lst=[lst; jj];
                        end
                    end
                end
                lst=unique(lst);
                
                % add a few more fields to allow more options on the
                % formula
                tbl.time=data(i).time;
                tbl(lst,:)=[];
                
                clear Beta Cov stats;    
                for chIdx=1:size(d,2)
                    dd=d(:,chIdx);
                    dd(lst)=[];
                    tbl.Y=dd;
                    if(strcmp(obj.FitMethod,'Repeatedmeas'))
                        r{chIdx}=nirs.math.fitrm(tbl,formula,1,4*data(i).Fs);
                        [Beta(chIdx,:),Cov(:,:,chIdx),stats]=r{chIdx}.stats;
                         names=r{chIdx}.Coefficients.Row; %(2:end);
                    else
                        
                       % r{chIdx}=nirs.math.fitlme_AR(tbl,formula,4*data(i).Fs,'DummyVarCoding','full','FitMethod',obj.FitMethod);
                        r{chIdx}=fitlme(tbl,formula,'DummyVarCoding','full','FitMethod',obj.FitMethod);
                        Beta(chIdx,:)=r{chIdx}.Coefficients.Estimate;
                        Cov(:,:,chIdx)=r{chIdx}.CoefficientCovariance;
                        stats.dfe(chIdx)=r{chIdx}.DFE;
                        names=r{chIdx}.CoefficientNames;
                    end
                end
                %stats.dfe=min(stats.dfe);      
                
                
%                 resid=zeros(size(d));
%                 for chIdx=1:size(d,2)
%                     resid(:,chIdx)=r{chIdx}.residuals;
%                 end
%                 CC=nirs.math.robust_corrcoef(resid);
%                 COV=zeros(size(Cov,1),size(Cov,1),size(d,2),size(d,2));
%                 for ii=1:size(d,2)
%                     for jj=1:size(d,2)
%                         COV(:,:,ii,jj)=1/2*CC(ii,jj)*(Cov(:,:,ii)+Cov(:,:,jj));
%                     end
%                 end
%                 Cov=COV;
                
                 for ii=1:length(names)
                     names{ii}(strfind(names{ii},'('))=[];
                     names{ii}(strfind(names{ii},' '))=[];
                     names{ii}(strfind(names{ii},')'))=[];
                 end
                 names=matlab.lang.makeValidName(names);
                 
                %% TODO
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
                S(i).beta = vec(Beta);
                
                
                covb = zeros( nchan*ncond );
                if(ndims(Cov)==4)
                    for j = 1:nchan
                        for k=1:nchan
                            idx = (0:ncond-1)*nchan + j;
                            idx2 = (0:ncond-1)*nchan + k;
                            covb(idx, idx2) = Cov(1:ncond, 1:ncond, j,k);
                        end
                    end
                elseif(ndims(Cov)==3)
                    for j = 1:nchan
                        idx = (0:ncond-1)*nchan + j;
                        covb(idx, idx) = Cov(1:ncond, 1:ncond, j);
                        
                    end
                else
                    covb = Cov(1:ncond*nchan,1:ncond*nchan);
                end
                
                %ensure positive/definant (sometimes off due to numerical
                %prec.
             
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

function tbl=remove_unrepresented_levels(tbl)

vars=tbl.Properties.VariableNames;
for i=1:length(vars)
    if(isa(tbl.(vars{i}),'ordinal'))
        tbl.(vars{i})=droplevels(tbl.(vars{i}));
    elseif(isa(tbl.(vars{i}),'categorical'))
        tbl.(vars{i})=removecats(tbl.(vars{i}));
        
    end
end

end

