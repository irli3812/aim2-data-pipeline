classdef Canonical
    % Canonical HRF response
    
    properties
        peakTime    = 4;
        uShootTime  = 16;
        peakDisp    = 1;
        uShootDisp  = 1;
        ratio       = 1/6;
        duration    = 32;
        
        incDeriv = false;
    end
    
    methods
        function out = convert( obj, s, t )
            
            % params
            a1 = obj.peakTime;
            a2 = obj.uShootTime;
            b1 = obj.peakDisp;
            b2 = obj.uShootDisp;
            c  = obj.ratio;
            
            % sampling freq
            Fs = 1/(t(2)-t(1));
            
            % time vector
            t = (0:1/Fs:obj.duration)';
            
            % impulse response
            h = obj.getImpulseResponse( a1, b1, a2, b2, c, t );
            
            %             % stupid filtering function
            %             f = @(s) bsxfun( @minus, s, s(1,:) );
            %             f = @(h, s) filter(h, 1, f(s));
            %             f = @(h, s) bsxfun( @plus, f(h,s), s(1,:) );
            
            % convert stim vectors
            out = filter(h, 1, s);
            
            % derivatives
            if obj.incDeriv
                da = 1e-6 * a1;
                db = 1e-6 * b1;
                
                ha = (h - obj.getImpulseResponse(a1+da, b1, a2, b2, c, t) )/da;
                hb = (h - obj.getImpulseResponse(a1, b1+db, a2, b2, c, t) )/db;
                
                out = [filter(h, 1, s) filter(ha, 1, s) filter(hb, 1, s)];
                
                % orthogonalize
                out(:,2) = out(:,2) - out(:,1) * (out(:,1)\out(:,2)); % Regress canonical from temporal
                out(:,3) = out(:,3) - out(:,1:2) * (out(:,1:2)\out(:,3)); % Regress canonical+temporal from dispersion
       
            end
            
        end
        
        function h = getFilter(obj,Fs)
            % params
            a1 = obj.peakTime;
            a2 = obj.uShootTime;
            b1 = obj.peakDisp;
            b2 = obj.uShootDisp;
            c  = obj.ratio;
            
            
            % time vector
            t = (0:1/Fs:obj.duration)';
            
            % impulse response
            h = obj.getImpulseResponse( a1, b1, a2, b2, c, t );
        end
        
        function h = draw(obj)
            
            % params
            a1 = obj.peakTime;
            a2 = obj.uShootTime;
            b1 = obj.peakDisp;
            b2 = obj.uShootDisp;
            c  = obj.ratio;
            
            % sampling freq
            Fs = 4;
            t = (0:1/Fs:obj.duration)';
            
            d = obj.getImpulseResponse( a1, b1, a2, b2, c, t );
            h=plot(t,d,'k');
            
             if obj.incDeriv
                da = 1e-6 * a1;
                db = 1e-6 * b1;
                
                ha = (d - obj.getImpulseResponse(a1+da, b1, a2, b2, c, t) )/da;
                hb = (d - obj.getImpulseResponse(a1, b1+db, a2, b2, c, t) )/db;
                hold on;
                h=plot(t,ha,'k--');
                h=plot(t,hb,'k--');
             end
            
        end
    end
    
    methods ( Static )
        function h = getImpulseResponse( a1, b1, a2, b2, c, t )
            h = b1^a1*t.^(a1-1).*exp(-b1*t)/gamma(a1) - c*b2^a2*t.^(a2-1).*exp(-b2*t)/gamma(a2);
            h = h / sum(h);
        end
        
        
    end
    
end

