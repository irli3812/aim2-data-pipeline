classdef MixedEffects_bootstrap < nirs.modules.MixedEffects
    properties
        number_iterations=1000;
        replacement=true;
        useparallel=false;
        savefile = 'bb';
    end
     methods
        function obj = MixedEffects_bootstrap( prevJob )
            obj.name = 'Mixed Effects Model with bootstrapping';
            if nargin > 0
                obj.prevJob = prevJob;
            end
        end
        
        function G = runThis( obj, S )
             job = nirs.modules.MixedEffects;
            flds=fields(obj);
             flds2=fields(job);
             flds=intersect(flds2,flds);
            for i=1:length(flds)
                job.(flds{i})=obj.(flds{i});
            end
            
            opt = statset('UseParallel',obj.useparallel,'Display','iter');
            
            if(obj.replacement)
                bb=bootstrp(obj.number_iterations,@(x)job.run(x).beta,S,'Options',opt); 
            else
                bb=jackknife(@(x)job.run(x).beta ,S,'Options',opt); 
            end
            
            save([obj.savefile '.mat'], 'bb', '-v7.3')
           
            conds=bb(end,:); %%remove
            bb(end,:)=[];    %%remove
            beta=mean(bb,1)';
            covB=cov(bb);
            
            for i=1:length(beta)
                % this matches the one-sided T-test
                if(beta(i)>0)
                    pval(i,1)=length(1+find(bb(:,i)<=0))/size(bb,1);
                else
                    pval(i,1)=length(1+find(bb(:,i)>0))/size(bb,1);
                end
            end
            G=job.run(S);
            G.beta=beta;
            G.covb=covB;
            G.pvalue_fixed=pval;
        end
        
        
        
     end
end

function beta = MEest(S,job)

G=job.run(S);
beta=G.beta;
end