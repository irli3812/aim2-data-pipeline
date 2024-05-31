function varargout = jobmanagerGUI(varargin)
% JOBMANAGERGUI MATLAB code for jobmanagerGUI.fig
%      JOBMANAGERGUI, by itself, creates a new JOBMANAGERGUI or raises the existing
%      singleton*.
%
%      H = JOBMANAGERGUI returns the handle to a new JOBMANAGERGUI or the handle to
%      the existing singleton*.
%
%      JOBMANAGERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in JOBMANAGERGUI.M with the given input arguments.
%
%      JOBMANAGERGUI('Property','Value',...) creates a new JOBMANAGERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before jobmanagerGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to jobmanagerGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help jobmanagerGUI

% Last Modified by GUIDE v2.5 10-Aug-2015 08:38:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @jobmanagerGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @jobmanagerGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before jobmanagerGUI is made visible.
function jobmanagerGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to jobmanagerGUI (see VARARGIN)

% Choose default command line output for jobmanagerGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes jobmanagerGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

jObject=com.mathworks.mlwidgets.html.HTMLBrowserPanel;
[browser,container]=javacomponent(jObject,[],handles.figure1);
set(container,'units',get(handles.uipanel1,'units'),'position',get(handles.uipanel1,'position'));
set(handles.uipanel1,'visible','off');
set(container,'UserData',browser);
set(container,'tag','jobmanager_browser')
browser.setHtmlText('Click on avaliable modules to see help info');
return

% --- Outputs from this function are returned to the command line.
function varargout = jobmanagerGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in listbox_avaliable.
function listbox_avaliable_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_avaliable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_avaliable contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_avaliable

info=get(handles.listbox_avaliable,'UserData');
html=help2html(['nirs.modules.' info{get(handles.listbox_avaliable,'value'),1}]);
delete(findobj('tag','jobmanager_browser'));

jObject=com.mathworks.mlwidgets.html.HTMLBrowserPanel;
[browser,container]=javacomponent(jObject,[],handles.figure1);
set(container,'units',get(handles.uipanel1,'units'),'position',get(handles.uipanel1,'position'));
set(handles.uipanel1,'visible','off');
set(container,'tag','jobmanager_browser')
browser.setHtmlText(html);

return


% --- Executes during object creation, after setting all properties.
function listbox_avaliable_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_avaliable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
str=help('nirs.modules');
lst=find(double(str)==10);

cnt=1;
for idx=3:length(lst)
    tx=str(lst(idx-1)+1:lst(idx)-1);
    if(isempty(strfind(tx,'Abstract')))
        [info{cnt,1} info{cnt,2}]=strtok(tx);
        info{cnt,1}=strtrim(info{cnt,1});
        info{cnt,2}=strtrim(info{cnt,2});
        cnt=cnt+1;
    end
end

set(hObject,'String',{info{:,1}})
set(hObject,'Userdata',info);
return


% --- Executes on button press in pushbutton_add.
function pushbutton_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

info=get(handles.listbox_avaliable,'UserData');
jobs=get(handles.listbox_loaded,'UserData');

if(isempty(jobs))
    jobs=nirs.modules.ImportData(jobs);
end
jobs=nirs.modules.(info{get(handles.listbox_avaliable,'value'),1})(jobs);

if(get(handles.checkbox_addfield,'value'))
    jobs=nirs.modules.ExportData(jobs);
    jobs.Output=['data_' info{get(handles.listbox_avaliable,'value'),1}];
end


set(handles.listbox_loaded,'UserData',jobs);
update_tree(handles);

function update_tree(handles);

info=get(handles.listbox_avaliable,'UserData');
jobs=get(handles.listbox_loaded,'UserData');
delete(findobj('tag','uitree_cont_jobs'));
delete(findobj('tag','uitree_obj_jobs'));

import javax.swing.*
import javax.swing.tree.*;
root = uitreenode('v0','jobs', 'jobs', [], false);

