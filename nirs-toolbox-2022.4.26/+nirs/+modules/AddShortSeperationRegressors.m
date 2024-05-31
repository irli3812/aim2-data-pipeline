classdef AddShortSeperationRegressors < nirs.modules.AbstractModule
    %% AddShortSeperationRegressors - Adds short seperation data as regressors to the GLM model
    %
    
    properties
         scICA;  % use single channel ICA instead of PCA for defining regressors
    end
    
    methods
        function obj = AddShortSeperationRegressors( prevJob )
            obj.name = 'AddShortSeperationRegressors';
            obj.scICA = false;
            if nargin > 0
                obj.prevJob = prevJob;
            end
        end
        
        function data = runThis( obj, data )
            for i = 1:numel(data)
                if(~nirs.util.hasshortdistances(data(i)))
                    continue;
                end
                lstss=find( data(i).probe.link.ShortSeperation);
                dd=data(i).data(:,lstss);
                
                dd=dd-ones(size(dd,1),1)*mean(dd,1);
               
                tmp=nirs.core.Data;
                tmp.time=data(i).time;
                tmp.data=dd;
                j=nirs.modules.FixNaNs;
                tmp=j.run(tmp);
                dd=tmp.data;
                
                if(~obj.scICA)
                    dd=orth(dd);
                else
                     dd2=[dd, [diff(dd); zeros(1,size(dd,2))],[diff(diff(dd)); zeros(2,size(dd,2))]]; 
                   
                   dd=orth(dd2);
%                    [in,f]=nirs.math.innovations(dd,1*data(i).Fs);
%                    dd2=[]; 
%                    n=1;
%                    for id=1:length(f); n=max(n,length(f{id})); end;
%                    for id=1:size(dd,2); 
%                        a=convmtx(in(:,id),n); 
%                        dd2=[dd2 a]; 
%                    end;
%                    dd2=dd2(1:size(dd,1),:);
%                    dd=orth(dd2);
               end
                        
                for j=1:size(dd,2)
                    st=nirs.design.StimulusVector;

                    st.regressor_no_interest=true;
                    st.name=['SS_PCA' num2str(j)];
                    st.time=data(i).time;
                    st.vector=dd(:,j);
                    st.vector=st.vector-mean(st.vector);
                    st.vector=st.vector./sqrt(var(st.vector));
                    data(i).stimulus(st.name)=st;  
                end
                
            end
        end
    end
    
end

