classdef NotchFilter < nirs.modules.AbstractModule
%% Simple Notch filter
%
% Options:
%     ncomp - % number of components to remove
    properties
        notchlower;
        notchhigher;
    end

    methods

        function obj = NotchFilter( prevJob )
           obj.name = 'Notch filter';
           obj.notchlower=[];
           obj.notchhigher=[];
           if nargin > 0
               obj.prevJob = prevJob;
           end
        end
        
        function data = runThis( obj, data )
            for i = 1:length(data)
                
                d1 = designfilt('bandstopiir','FilterOrder',4, ...
               'HalfPowerFrequency1',obj.notchlower,'HalfPowerFrequency2',obj.notchhigher, ...
               'DesignMethod','butter','SampleRate',data(i).Fs);
           
                d = filtfilt(d1,data(i).data);
                
                data(i).data = d; 
                
%                 if(isempty(obj.lowpass))
%                     [fa,fb]=butter(4,[obj.highpass]*2/data(i).Fs,'high');
%                 elseif(isempty(obj.highpass))
%                      [fa,fb]=butter(4,[obj.lowpass]*2/data(i).Fs,'low');
%                 else
%                      [fa,fb]=butter(4,[obj.highpass obj.lowpass]*2/data(i).Fs);
%                 end
%                 
%                
%                 % resample data
%                 d = data(i).data;
%                 if(obj.keepdc)
%                     dc=mean(d,1);
%                 else
%                     dc=zeros(1,size(d,2));
%                 end
%                 d=d-ones(size(d,1),1)*dc;
%                 d=filtfilt(fa,fb,d);
%                 d=d+ones(size(d,1),1)*dc;
%                
%                 
%                 if(~isempty(obj.lowpass) & obj.do_downsample & obj.lowpass*2<data(i).Fs)
%                     t=data(i).time;
%                     N = floor((t(end)-t(1)) * obj.lowpass*2);
%                     new_t = t(1) + (0:N-1)' / (obj.lowpass*2);
%                   d = interp1(t,d,new_t,'linear');
%                     data(i).time=new_t;
%                 end
%                 
%                 % put back
%                 data(i).data = d; 
%                 
                               
            end
        end
    end
    
end

