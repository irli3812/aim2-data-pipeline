classdef PCAFilter < nirs.modules.AbstractModule
    %% PCAFilter - Removes principal components reducing spatial covariance.
    %
    % Options:
    %     ncomp - % number of components to remove
    
    properties
        ncomp = 1; % number of components to remove
        splittypes=true;
        keep_components=false;
    end
    
    methods
        
        function obj = PCAFilter( prevJob )
            obj.name = 'Remove Principal Components';
            
            if nargin > 0
                obj.prevJob = prevJob;
            end
        end
        
        function data = runThis( obj, data )
            for i = 1:numel(data)
                
                if(obj.keep_components)
                    
                    comp=data(i);
                    comp.auxillary('eigenvalues')=[];
                    data(i).auxillary('PCAfilter')=comp;
                end
                
                types=unique(data(i).probe.link.type);
                for tI=1:length(types)
                    
                    if(tI>1 & ~obj.splittypes)
                        continue;
                    end
                    
                    if(obj.splittypes)
                        if(~iscell(types))
                            types=num2cell(types);
                        end
                        lst=find(ismember(data(i).probe.link.type,types{tI}));
                    else
                        lst=1:size(data(i).data,2);
                    end
                    
                    % resample data
                    d = data(i).data(:,lst);
                    
                    % remove mean
                    m = mean(d,1);
                    d = bsxfun(@minus, d, m);
                    
                    % svd
                    [u, s, v] = svd(d,'econ');
                    s = diag(s);
                    
                    if(obj.ncomp>0 & obj.ncomp<1)
                        % if fraction, then remove that % of the noise
                        n=max(find(cumsum(s)/sum(s)<=obj.ncomp));
                        disp(['Removing first ' num2str(n) ' components (' num2str(sum(s(1:n))/sum(s)*100) '%)']);
                        
                        if(n==0)
                            disp(['     lowest component = ' num2str(sum(s(1))/sum(s)*100) '%)']);
                        end
                    else
                        n=obj.ncomp;
                    end
                    
                    if(obj.keep_components)
                        s2=s;
                        s2(n+1:end)=0;
                        comp=data(i).auxillary('PCAfilter');
                        comp.data(:,lst) = u*diag(s2)*v';
                        eig=comp.auxillary('eigenvalues');
                        eig(:,end+1)=s;
                        data(i).auxillary('PCAfilter')=comp;
                    end
                    
                    % remove n components
                    s(1:n) = 0;
                    d = u*diag(s)*v';
                    
                    % add mean back
                    d = bsxfun(@plus, d, m);
                    
                    % put back
                    data(i).data(:,lst) = d;
                end
            end
        end
    end
    
end

