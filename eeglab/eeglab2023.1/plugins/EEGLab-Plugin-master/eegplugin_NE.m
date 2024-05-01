% eegplugin_NE() - EEGLAB plugin for importing data using NEUROELECTRICS Matlab toolbox
%
% Usage:
%   >> eegplugin_NE(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks. 
%
% Create a plugin:
%   For more information on how to create an EEGLAB plugin see the
%   help message of eegplugin_besa() or visit http://www.sccn.ucsd.edu/eeglab/contrib.html
%
% Author: Jaume Banús, 08 Sept. 2015
%
% External dependencies: xml4mat mathworks toolbox. 

function vers = eegplugin_NE(fig, trystrs, catchstrs)

vers = '1.1';
if nargin < 3
    error('eegplugin_eepimport requires 3 arguments');
end;

% add neuroelectrics folder to path
% -----------------------
if ~exist('pop_easy','file')
    p = which('eegplugin_NE');
    p = p(1:strfind(p,'eegplugin_NE.m')-1);
    addpath( p );
end;

% external dependencies (xml4mat)
if ~exist('xml4mat','dir')
    p = which('eegplugin_NE');
    p = p(1:strfind(p,'eegplugin_NE')-1);   
    addpath ( [ p 'xml4mat']);
end

% add location folder
if ~exist('Locations','dir')
    p = which('eegplugin_NE');
    p = p(1:strfind(p,'eegplugin_NE')-1);   
    addpath ( [ p 'Locations']);
end

% find import data menu
% ---------------------
menu = findobj(fig, 'tag', 'import data');

% menu callbacks
% --------------
easy = [ trystrs.no_check '[EEGTMP LASTCOM] = pop_easy;' catchstrs.new_non_empty ];
nedf = [ trystrs.no_check '[EEGTMP LASTCOM] = pop_nedf;' catchstrs.new_non_empty ];

uimenu( menu, 'Label', 'From Neuroelectrics .EASY', 'CallBack', easy, 'Separator', 'on');
uimenu( menu, 'Label', 'From Neuroelectrics .NEDF', 'CallBack', nedf, 'Separator', 'off');

end