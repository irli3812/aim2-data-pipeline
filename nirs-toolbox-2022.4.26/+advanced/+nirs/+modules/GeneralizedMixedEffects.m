classdef GeneralizedMixedEffects < nirs.modules.AbstractModule
    %% MixedEffect - Performs group level mixed effects analysis.
    %
    % Options:
    %     formula     - string specifiying regression formula (see Wilkinson notation)
    %     dummyCoding - dummyCoding format for categorical variables (full, reference, effects)
    %     centerVars  - (true or false) flag for whether or not to center numerical variables
    %
    % Example Formula:
    %     % this will calculate the group average for each condition
    %     j = nirs.modules.MixedEffects();
    %     j.formula = 'beta ~ -1 + group:cond + (1|subject)';
    %     j.dummyCoding = 'full';
    
    properties
        formula = 'beta ~ -1 + group:cond + (1|subject)';
        dummyCoding = 'full';
        centerVars = true;
        include_diagnostics=false;
        
    end
    
    methods
        function obj = GeneralizedMixedEffects( prevJob )
            obj.name = 'Generalized Mixed Effects Model';
            if nargin > 0
                obj.prevJob = prevJob;
            end
        end
        
        function G = runThis( obj, S )
            
            if(length(S)<2)
                G=S;
                return;
            end
            
            % demographics info
            demo = nirs.createDemographicsTable( S );
            
            % center numeric variables
            if obj.centerVars
                n = demo.Properties.VariableNames;
                for i = 1:length(n)
                    if all( isnumeric( demo.(n{i}) ) )
                        demo.(n{i}) = demo.(n{i}) - nanmean( demo.(n{i}) );
                    end
                end
            end
            
            % preallocate group stats
            G = nirs.core.ChannelStats();
            
            %% loop through files
            W = sparse([]);
            iW = sparse([]);
            
            b = [];
            vars = table();
            for i = 1:length(S)
                % coefs
                b = [b; S(i).beta];
                
                % whitening transform
                

                
                [u, s, ~] = svd(S(i).covb, 'econ');
                %W = blkdiag(W, diag(1./diag(sqrt(s))) * u');
                W = blkdiag(W, pinv(s).^.5 * u');
                
                iW = blkdiag(iW, u*sqrt(s) );
                
                
                %                L = chol(S(i).covb,'upper');
                %                W = blkdiag(W,pinv(L));
                
                % table of variables
                file_idx = repmat(i, [size(S(i).beta,1) 1]);
                
                if(~isempty(demo))
                    vars = [vars;
                        [table(file_idx) S(i).variables repmat(demo(i,:), [size(S(i).beta,1) 1])]
                        ];
                else
                    vars = [vars; ...
                        [table(file_idx) S(i).variables]];
                end
            end
            
            % sort
            [vars, idx] = nirs.util.sortrows(vars, {'source', 'detector', 'type'});
            
            % list for first source
            [sd, ~,lst] = nirs.util.uniquerows(table(vars.source, vars.detector, vars.type));
            sd.Properties.VariableNames = {'source', 'detector', 'type'};
            
            %% design mats
            for c = 1:height(vars)
                block_ind = strfind(vars.cond{c},'◄');
                if ~isempty(block_ind)
                    vars.cond{c} = vars.cond{c}(1:block_ind-2);
                end
            end
            tmp = vars(lst == 1, :);
            
            beta = randn(size(tmp,1), 1);
            
            nRE=max(1,length(strfind(obj.formula,'|')));
            warning('off','stats:LinearMixedModel:IgnoreCovariancePattern');
            
            obj.formula=nirs.util.verify_formula([table(beta) tmp], obj.formula,true);
            
            lm1 = fitlme([table(beta) tmp], obj.formula, 'dummyVarCoding',...
                obj.dummyCoding, 'FitMethod', 'ML', 'CovariancePattern', repmat({'Isotropic'},nRE,1));
            
            X = lm1.designMatrix('Fixed');
            Z = lm1.designMatrix('Random');
            
            nchan = max(lst);
            
            X = kron(speye(nchan), X);
            Z = kron(speye(nchan), Z);
            
            %% put them back in the original order
            vars(idx,:) = vars;
            X(idx, :)   = X;
            Z(idx, :)   = Z;
            beta        = b; % already in correct order
            
            %% check weights
            dWTW = sqrt(diag(W'*W));
            
            % Edit made 3/20/16-  Treat each modality seperately.  This
            % avoids issues with mixed data storage (e.g. StO2,Hb, CMRO2)
            % etc.
            utypes=unique(vars.type);
            if(~iscellstr(utypes)); utypes={utypes(:)}; end
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
            
            [i,j]=find(isnan(X));
            lst=find(~ismember(1:size(X,1),unique(i)));
            if(rank(full(X(lst,:)))<size(X,2))
                warning('Model is unstable');
            end
            lstKeep=find(~all(X==0));
          
          [tmp,bhat,~]=nirs.math.fitlme(X,beta,Z);  
          beta = beta-Z*bhat;  
            
          s=struct;  
          s.beta=beta;
          formula2='beta ~ -1';
          coefnames = matlab.lang.makeValidName(lm1.CoefficientNames);
          ncoef = length(coefnames);
          chanlbls = unique(vars(:,2:4),'stable','rows');
          
          for j=1:size(X,2)
                coef = mod(j-1,ncoef)+1;
                channel = (j-coef)/ncoef + 1;
                lbl=sprintf('%s_S%02i_D%02i_%s',coefnames{coef},chanlbls.source(channel),chanlbls.detector(channel),chanlbls.type{channel});
                s=setfield(s,lbl,X(:,j));
                formula2=[formula2 '+' lbl]; 
          end
         
%          lm=fitlmematrix(X,beta,Z,[]);
          
          %% fit the model
          glm=fitglm(struct2table(s),formula2,'dummyVarCoding',obj.dummyCoding);
           
             cnames = lm1.CoefficientNames(:);
            for idx=1:length(cnames);
                cnames{idx}=cnames{idx}(max([0 min(strfind(cnames{idx},'_'))])+1:end);
                %if(cnames{idx}(1)=='_'); cnames{idx}(1)=[]; end;
            end;
            cnames = repmat(cnames, [nchan 1]);
            
            %% output
            G.beta=zeros(size(X,2),1);
            G.covb=1E6*eye(size(X,2)); %make sure anything not fit will have high variance
            
            G.beta(lstKeep) = glm.Coefficients.Estimate;
            G.covb(lstKeep,lstKeep) = glm.CoefficientCovariance;
            G.dfe        = lm1.DFE;
            
%             [U,~,~]=nirs.math.mysvd(full([X(:,lstKeep) Z]));
%             G.dfe=length(beta)-sum(U(:).*U(:));
            
            G.probe      = S(1).probe;
            
            sd = repmat(sd, [length(unique(cnames)) 1]);
            sd = nirs.util.sortrows(sd, {'source', 'detector', 'type'});
            
            G.variables = [sd table(cnames)];
            G.variables.Properties.VariableNames{4} = 'cond';
            G.description = ['Mixed Effects Model: ' obj.formula];
            
            G.basis=S(1).basis;
            
            if(obj.include_diagnostics)
                %Create a diagnotistcs table of the adjusted data
%                 yproj = beta - lm2.designMatrix('random')*lm2.randomEffects;
                yproj=inv(W)*beta;
                
                
                [sd, ~,lst] = nirs.util.uniquerows(table(vars.source, vars.detector, vars.type));
                vars(:,~ismember(vars.Properties.VariableNames,lm1.PredictorNames))=[];
                if(~iscell(sd.Var3)); sd.Var3=arrayfun(@(x){x},sd.Var3); end;
                btest=[]; models=cell(height(G.variables),1);
                for idx=1:max(lst)                   
                        ll=find(lst == idx);
                        tmp = vars(ll, :);
                        beta = yproj(ll);
                        w=full(dWTW(ll));
                        
                       mdl{idx} = fitlm([table(beta) tmp], [lm1.Formula.FELinearFormula.char ' -1'],'weights',w.^2,'dummyVarCoding','full');
                          
                       
                       btest=[btest; mdl{idx}.Coefficients.Estimate];
                       
                        for j=1:length(mdl{idx}.CoefficientNames)
                            cc=mdl{idx}.CoefficientNames{j};
                            if(isempty(find(ismember(G.variables.cond,cc) & ismember(G.variables.source,sd.Var1(idx)))))
                                if(~isempty(strfind(cc,'cond_')))
                                    cc=cc(strfind(cc,'cond_')+length('cond_'):end);
                                else
                                    cc=cc(min(strfind(cc,'_'))+1:end);
                                end
                            end
                            id=find(ismember(G.variables.cond,cc) & ismember(G.variables.source,sd.Var1(idx)) & ...
                                ismember(G.variables.detector,sd.Var2(idx)) & ismember(G.variables.type,sd.Var3{idx}));
                           models{id}=mdl{idx};
                       end
                end
                %mdl=reshape(repmat(mdl,[length(unique(cnames)),1]),[],1);
                G.variables.model=models;
 
            end
            
            
                        
        end
    end
    
end
