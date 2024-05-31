classdef ShortSeperationCCAFilter < nirs.modules.AbstractModule
    %% PCAFilter - Removes principal components reducing spatial covariance.
    %
    % Options:
    %     ncomp - % number of components to remove
    
    properties
        thrsh = 0.05; % number of components to remove
        lags=10;
        prewhiten=true;
    end
    
    methods
        
        function obj = ShortSeperationCCAFilter( prevJob )
            obj.name = 'Remove Principal Components based on short seperations';
            
            if nargin > 0
                obj.prevJob = prevJob;
            end
        end
        
        function data = runThis( obj, data )
            for i = 1:numel(data)
                if(~nirs.util.hasshortdistances(data(i)))
                    continue;
                end
                
                % remove mean
                m = mean(data(i).data,1);
                d = bsxfun(@minus, data(i).data, m);
                
                
                types=unique(data(i).probe.link.type);
                if(obj.prewhiten)
                    [inn,f]=nirs.math.innovations(d,data(i).Fs*4);
                else
                    inn=d;
                end
                for tI=1:length(types)
                    
                    
                    if(~iscell(types))
                        types=num2cell(types);
                    end
                    lst=find(ismember(data(i).probe.link.type,types{tI}) & ~data(i).probe.link.ShortSeperation);
                    lstss=find(ismember(data(i).probe.link.type,types{tI}) & data(i).probe.link.ShortSeperation);
                    
                    
                    
                    d = inn(:,lst);
                    dss=inn(:,lstss);
                    
                    
                    
                    X=[];
                    for jj=1:obj.lags
                        X=[X [zeros(jj-1,size(dss,2)); dss(jj:end,:)]];
                    end
                    
                    warning('off','stats:canoncorr:NotFullRank');
                    [A,B,R,U,V,stats] = canoncorr(d,X);
                    
                    rm=find(stats.p<obj.thrsh);
                    disp(['removing ' num2str(length(rm)) ' components'])
                    d= d-U(:,rm)*pinv(A(:,rm))+ones(size(d,1),1)*mean(d,1);
                    
                    %d=d-U(:,rm)*inv(U(:,rm)'*U(:,rm))*U(:,rm)'*d+ones(size(d,1),1)*mean(d,1);
                    
                    Xhat = V(:,rm)*pinv(B(:,rm))+ones(size(X,1),1)*mean(X,1);
                    %Xhat=V(:,rm)*inv(V(:,rm)'*V(:,rm))*V(:,rm)'*X+ones(size(X,1),1)*mean(X,1);
                    for jj=1:obj.lags
                        dss= dss-Xhat(:,(jj-1)*size(dss,2)+[1:size(dss,2)]);
                    end
                    
                    % put back
                    inn(:,lst) = d;
                    inn(:,lstss) = dss;
                end
                
                if(obj.prewhiten)
                    for j=1:length(f)
                        data(i).data(:,j)=filter(1,[1; f{j}(2:end)],inn(:,j));
                    end
                    
                else
                    data(i).data=inn;
                end
                
                data(i).data= bsxfun(@plus,data(i).data , m);
                
            end
        end
    end
    
end
