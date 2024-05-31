classdef  WKM_difflimit < nirs.vascular.models.AbstractVascularModel
     % State space model of the hemodynamic balloon model.  Modified from
            % Neuroimage. 2004 Feb;21(2):547-67.
            % A state-space model of the hemodynamic approach: nonlinear filtering of BOLD signals.
            % Riera JJ1, Watanabe J, Kazuki I, Naoki M, Aubert E, Ozaki T, Kawashima R.
         
    methods
        function obj = WKM_difflimit(varargin)
            
            obj.description = 'O2 diffusion limited model';
            obj.states={'Flow Inducing','CBF','CBV','q','OEF','CMRO2'};  % This needs to match the model
            
            obj.parameters(1).name='tau_autoreg';
            obj.parameters(1).value= 3;
            obj.parameters(1).fixed= false;
            obj.parameters(1).range= [1 5];
            
            obj.parameters(2).name='tau_flowind';
            obj.parameters(2).value= 2;
            obj.parameters(2).fixed= false;
            obj.parameters(2).range= [1 5];
            
            obj.parameters(3).name='tau';
            obj.parameters(3).value= 3;
            obj.parameters(3).fixed= false;
            obj.parameters(3).range= [1 5];
            
            obj.parameters(4).name='alpha';
            obj.parameters(4).value= .38;
            obj.parameters(4).fixed= false;
            obj.parameters(4).range= [.2 .5];
            
            obj.parameters(5).name='HbT0';
            obj.parameters(5).value= 100;
            obj.parameters(5).fixed= false;
            obj.parameters(5).range= [30 200];
            
            obj.parameters(6).name='E0';
            obj.parameters(6).value= .40;
            obj.parameters(6).fixed= false;
            obj.parameters(6).range= [.2 .65];
            
            obj.parameters(7).name='gain_flowind';
            obj.parameters(7).value= 1;
            obj.parameters(7).fixed= false;
            obj.parameters(7).range= [-Inf Inf];
            
            obj.outputNames={'CMRO2','CBF'};
            
        end
        
        function nlgr= model(obj)
            
            paramorder={'gain_flowind','tau_autoreg','tau_flowind',...
                'tau','alpha','E0','HbT0'};
            
            for i=1:length(paramorder)
                id=find(ismember({obj.parameters.name},paramorder{i}));
                pValues(i)=obj.parameters(id).value;
                pValuesMin{i}=obj.parameters(id).range(1);
                pValuesMax{i}=obj.parameters(id).range(2);
                pValuesFixed{i}=obj.parameters(id).fixed;
            end
            
            FileName      = @nirs.vascular.models.WKM.WKM_diffusion_limited;   % File describing the WKM model structure.
            Order         = [2 1 6];   % Model orders [ny nu nx].
            Parameters    = pValues;   % Initial parameters. Np = 7.
            InitialStates = [0; 1;1;1;1;1];   % Initial initial states.
            Ts            = 0;           % Time-continuous system.
            nlgr = idnlgrey(FileName, Order, Parameters, InitialStates, Ts, ...
                'Name', 'Windkessel model');
            
            set(nlgr, 'InputName', {'flow-inducing'}, 'InputUnit', {'%'},...
                'OutputName', {'HbO2', 'HbR'}, ...
                'OutputUnit', {'uM', 'uM'},                         ...
                'TimeUnit', 's');
            
            nlgr = setinit(nlgr,'Name', obj.states);
            nlgr = setpar(nlgr, 'Name', paramorder);
            nlgr = setpar(nlgr, 'Minimum', pValuesMin);
            nlgr = setpar(nlgr, 'Maximum', pValuesMax);
            nlgr = setpar(nlgr, 'Fixed', pValuesFixed);
            
            nlgr.SimulationOptions.AbsTol = 1e-6;
            nlgr.SimulationOptions.RelTol = 1e-5;
            
        end
        
    end
end