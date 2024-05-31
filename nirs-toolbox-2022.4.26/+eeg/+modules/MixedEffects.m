classdef MixedEffects < nirs.modules.AbstractModule
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
        function obj = MixedEffects( prevJob )
            obj.name = 'Mixed Effects Model';
            if nargin > 0
                obj.prevJob = prevJob;
            end
        end
        
        function G = runThis( obj, S )
            
            % demographics info
            demo = nirs.createDemographicsTable( S );
            
            % center numeric variables
            if obj.centerVars
                n = demo.Properties.VariableNames;
                for i = 1:length(n)
                    if all( isnumeric( demo.(n{i}) ) )
                        demo.(n{i}) = demo.(n{i}) - mean( demo.(n{i}) );
                    end
                end
            end
            
            % preallocate group stats
            G = eeg.core.ChannelStats();
            
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
            [vars, idx] = sortrows(vars, {'electrode','type'});
            
            % list for first source
            [sd, ~,lst] = unique(table(vars.electrode, vars.type), 'rows', 'stable');
            sd.Properties.VariableNames = {'electrode', 'type'};
            
            %% design mats
            tmp = vars(lst == 1, :);
            
            beta = randn(size(tmp,1), 1);
            
            nRE=max(1,length(strfind(obj.formula,'|')));
            warning('off','stats:LinearMixedModel:IgnoreCovariancePattern');
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
            m = median(dWTW);
            
            %W(dWTW > 100*m,:) = 0;
            lstBad=find(dWTW > 100*m);
            
            W(lstBad,:)=[];
            W(:,lstBad)=[];
            X(lstBad,:)=[];
            Z(lstBad,:)=[];
            beta(lstBad,:)=[];
            %% Weight the model
                        
            X    = W*X;
            Z    = W*Z;
            beta = W*beta;
            
            %% fit the model
            warning('off','stats:LinearMixedModel:IgnoreCovariancePattern');
            lm2 = fitlmematrix(X, beta, Z, [], 'CovariancePattern','Isotropic', ...
                'FitMethod', 'ML');
            
            cnames = lm1.CoefficientNames(:);
            for idx=1:length(cnames);
                cnames{idx}=cnames{idx}(max([0 min(strfind(cnames{idx},'_'))])+1:end);
                %if(cnames{idx}(1)=='_'); cnames{idx}(1)=[]; end;
            end;
            cnames = repmat(cnames, [nchan 1]);
            
            %% output
            G.beta       = lm2.Coefficients.Estimate;
            G.covb       = lm2.CoefficientCovariance;
            G.dfe        = lm2.DFE;
            G.probe      = S(1).probe;
            
            sd = repmat(sd, [length(unique(cnames)) 1]);
            sd = sortrows(sd, {'type'});
            
            G.variables = [sd table(cnames)];
            G.variables.Properties.VariableNames{3} = 'cond';
            G.description = ['Mixed Effects Model: ' obj.formula];
            
            if(obj.include_diagnostics)
                %Create a diagnotistcs table of the adjusted data
                yproj = beta - lm2.designMatrix('random')*lm2.randomEffects;
                yproj=inv(W)*yproj;
                
                [sd, ~,lst] = unique(table(electrodes, vars.type), 'rows', 'stable');
                
                btest=[];
                for idx=1:max(lst)                   
                        ll=find(lst == idx);
                        tmp = vars(ll, :);
                        beta = yproj(ll);
                        w=full(dWTW(ll));
                        
                        mdl{idx} = fitlm([table(beta) tmp], lm1.Formula.FELinearFormula,'weights',w.^2,...
                            'dummyVarCoding','full');
                       
                        btest=[btest; mdl{idx}.Coefficients.Estimate];
                                
                end
                mdl=reshape(repmat(mdl,[length(unique(cnames)),1]),[],1);
                G.variables.model=mdl;
 
            end
            
                        
        end
    end
    
end
