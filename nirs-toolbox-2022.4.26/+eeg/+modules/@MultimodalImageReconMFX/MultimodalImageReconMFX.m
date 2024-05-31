classdef MultimodalImageReconMFX < nirs.modules.AbstractModule
    % This is the (ReML) linear mixed effects image reconstruction model for
    % multimodal data. 
    % This model preforms single-subject or group-level image
    % reconstruction using ReML
    
    properties
        formula = 'beta ~ cond*group + (1|subject)';
        jacobian = Dictionary(); % key is subject name or "default"
        dummyCoding = 'full';
        centerVars=false
        
        basis;  % Basis set from nirs.inverse.basis
        mask = [];   % Mask (e.g. cortical contraint)
        prior = Dictionary();  % The prior on the image; default = 0 (Min Norm Estimate)
        mesh;  % Reconstruction mesh (needed to create the ImageStats Class)
        probe = Dictionary();  % This is the probe for the Jacobian model.  These needs to match the jacobian
    end
    
    methods
        
        function obj = MultimodalImageReconMFX( prevJob )
            obj.name = 'Multimodal Image Recon w/ Random Effects';
            if nargin > 0
                obj.prevJob = prevJob;
            end
            
            nVox=20484;
            obj.basis=nirs.inverse.basis.identity(nVox);
            
            obj.prior('default')=zeros(nVox,1);
            
        end
        
        function G = runThis( obj,S )
            
            if(~iscell(S))
                S={S};
            end
            
%            Convert all the data into a common data type
            SS=struct('variables',[],'beta',[],'covb',[],...
                'probe',[],'conditions',{},'demographics',Dictionary);
            SS(:)=[];
            cnt=1;
            %Make sure the probe and data link match
            RescaleData=NaN;
            for j=1:length(S)
                for idx=1:length(S{j})
                    if(~S{j}(idx).demographics.iskey('subject'))
                        S{j}(idx).demographics('subject')='default';
                    end
                    
                    sname=S{j}(idx).demographics('subject');
                    if(isempty(sname))
                        S{j}(idx).demographics('subject')='default';
                        sname='default';
                    end
                    modality=class(S{j});
                    modality=modality(1:min(strfind(modality,'.')-1));
                    S{j}(idx).demographics('modality')=modality;
                    ModalityName{j}=modality;
                    sname=[sname ':' modality];
                    S{j}(idx).demographics('subject')=sname;
                    
                    key=sname;
                    
                    SS(cnt).demographics=S{j}(idx).demographics;
                    SS(cnt).conditions=S{j}(idx).conditions;
                    SS(cnt).demographics('modality')=modality;
                    SS(cnt).variables=S{j}(idx).variables;
                    SS(cnt).beta=S{j}(idx).beta;
                    SS(cnt).covb=S{j}(idx).covb;
                    SS(cnt).probe=S{j}(idx).probe;
                    
                    RescaleData(cnt,j)=normest(SS(cnt).beta);              
                    cnt=cnt+1;
                    
                end
            end
            S=SS;
            clear SS;
            RescaleData(RescaleData==0)=NaN;
            ModalityRescale=nanmedian(RescaleData,1)*100;
            
            
            rescale=(10*length(unique(nirs.getStimNames(S)))*length(S))/length(ModalityRescale);
            
            % demographics info
            demo = nirs.createDemographicsTable( S );
            if(isempty(demo))
                for idx=1:length(S);
                    S(idx).demographics('subject')='default';
                end
            end
            if(~ismember(demo.Properties.VariableNames,'subject'));
                for idx=1:length(S);
                    S(idx).demographics('subject')='default';
                end
            end
            
            
            % center numeric variables
            if obj.centerVars
                n = demo.Properties.VariableNames;
                for i = 1:length(n)
                    if all( isnumeric( demo.(n{i}) ) )
                        demo.(n{i}) = demo.(n{i}) - mean( demo.(n{i}) );
                    end
                end
            end
            
            
            % Mask of the reconstruction volume
            if(~isempty(obj.mask))
               LstInMask=find(obj.mask);
            else
               LstInMask=1:size(obj.basis.fwd,1);
            end
                        
            %% Wavelet ( or other tranform )
            Basis = obj.basis.fwd; % W = W(1:2562,:);
            
            %Let's make the forward models
            L = obj.jacobian;
            Lfwdmodels=Dictionary();
            Probes=Dictionary();
            
            fldsAll={};
            for i = 1:L.count
                key = L.keys{i};
                if(ismember(key,nirs.createDemographicsTable(S).subject))
                J =L(key);
                flds=fields(J);
                fldsAll={fldsAll{:} flds{:}};
                if(~ismember(key,obj.probe.keys))
                     Probes(key)=obj.probe('default');
                else
                     Probes(key)=obj.probe(key);
                end
                l=[];
                for j=1:length(flds)
                    l=setfield(l,flds{j},(J.(flds{j})(:,LstInMask).*(J.(flds{j})(:,LstInMask)>10*eps(1)))*...
                        Basis(LstInMask,:));
                end
                Lfwdmodels(key)=l;
                end
            end
            
            fldsAll=unique(fldsAll);
            
