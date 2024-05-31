classdef connectivity_GLM < nirs.modules.AbstractGLM
    %% GLM- this is a wrapper for the OLS, AR-IRLS, and SPM-NIRS regression programs%
    %
    % Options:
    %     basis       - a Dictionary object containing temporal bases using stim name as key
    %     verbose     - flag to display progress
    %     trend_func  - a function that takes in a time vector and returns trend regressors
    %     type        - {OLS, NIRS-SPM, or [AR-IRLS]}
    % Example:
    %     j = nirs.modules.GLM();
    %     j.type = 'AR-IRLS';
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
        type;
        AddShortSepRegressors = false;
        options;
    end
    methods
        function obj = connectivity_GLM( prevJob )
            if nargin > 0, obj.prevJob = prevJob; end
            
            obj.name = 'GLM model';
            obj.basis('default') = nirs.design.basis.Canonical();
            obj.type='AR-IRLS';
            obj.options=[];
        end
        
        function obj = set.type(obj,type)
            validtypes={'OLS','NIRS-SPM','AR-IRLS','MV-GLM','Nonlinear','Ordinal','RepeatedMeasures'};
            if(~ismember(type,validtypes))
                disp('type must be one of : ')
                disp(strvcat(validtypes));
                return;
            else
                obj.type=type;
            end
            % use the call functions to evoke any special messages or
            % conditions (e.g. NIRS-SPM checks for code in path);
            switch(obj.type)
                case('OLS')
                    j=nirs.modules.OLS();
                case('AR-IRLS');
                    j=nirs.modules.AR_IRLS();
                case('NIRS-SPM')
                    j=nirs.modules.NIRS_SPM_GLM();
                case('MV-GLM')
                    j=nirs.modules.MultiVarGLM();
                    disp(['Note: Inputs expected to be optical density']);
                case('Nonlinear')
                    j=nirs.modules.nonlin_GLM();
                    obj.basis=j.basis;
                case('Ordinal')
                    j=nirs.modules.MMR_GLM();
                case('RepeatedMeasures')
                    j=nirs.modules.repeatedMeas_GLM();
                otherwise
                    error('type not recognized');
            end
            obj.citation=j.citation;
            obj.options=[];
            pj=obj.prevJob;
            flds=fields(j);
            lst=find(ismember(flds,fields(obj)));
            for i=1:length(lst)
                obj.(flds{lst(i)})=j.(flds{lst(i)});
            end
            lst=find(~ismember(flds,fields(obj)));
            for i=1:length(lst)
                obj.options=setfield(obj.options,flds{lst(i)},j.(flds{lst(i)}));
            end
            obj.prevJob=pj;
        end
        
        function S = runThis( obj, data )
            
            if (obj.AddShortSepRegressors)
                
                j=nirs.modules.AddShortSeperationRegressors();
                j=nirs.modules.RemoveShortSeperations(j);
            else
                j=nirs.modules.Assert;
                j.condition=@(data)isa(data,'nirs.core.Data');
            end
            
            switch(obj.type)
                case('OLS')
                    j=nirs.modules.OLS(j);
                case('AR-IRLS');
                    j=nirs.modules.AR_IRLS(j);
                case('NIRS-SPM')
                    j=nirs.modules.NIRS_SPM_GLM(j);
                case('MV-GLM')
                    j=nirs.modules.MultiVarGLM(j);
                case('Nonlinear')
                    j=nirs.modules.nonlin_GLM(j);
                case('Ordinal')
                    j=nirs.modules.MMR_GLM(j);
                case('RepeatedMeasures')
                    j=nirs.modules.repeatedMeas_GLM(j);
                otherwise
                    error('type not recognized');
            end
            j.basis=obj.basis;
            j.verbose=obj.verbose;
            j.trend_func=obj.trend_func;
            j.goforit=obj.goforit;
            
            
            if(~isempty(obj.options))
                flds=fields(obj.options);
                for i=1:length(flds)
                    j.(flds{i})=obj.options.(flds{i});
                end
            end
            
            
            if (obj.AddShortSepRegressors)
                Stim=unique(nirs.getStimNames(data));
                for ii=1:length(Stim)
                    Stim{ii}=[Stim{ii} '*'];
                end
                
                j=nirs.modules.KeepStims(j);
                j.regex=true;
                j.listOfStims=Stim;
            end
            
           
            for i=1:length(data)
                cnt=1;
                link=struct;
                dd=zeros(size(data(i).data,1),size(data(i).data,2)*(size(data(i).data,2)-1)/2+size(data(i).data,2));
                for a=1:size(data(i).data,2) 
                    for b=a:size(data(i).data,2)
                        dd(:,cnt)=data(i).data(:,a).*data(i).data(:,b);
                        link.source{cnt,1}=['src-' num2str(data(i).probe.link.source(a)) ':' ...
                            'det-' num2str(data(i).probe.link.detector(a))];
                        link.detector{cnt,1}=['src-' num2str(data(i).probe.link.source(b)) ':' ...
                            'det-' num2str(data(i).probe.link.detector(b))];
                        link.type{cnt,1}=[num2str(data(i).probe.link.type(a)) '-' ...
                            num2str(data(i).probe.link.type(b))];
                        cnt=cnt+1; 
                    end; 
                end;
                data2(i)=data(i);
                data2(i).data=dd;
                data2(i).probe.link=struct2table(link);
            end
            
            
            S=j.run(data2);
            
            
            for idx=1:length(S)
                [~,Stim]=nirs.design.createDesignMatrix(data(idx).stimulus,data(idx).time,obj.basis);
                StimNew=unique(nirs.getStimNames(S(idx)));
                
                lst=[]; lst2=[];
                for j=1:length(Stim)
                    ss=Stim{j};
                    if(~isempty(strfind(ss,':')))
                        ss(strfind(ss,':'):end)=[];
                    end
                    
                    st=data(idx).stimulus(ss);
                    if(~ismember('regressor_no_interest',fields(st)))
                        lst=[lst j];
                    else
                        if(~st.regressor_no_interest)
                            
                            lst=[lst j];
                        else
                            lst2=[lst2 j];
                        end
                    end
                end
                StimRm={Stim{lst2}};
                Stim={Stim{lst}};
                
                SS={};
                for i=1:length(StimNew)
                    for j=1:length(Stim)
                        if(~isempty(ismember(StimNew{i},Stim{j},'rows')) & ...
                                isempty(strfind(StimNew{i},'SS_PCA')) & ...
                                ~ismember(StimNew{i},StimRm))
                            SS{end+1}=StimNew{i};
                        end
                    end
                end
                SS=unique(SS);
                for ii=1:length(SS)
                    SS{ii}=[SS{ii} '*'];
                end
                
                j=nirs.modules.KeepStims;
                j.listOfStims=SS;
                j.regex=true;
                S(idx)=j.run(S(idx));
            end
            
            
            
            
            
            
        end
        
    end
    
end

