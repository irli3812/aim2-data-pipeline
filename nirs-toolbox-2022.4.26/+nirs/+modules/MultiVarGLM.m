classdef MultiVarGLM < nirs.modules.AbstractGLM
    properties
        useSpectralPriors = true;
        PPF = 5 / 50;
    end
    
    methods
        function obj = MultiVarGLM( prevJob )
            if nargin > 0, obj.prevJob = prevJob; end
            
            obj.name             	= 'Multivariate GLM';
            obj.basis('default')    = nirs.design.basis.Canonical();
            obj.trend_func          = @nirs.design.trend.constant;
        end
        
        function S = runThis( obj, data )
            for i = 1:numel(data)
       
                % get data
                d  = data(i).data;
                t  = data(i).time;
                Fs = data(i).Fs;
                
                % sort data
                link = data(i).probe.link;
                if(~isempty(strfind(class(probe),'nirs')))
                    if(~ismember('source',link.Properties.VariableNames) & ...
                            ismember('ROI',link.Properties.VariableNames))
                        [link, idx] = nirs.util.sortrows(link, {'ROI','type'});
                    else
                        [link, idx] = nirs.util.sortrows(link, {'source', 'detector','type'});
                    end
                elseif(~isempty(strfind(class(probe),'eeg')))
                    [link, idx] = nirs.util.sortrows(link, {'electrode','type'});
                else
                    error('data type not supported');
                end
                
                d = d(:,idx);
                
                % design mat
                [X, tbl] = nirs.design.createMultiVarDesignMat( ...
                    data(i).stimulus, t, obj.basis, link, obj.useSpectralPriors );
                
                C = obj.getTrendMatrix( t );
                
                % fit data
                stats = nirs.math.mv_ar_irls( X, d, round(4*Fs), C);

                % new probe
                probe = data(i).probe;
                
                if obj.useSpectralPriors
                    lst  = link.type == link.type(1);
                    probe.link = repmat(link(lst,:), [2 1]);
                    type = repmat( {'hbo', 'hbr'}, [sum(lst) 1]);
                    probe.link.type = type(:);
                    probe.link = nirs.util.sortrows(probe.link, {'source', 'detector', 'type'});
                end
                
                % outputs
                ncond = size(tbl,1);
                
                S(i) = nirs.core.ChannelStats();
                S(i).description    = data(i).description;
                
                [tbl, idx] = nirs.util.sortrows(tbl, {'cond', 'source', 'detector', 'type'});
                
                
                S(i).variables    	= tbl;
                S(i).demographics   = data(i).demographics;
                S(i).probe          = probe;
                
                b       = stats.b(1:ncond);
                covb    = stats.covb(1:ncond, 1:ncond);
                
                S(i).beta = b(idx);
                S(i).covb = covb(idx, idx);
                S(i).dfe  = stats.dfe;
                
                
                % print progress
                obj.printProgress( i, length(data) )
            end

        end
    end
    
    methods ( Access = protected )
        function [X, names, link] = createX( obj, data, lambda )
          
            names = {};
            if obj.useSpectralPriors
                
                t       = data.time;
                stims   = data.stimulus;

                [xhbo, n] = nirs.design. ...
                    createDesignMatrix( stims, t, obj.basis, 'hbo' );
                
                names   = [names n];
                
                [xhbr, n] = nirs.design. ...
                    createDesignMatrix( stims, t, obj.basis, 'hbr' );
                
                names   = [names n];
                
                X = [];
                e = nirs.media.getspectra(lambda);
                
                for i = 1:length( lambda )
                    X(:,:,i) = [e(i,1)*xhbo e(i,2)*xhbr] * 1e-6;
                end
                                
            else
                
                t       = data.time;
                stims   = data.stimulus;
                
                [X, names] = nirs.design. ...
                        createDesignMatrix( stims, t, obj.basis );
                    
            end
            
        end
    end
            
end