%             % Do a higher-order generalized SVD
             [US,V]=nirs.math.hogSVD(Lfwdmodels.values);
%             % [U1,U2...,V,S1,S2...]=gsvd(L1,L2,...);
%             % L1 = U1*S1*V'
%             % L2 = U2*S2*V'
%             
%             % Store back into the forward model
             Lfwdmodels.values=US;
            
            
            %Make sure the probe and data link match
            modltypes={};
            for idx=1:length(S)
                sname=S(idx).demographics('subject');
                if(ismember(sname,Lfwdmodels.keys))
                    key=sname;
                else
                    key=['default:' S(idx).demographics('modality')];
                end
                thisprobe=Probes(key);
                [ia,ib]=ismember(thisprobe.link,S(idx).probe.link,'rows');
                ibAll=[];
                for i=1:length(S(idx).conditions);
                    ibAll=[ibAll; ib+(length(ib)*(i-1))];
                end   
                S(idx).variables=S(idx).variables(ibAll,:);
                S(idx).beta=S(idx).beta(ibAll);
                S(idx).covb=S(idx).covb(ibAll,ibAll);
                S(idx).probe.link=S(idx).probe.link(ib,:);
                modltypes={modltypes{:} repmat({S(idx).demographics('modality')},length(S(idx).beta),1)};
            end
            modltypes=vertcat(modltypes{:});
            
            % FInd the initial noise weighting
            W=[];
            for i = 1:length(S)
