
matlabroot=which('addpath');
matlabroot=matlabroot(1:strfind(matlabroot,'toolbox')-1);
p=path;


%keep toolboxs
keep={'local','eml','coder','matlab','simulink','compiler'};
fold=dir(fullfile(matlabroot,'toolbox'));
warning('off','MATLAB:rmpath:DirNotFound');
for i=1:length(fold)
    if(~ismember(fold(i).name,keep) & isempty(strfind(fold(i).name,'.')))
        g=genpath(fullfile(matlabroot,'toolbox',fold(i).name));
        addpath(g);
        
        if(exist(fullfile(matlabroot,'toolbox',fold(i).name,'eml')))
            %this causes issues if the 
            % toolbox/stats/eml/exprnd.m
            % overshadows 
            % toolbox/stats/stats/exprnd.m
            rmpath(fullfile(matlabroot,'toolbox',fold(i).name,'eml'));
            path(path,fullfile(matlabroot,'toolbox',fold(i).name,'eml'));
        end
        
    end
end