j=[];
j.prevJob=jobs;
cnt=1;
while(~isempty(j.prevJob))
     g(cnt) = uitreenode('v0', j.prevJob.name,  j.prevJob.name, [], false);
     
     opt=options(j.prevJob);
     for idx=1:length(opt)
         val=j.prevJob.(opt{idx});
         if(isnumeric(val));
             val=num2str(val);
         end;
         if(iscell(val));
             for idx2=1:length(val);
                 val{idx2}=['''' val{idx2} ''''];
             end
             for idx2=1:length(val)-1;
                 val{idx2}=[val{idx2} ', '];
             end
             val=['{' val{:} '}'];
             
         end;
         
         if(islogical(val))
             if(val)
                 val='true';
             else
                 val='false';
             end
         end
         if(isa(val,'Dictionary'))
             val='Dictionary';
         end
         if(isa(val,'function_handle'))
             val=func2str(val);
         end
         if(~isempty(val))
             try
                 str =[opt{idx} ' = ' val(1,:)];
                 o = uitreenode('v0', str,  str, [], true);
                 g(cnt).add(o);
             end
         end
     end
     
     
     cnt=cnt+1;
     j=j.prevJob;
end
if(exist('g'))
for idx=length(g):-1:1
    root.add(g(idx));
end
end
figure(handles.figure1);

[mtree,container] = uitree('v0', 'Root', root);
set(container,'units',get(handles.listbox_loaded,'units'));
set(container,'tag','uitree_cont_jobs');

set(container,'position',get(handles.listbox_loaded,'position'));
set(container,'visible','on');

set(container,'userdata',mtree);
% 
% 
% str = convertjobs2str(jobs);
% set(handles.listbox_loaded,'String',str);

%     
% for idx=1:length(g)
%     mtree.expand(g(idx));
% end
mtree.expand(mtree.getRoot);
set(mtree,'NodeSelectedCallback',@listbox_loaded_Callback);

return

function [str, jobeval] = convertjobs2str(jobs)
str = {'     >> out'};
jobeval = {'out = job.run(in)'};

j.prevJob=jobs;

while(~isempty(j.prevJob))
    
    str={'---------------------------------------------------------------' str{:}};
    opt=options(j.prevJob);
    for idx=1:length(opt)
        val=j.prevJob.(opt{idx});
        if(isnumeric(val));
            val=num2str(val);
        end;
        if(iscell(val));
            for idx2=1:length(val);
                val{idx2}=['''' val{idx2} ''''];
            end
            for idx2=1:length(val)-1;
                val{idx2}=[val{idx2} ', '];
            end
            val=['{' val{:} '}'];
            
        end;
        str ={[opt{idx} '=' val] str{:}};
        jobeval={['      ' opt{idx} '=' val ';'] jobeval{:}};
    end
    str={j.prevJob.name str{:}};
    jobeval={['job=' class(jobs) '(job);'] jobeval{:}};
    j=j.prevJob;
end
  str={'---------------------------------------------------------------' str{:}};
str = {'raw >> ' str{:}};
jobeval={'job=[]' jobeval{:}};


return


% --- Executes on button press in checkbox_addfield.
function checkbox_addfield_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_addfield (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_addfield


% --- Executes on selection change in listbox_loaded.
function listbox_loaded_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_loaded (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_loaded contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_loaded
handles=guidata(findobj('tag','listbox_loaded'));

name=getselectednode;
jobs=get(handles.listbox_loaded,'UserData');

j.prevJob=jobs;
cnt=1;
while(~isempty(j.prevJob))
    JJ{cnt}=j.prevJob;
    JJ{cnt}.prevJob=[];
   
    j=j.prevJob;
    Names{cnt}=JJ{cnt}.name;
     cnt=cnt+1;
end
lst=min(find(ismember(Names,toCharArray(name)')));

if(isempty(lst) || ~ismember('javaoptions',methods(JJ{lst})))
    return
end

prop=javaoptions(JJ{lst});

com.mathworks.mwswing.MJUtilities.initJIDE;
 
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import javax.swing.*;
import com.mathworks.mwswing.*;
% Property list
list = java.util.ArrayList();

for idx=1:length(prop)
    set(prop(idx),'Value',JJ{lst}.(get(prop(idx),'name')));
    list.add(prop(idx));
   
end

% Prepare a properties table containing the list
model = com.jidesoft.grid.PropertyTableModel(list);
model.expandAll();
grid = com.jidesoft.grid.PropertyTable(model);
pane = com.jidesoft.grid.PropertyPane(grid);

warning('off','MATLAB:hg:PossibleDeprecatedJavaSetHGProperty');
hModel = handle(model, 'CallbackProperties');
set(hModel, 'PropertyChangeCallback', @callback_onPropertyChange);


%addlistener(model,'PropertyChange',@callback_onPropertyChange);
 
% Display the properties pane onscreen
[pan,comp]=javacomponent(pane, [0 0 200 200], handles.uipanel2);
set(comp,'units','normalized','position',[0 0 1 1]);
set( handles.uipanel2,'UserData',name);

return

function callback_onPropertyChange(varargin)
handles=guidata(findobj('tag','listbox_loaded'));
prop=varargin{2};
val=prop.getNewValue;
propname=prop.getPropertyName;

name=get(findobj('tag','uipanel2'),'Userdata');
%name=getselectednode;

jobs=get(handles.listbox_loaded,'UserData');
j.prevJob=jobs;
cnt=1;
while(~isempty(j.prevJob))
    JJ{cnt}=j.prevJob;
    JJ{cnt}.prevJob=[];
    j=j.prevJob;
    Names{cnt}=JJ{cnt}.name;
    cnt=cnt+1;
end
lst=min(find(ismember(Names,toCharArray(name)')));
JJ{lst}=setfield(JJ{lst},propname.toCharArray',val);

JJ{end}.prevJob=[];
for idx=length(JJ)-1:-1:1
    JJ{idx}.prevJob=JJ{idx+1};  
end
jobs=JJ{1};
set(handles.listbox_loaded,'UserData',jobs);
update_tree(handles);

return


% --- Executes during object creation, after setting all properties.
function listbox_loaded_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_loaded (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

jobs=[];
set(hObject,'String',[]);
set(hObject,'Userdata',jobs);

import javax.swing.*
import javax.swing.tree.*;
root = uitreenode('v0','jobs', 'jobs', [], false);
[mtree,container] = uitree('v0', 'Root', root);

set(container,'units',get(hObject,'units'));
set(container,'tag','uitree_cont_jobs');
set(container,'position',get(hObject,'position'));
set(container,'visible','on');
set(hObject,'visible','off');
set(container,'userdata',root);

return

function name=getselectednode
a=findobj('tag','uitree_cont_jobs');
a=get(a,'Userdata');
node=get(a.Tree,'LastSelectedPathComponent');
if(node.getLevel==2)
    node=node.getParent;
end
name=node.getName;

% --- Executes on button press in pushbutton_mov
function pushbutton_moveup_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_moveup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
name=getselectednode;
jobs=get(handles.listbox_loaded,'UserData');

j.prevJob=jobs;
cnt=1;
while(~isempty(j.prevJob))
    JJ{cnt}=j.prevJob;
    JJ{cnt}.prevJob=[];
   
    j=j.prevJob;
    Names{cnt}=JJ{cnt}.name;
     cnt=cnt+1;
end


lst=min(find(ismember(Names,toCharArray(name)')));

if(lst~=length(JJ))
    JJ={JJ{[1:lst-1 lst+1 lst lst+2:length(JJ)]}};
end

JJ{end}.prevJob=[];
for idx=length(JJ)-1:-1:1
    JJ{idx}.prevJob=JJ{idx+1};  
end
jobs=JJ{1};


set(handles.listbox_loaded,'UserData',jobs);
update_tree(handles);


return

% --- Executes on button press in pushbutton_movedown.
function pushbutton_movedown_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_movedown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

name=getselectednode;
jobs=get(handles.listbox_loaded,'UserData');

j.prevJob=jobs;
cnt=1;
while(~isempty(j.prevJob))
    JJ{cnt}=j.prevJob;
    JJ{cnt}.prevJob=[];
   
    j=j.prevJob;
    Names{cnt}=JJ{cnt}.name;
     cnt=cnt+1;
end


lst=min(find(ismember(Names,toCharArray(name)')));

if(lst~=1)
    JJ={JJ{[1:lst-2 lst lst-1 lst+1:length(JJ)]}};
end

JJ{end}.prevJob=[];
for idx=length(JJ)-1:-1:1
    JJ{idx}.prevJob=JJ{idx+1};  
end
jobs=JJ{1};


set(handles.listbox_loaded,'UserData',jobs);
update_tree(handles);

% --- Executes on button press in pushbutton_delete.
function pushbutton_delete_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_delete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

name=getselectednode;
jobs=get(handles.listbox_loaded,'UserData');

j.prevJob=jobs;
cnt=1;
while(~isempty(j.prevJob))
    JJ{cnt}=j.prevJob;
    JJ{cnt}.prevJob=[];
   
    j=j.prevJob;
    Names{cnt}=JJ{cnt}.name;
     cnt=cnt+1;
end


lst=min(find(ismember(Names,toCharArray(name)')));

JJ={JJ{[1:lst-1 lst+1:length(JJ)]}};

if(length(JJ)>0)
JJ{end}.prevJob=[];
for idx=length(JJ)-1:-1:1
    JJ{idx}.prevJob=JJ{idx+1};  
end
    jobs=JJ{1};
else
    jobs=[];
end
set(handles.listbox_loaded,'UserData',jobs);
update_tree(handles);


% --- Executes on button press in pushbutton_editparam.
function pushbutton_editparam_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_editparam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


return

% --------------------------------------------------------------------
function uimenu_file_Callback(hObject, eventdata, handles)
% hObject    handle to uimenu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function uimeu_regress_Callback(hObject, eventdata, handles)
% hObject    handle to uimeu_regress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

jobs=get(handles.listbox_loaded,'UserData');
ROCtest=nirs.testing.ChannelStatsROC;
ROCtest.pipeline=jobs;
iter=get(handles.uimenu_changeiterations,'Userdata');
ROCtest=ROCtest.run(iter);
ROCtest.draw;

return


% --------------------------------------------------------------------
function uimenu_savejob_Callback(hObject, eventdata, handles)
% hObject    handle to uimenu_savejob (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename, pathname] = uiputfile('pipeline.mat', 'Save pipeline as');
if isequal(filename,0) || isequal(pathname,0)
    return
end

job=get(handles.listbox_loaded,'UserData');
save(fullfile(pathname,filename),'job');


% --------------------------------------------------------------------
function uimenu_loadjob_Callback(hObject, eventdata, handles)
% hObject    handle to uimenu_loadjob (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename, pathname] = uigetfile('*.mat', 'Pick a pipeline file');
if isequal(filename,0) || isequal(pathname,0)
    return
end
tmp=load(fullfile(pathname,filename),'job');
if(~isfield(tmp,'job'))
    warning('file does not contain a processing pipeline')
    return
end

jobs=tmp.job;
set(handles.listbox_loaded,'UserData',jobs);
update_tree(handles);



% --------------------------------------------------------------------
function uimenu_exportscript_Callback(hObject, eventdata, handles)
% hObject    handle to uimenu_exportscript (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

job=get(handles.listbox_loaded,'UserData');
pipe=nirs.modules.pipelineToList(job);

str = ['% STEP 1 ----  ' pipe{1}.name];
str = sprintf('%s\njob = %s();\n',str,class(pipe{1}));

flds=fields(pipe{1});
lst=find(~ismember(flds,{'name','prevJob'}));
for j=1:length(lst)
    val=getfield(pipe{1},flds{lst(j)});
    if(iscellstr(val))
        val=val{1};
    end
    if(isstr(val))
                val=['''' val ''''];
            end
    if(~isstr(val))
        val=num2str(val);
    end
    str = sprintf('%s   job.% s = %s;\n',str,flds{lst(j)},val);
end

for i=2:length(pipe)
    
    str = sprintf('%s\n\n',str);
    str = sprintf('%s%s\n',str,['% STEP ' num2str(i) ' ----  ' pipe{i}.name ]);
    str = sprintf('%sjob = %s(job);\n',str,class(pipe{i}));
    flds=fields(pipe{i});
    lst=find(~ismember(flds,{'name','prevJob'}));
    for j=1:length(lst)
        val=getfield(pipe{i},flds{lst(j)});
        if(~isa(val,'Dictionary'))
            if(iscellstr(val))
                val=val{1};
            end
            if(isstr(val))
                val=['''' val ''''];
            end
            if(isa(val,'function_handle'))
                val=func2str(val);
                if(~strcmp(val(1),'@'))
                    val=['@' val];
                end
            end
            if(isempty(val))
                val='[]';
            end
            
            if(~isstr(val))
                val=num2str(val);
            end
            str = sprintf('%s   job.% s = %s;\n',str,flds{lst(j)},val);
        else
            str=sprintf('%s   %s=Dictionary();\n',str,flds{lst(j)});
            for k=1:val.count
                val2=val(val.keys{k});
                str = sprintf('%s        %s=%s;\n',str,val.keys{k},class(val2));
                flds2=fields(val2);
                for jj=1:length(flds2)
                    val3=getfield(val2,flds2{jj});
                    if(~isstr(val3));
                        val3=num2str(val3);
                    end
                     str = sprintf('%s             %s.%s=%s;\n',str,val.keys{k},flds2{jj},val3);
                end
                str = sprintf('%s        %s(''%s'')=%s;\n',str,flds{lst(j)},val.keys{k},val.keys{k});
            end
            str=sprintf('%s   job.basis=%s;\n',str,flds{lst(j)});
            
            
            
        end
    end
end


[filename, pathname] = uiputfile('analysis.m', 'Save pipeline script as');
if isequal(filename,0) || isequal(pathname,0)
    return
end
if(exist(fullfile(pathname,filename),'file'))
    delete(fullfile(pathname,filename));
end

str2=sprintf('%% Analysis script\n%%  created on %s\n\n',datestr(now));
system(['echo "' str2 '" > ' fullfile(pathname,filename)]);

str3=job.cite; str4='%Citations:';
for j=1:length(str3)
   str4=sprintf('%s\n%%%s\n',str4,str3{j}(find(double(str3{j}~=10))));
end

system(['echo "' str4 '" >> ' fullfile(pathname,filename)]);

system(['echo "' str '" >> ' fullfile(pathname,filename)]);

edit(fullfile(pathname,filename));


return


% --------------------------------------------------------------------
function uimenu_defaultjob_singlesubject_Callback(hObject, eventdata, handles)
% hObject    handle to uimenu_defaultjob_singlesubject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

jobs=nirs.modules.default_modules.single_subject;
set(handles.listbox_loaded,'UserData',jobs);
update_tree(handles);


% --------------------------------------------------------------------
function uimenu_defaultjob_group_Callback(hObject, eventdata, handles)
% hObject    handle to uimenu_defaultjob_group (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

jobs=nirs.modules.default_modules.group_analysis;
set(handles.listbox_loaded,'UserData',jobs);
update_tree(handles);


% --------------------------------------------------------------------
function uimenu_defaultjob_imagerecon_Callback(hObject, eventdata, handles)
% hObject    handle to uimenu_defaultjob_group (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

jobs=nirs.modules.default_modules.image_recon;
set(handles.listbox_loaded,'UserData',jobs);
update_tree(handles);



% --------------------------------------------------------------------
function uimenu_defaultjob_writepaper_Callback(hObject, eventdata, handles)
% hObject    handle to uimenu_defaultjob_group (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

jobs=nirs.modules.default_modules.write_paper;
set(handles.listbox_loaded,'UserData',jobs);
update_tree(handles);


% --------------------------------------------------------------------
function uimenu_defaultjob_FIR_Callback(hObject, eventdata, handles)
% hObject    handle to uimenu_defaultjob_group (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

jobs=nirs.modules.default_modules.FIR_model;
set(handles.listbox_loaded,'UserData',jobs);
update_tree(handles);


% --- Executes on button press in pushbutton_run.
function pushbutton_run_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

job=get(handles.listbox_loaded,'UserData');
flag=test_job(job);
if(flag)
    job.run([]);
end
try;
    nirs_viewer('uimenu_refresh_Callback');
end

return

function flag = test_job(job)
%TODO
flag=true;


% --------------------------------------------------------------------
function uimenu_changeiterations_Callback(hObject, eventdata, handles)
% hObject    handle to uimenu_changeiterations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 
prompt={'Enter number of iterations for ROC testing'};
name='Iterations';
numlines=1;
defaultanswer={'10'};

answer=inputdlg(prompt,name,numlines,defaultanswer);
 
set(handles.uimenu_changeiterations,'Label',['# Iterations = ' answer{1}]); 
set(handles.uimenu_changeiterations,'Userdata',str2num(answer{1}));
  
   
return


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure

disp('Processing job created in workspace');
job=get(handles.listbox_loaded,'UserData');
assignin('base','job',job)

delete(hObject);