%                 [u, s, ~] = svd(S(i).covb, 'econ');
%            %     W = [W; diag(1./diag(sqrt(s))) * u'];
%                 W = blkdiag(W,diag(1./diag(sqrt(s))) * u');
                  W=blkdiag(W,inv(chol(S(i).covb)));
            end
            lstBad=find(sum(abs(W),2)>100*median(sum(abs(W),2)));
            W(lstBad,:)=[];
            
            
            dWTW = sqrt(diag(W'*W));
            
            for i=1:length(fldsAll)
                if(ismember(fldsAll{i},{'hbo','hbr'}))
                    modl='nirs';
                elseif(ismember(fldsAll{i},{'eeg'}))
                    modl='eeg';
                else
                    error('fix this');
                end
                lst=ismember(modltypes,modl);
                 m(i)=median(dWTW(lst));
            end
            
         
            
            %% Let's compute the minimum detectable unit on beta so we
            % can compute the spatial type-II error
           
            X=[];
            vars = table();
            
            for i = 1:length(S)
                conds=unique(nirs.getStimNames(S(i)));
                [u, s, ~] = svd(S(i).covb, 'econ');
                W = diag(1./diag(sqrt(s))) * u';
                
                
                key = S(i).demographics('subject');
                if(~ismember(key,Lfwdmodels.keys))
                    key=['default:' S(i).demographics('modality')];
                end
                xx=[];
                
                for j=1:length(conds)
                    xlocal=[];
                    L=Lfwdmodels(key);
                    for fIdx=1:length(fldsAll)
                        if(isfield(L,fldsAll{fIdx}))
                            x2=L.(fldsAll{fIdx})*V';
                        else
                            x2=zeros(length(S(i).beta),size(V,1));
                        end
                        xlocal=[xlocal x2]; 
                
                    end
                    
                    xx=[xx; xlocal];
                end
                X=[X; W*xx];
            end
           
            lstBad=[]; %find(sum(abs(X),2) > 100*median(sum(abs(X),2)));
            X(lstBad,:)=[];
            
            n=size(X,2)/length(m);
            for i=1:length(m)
                scale(i) = norm(X(:,(i-1)/length(m)*n+1:i/length(m)*n))./m(i); 
            end
           
            n=size(X,2)/length(fldsAll);
            mm=reshape(repmat(m,n,1),[],1);
            for idx=1:size(X,2)
                x=X(:,idx);
                VarMDU(idx)=inv(x'*x+eps(1))/mm(idx)^2;
            end
           
           
              
            % The MDU is the variance at each voxel (still in the basis
            % space here) of the estimated value assuming all the power came
            % from only this voxel.  This is similar to the Rao-Cramer lower bound
            % and is used to define the smallest detectable change at that
            % voxel given the noise in the measurements
            % e.g. pval(typeII) = 2*tcdf(-abs(beta/sqrt(VarMDU+CovBeta)),dfe)
            
  
            demo = nirs.createDemographicsTable( S );
            
            
            
            % Now create the data for the model
            W = sparse([]);
            b = [];
            bLst=[];
            vars = table();
            tmpvars =table();
            for i = 1:length(S)
                % coefs
                b = [b; S(i).beta];
                bLst=[bLst; repmat(i,size(S(i).beta))];
                % whitening transform
                %[u, s, ~] = svd(S(i).covb, 'econ');
               % W = blkdiag(W, diag(1./diag(eps(1)+sqrt(s))) * u');
                 W = blkdiag(W,inv(chol(S(i).covb)));
                 
                % table of variables
                variables=S(i).variables;
                conds=unique(variables.cond);
                                
                for cIdx=1:length(conds)
                    variableLst = variables(find(ismember(variables.cond,conds{cIdx})),:);
                    
                    % Make sure we are concatinating like datatypes
                    if(~iscell(variableLst.type)); variableLst.type=arrayfun(@(x){num2str(x)},variableLst.type); end;
                    idx = repmat(i,height(variableLst),1);
                    variableLst =[table(idx) variableLst repmat(demo(i,:),height(variableLst),1)];
                    
%                    % lst=ismember( variableLst.DataType,'prior');
%                     variableLst.DataType=strcat(variableLst.DataType, variableLst.type);
%                     
                    
                    if(~ismember('electrode',variableLst.Properties.VariableNames))
                        variableLst=[variableLst table(nan(height(variableLst),1),'VariableNames',{'electrode'})];
                    end
                    if(~ismember('source',variableLst.Properties.VariableNames))
                        variableLst=[variableLst table(nan(height(variableLst),1),...
                            nan(height(variableLst),1),'VariableNames',{'source','detector'})];
                    end
                    
                    vars = [vars; variableLst];
                    tmpvars =[tmpvars; variableLst(1,:)];
                end
            end
            
           
            beta = randn(height(tmpvars),1);                     
                   
            nRE = length(strfind(obj.formula,'|'));
            
            
                        
            if(height(tmpvars)>1)
                %RUn a test to get the Fixed/Random matrices
                warning('off','stats:LinearMixedModel:IgnoreCovariancePattern');
                lm1 = fitlme([table(beta) tmpvars], obj.formula,'FitMethod', 'reml', 'CovariancePattern', repmat({'Isotropic'},nRE,1), 'dummyVarCoding',obj.dummyCoding);
                
                X = lm1.designMatrix('Fixed');
                Z = lm1.designMatrix('Random');
            else
                X=1;
                Z=[];
                lm1.CoefficientNames=cellstr(tmpvars.cond{1});
                lm1.designMatrix=Dictionary;
                lm1.designMatrix('Fixed')=X;
            end
               
            %Now, lets make the full model
            XFull=[];
            ZFull=[];
            
            for i=1:size(X,1)
                Xlocal=[];
                Zlocal=[];
                
                if(ismember('subject',tmpvars.Properties.VariableNames))
                    subname = tmpvars.subject{i};
                else
                    subname='default';
                end
                
                if(ismember(subname,Lfwdmodels.keys))
                    subname=subname;
                else
                   subname=['default:' tmpvars.modality(i,:)];
                end
                
                
                idx = tmpvars.idx(i);
                variables = S(idx).variables;
                thiscond = tmpvars.cond{i};
                variables = variables(find(ismember(variables.cond,thiscond)),:); 
                
                Llocal=[];
                L=Lfwdmodels(subname);
                for fIdx=1:length(fldsAll)
                        if(isfield(L,fldsAll{fIdx}))
                            x2=L.(fldsAll{fIdx})*V';
                        else
                            x2=zeros(length(S(i).beta),size(V,1));
                        end
                     
                    Llocal =[Llocal x2];
                end
              
                for j=1:size(X,2)
                    Xlocal=[Xlocal X(i,j)*Llocal];
                end              
                for j=1:size(Z,2)
                    Zlocal=[Zlocal Z(i,j)*ones(size(Llocal,1),1)];
                end
                
               
                XFull=[XFull; Xlocal];
                ZFull=[ZFull; Zlocal];               
            end
            
            
            

            
            if(isempty(ZFull)), ZFull=zeros(size(XFull,1),0); end;
            X=XFull;
            Z=ZFull;
            beta=b;
            
            %             %% put them back in the original order
            %             vars(ord,:) = vars;
            %             X(ord, :)   = X;
            %             Z(ord, :)   = Z;
            %             beta        = b; % already in correct order
            
            %% check weights
            dWTW = sqrt(diag(W'*W));
            m = median(dWTW);
            
            %W(dWTW > 100*m,:) = 0;
             utypes=unique(vars.type);
            lstBad=[];
            for iT=1:length(utypes)
                lst=ismember(vars.type,utypes{iT});
                m = median(dWTW(lst));
                
                %W(dWTW > 100*m,:) = 0;
                lstBad=[lstBad; find(dWTW(lst) > 100*m)];
            end
            
            W(lstBad,:)=[];
            W(:,lstBad)=[];
            X(lstBad,:)=[];
            Z(lstBad,:)=[];
            beta(lstBad,:)=[];
            
            %% Weight the model
            X    = W*X;
            Z    = W*Z;
            beta = W*beta;
%             
%             n=length(fldsAll);
%             m=size(X,2);
%             for i=1:n
%                 lst=[m*(i-1)/n+1:m*i/n];
%                 rescaleFwd(i)= norm(X(:,lst))/10;
%                 X(:,lst)=X(:,lst)/rescaleFwd(i);
%             end
            
            
            %Now deal with the ReML covariace terms

          
                   
            lstKeep = find(sum(abs(X),1)~=0);
            if(length(lstKeep)<size(X,2))
                warning('Some measurements have zero fluence in the forward model');
            end
            
           
            X=sparse(X);
            Z=sparse(Z);
            
            
            
                lstKeep = find(sum(abs(X),1)~=0);
            if(length(lstKeep)<size(X,2))
                warning('Some Src-Det pairs have zero fluence in the forward model');
            end
            
            X=sparse(X);
            Z=sparse(Z);
            
           
            
            VV=[];
            n=size(V,2);
            for i=1:length(fldsAll)
                N=[];
                for j=1:i-1
                    N=blkdiag(N,zeros(n));
                end
                N=blkdiag(N,V'*V);
                for j=i+1:length(fldsAll)
                    N=blkdiag(N,zeros(n));
                end
                VtV{i}=sparse(N);
                VV=blkdiag(VV,V);
            end
            
            
           
           
           ncond=length(lm1.CoefficientNames);
           n=size(VtV{1},1);
           cnt=1;
           for k=1:length(VtV)
               
               for i=1:ncond
                   Q{cnt}=[];
                   for j=1:i-1
                       Q{cnt}=blkdiag(Q{cnt},0*speye(n,n));
                   end
                   Q{cnt}=blkdiag(Q{cnt},VtV{k});
                   for j=i+1:ncond
                       Q{cnt}=blkdiag(Q{cnt},0*speye(n,n));
                   end
                   Q{cnt}=blkdiag(Q{cnt},0*speye(size(Z,2),size(Z,2)));
                   cnt=cnt+1;
               end
           end
            for i=1:size(Z,2)
                Q{end+1}=blkdiag(0*speye(size(X,2),size(X,2)),...
                    speye(size(Z,2),size(Z,2)));
                
            end
           % TODO-- off diagionals
           %     lst=find(ismember(names,{'priorhbo','priorhbr'}));
           
            R={speye(size(beta,1),size(beta,1))};
            

            Beta0= zeros(size(X,2)+size(Z,2),1);
          
            
            [lambda,Beta,Stats]=nirs.math.REML(beta,[X(:,lstKeep) Z]*VV(lstKeep,:),VV(lstKeep,:)'*Beta0(lstKeep),R,Q);
            lm2.CoefficientCovariance=Stats.tstat.covb;
            lm2.Coefficients.Estimate=Beta;
            dfe= Stats.tstat.dfe;
            
             %% fit the model
            %lm2 = fitlmematrix(X(:,lstKeep), beta, Z, [], ...
            %     'FitMethod', 'ReML');
            
            % Call my wrapper for the fitlmefunction
          %  lm2 = nirs.math.Remlfiflmematrix(X(:,lstKeep), beta, Z,PAT);
%             
%             
%             lm2 = fitlmematrix(X(:,lstKeep), beta, Z, [], ...
%                  'FitMethod', 'ReML');
%              
            
            CoefficientCovariance=lm2.CoefficientCovariance;
            
            G = nirs.core.ImageStats();
            G.description = ['Reconstructed model from: ' obj.formula];
            G.mesh = obj.mesh;
            G.probe = obj.probe.values{1};
            G.demographics = demo;
            
            %Sort the betas
            cnames = lm1.CoefficientNames(:);
              
           for idx=1:length(cnames); 
               cnames{idx}=cnames{idx}(min(strfind(cnames{idx},'_'))+1:end); 
               %if(cnames{idx}(1)=='_'); cnames{idx}(1)=[]; end; 
           end;
            
            %V=iW*V;
            Vall=[];
            iWall=[];
            for idx=1:length(cnames)
                for fIdx=1:length(fldsAll)
                    Vall=sparse(blkdiag(Vall,V));
                    iWall=sparse(blkdiag(iWall,obj.basis.fwd));
                end
            end
            V=iWall*Vall;
            G.beta=V*lm2.Coefficients.Estimate;
            [Uu,Su,Vu]=nirs.math.mysvd(CoefficientCovariance);
            
            G.covb_chol = V(lstKeep,:)*Uu*sqrt(Su);  % Note- SE = sqrt(sum(G.covb_chol.^2,2))
            
            G.dfe        = dfe;
            
           fwd=[];
           for idx=1:length(fldsAll)
               fwd=blkdiag(fwd,obj.basis.fwd);
           end
           fwd=sparse(fwd);
           
           G.typeII_StdE=1/eps(1)*ones(size(fwd,1),1);
           Lst=find(sum(abs(fwd),2)~=0);
           G.typeII_StdE(Lst) =fwd(Lst,:) * sqrt(VarMDU');
            
           G.typeII_StdE=repmat(G.typeII_StdE,size(lm1.designMatrix('Fixed'),2),1);
           
            
            nVox=size(obj.basis.fwd,1);
            
            tbl=[];
            for i=1:length(cnames)
                for j=1:length(fldsAll)
                    tbl=[tbl; table(arrayfun(@(x){x},[1:nVox]'),...
                        repmat({fldsAll{j}},nVox,1),...
                        repmat({cnames{i}},nVox,1),...
                        'VariableNames',{'VoxID','type','cond'})];
                end
            end
            G.variables=tbl;
            
            
            
        end
        
 
        
    end
    
end

