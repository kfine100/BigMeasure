function varargout = SaveDialog(varargin)
% SAVEDIALOG M-file for SaveDialog.fig
%      SAVEDIALOG by itself, creates a new SAVEDIALOG or raises the
%      existing singleton*.
%
%      H = SAVEDIALOG returns the handle to a new SAVEDIALOG or the handle to
%      the existing singleton*.
%
%      SAVEDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SAVEDIALOG.M with the given input arguments.
%
%      SAVEDIALOG('Property','Value',...) creates a new SAVEDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SaveDialog_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SaveDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SaveDialog

% Last Modified by GUIDE v2.5 18-Jan-2008 07:19:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SaveDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @SaveDialog_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT






function SaveDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% Initializes dialog box
                                     %Write input values to display
handles.PrevFileSuffixes    = varargin{2};
set(handles.FileSuffixBox,          'String',  handles.PrevFileSuffixes{1})
handles  = DisplayDirectoryName(handles,       varargin(3));
                                    %Load in first comment in old list as first choice for comments
handles.MaxNumSavedComs     = varargin{4};                              
handles.PrevComments1       = varargin{5};
handles.PrevComments2       = varargin{6};
set(handles.Comment1Box,            'String',  handles.PrevComments1{1})
set(handles.Comment2Box,            'String',  handles.PrevComments2{1})

                                    %Load in all old comments to context menus so user can choose with right click
Comm1Menu = uicontextmenu;
for ic = 1:length(handles.PrevComments1)
    CallBack     = sprintf('%s%i%s', 'SaveDialog(''SetMenuItem_Comm1'', guidata(gco),', ic, ')');
    uimenu(Comm1Menu, 'Label', handles.PrevComments1{ic}, 'Callback', CallBack);
end
set(handles.Comment1Box, 'uicontextmenu',Comm1Menu)

Comm2Menu = uicontextmenu;
for ic = 1:length(handles.PrevComments2)
    CallBack     = sprintf('%s%i%s', 'SaveDialog(''SetMenuItem_Comm2'', guidata(gco),', ic, ')');
    uimenu(Comm2Menu, 'Label', handles.PrevComments2{ic}, 'Callback', CallBack);
end
set(handles.Comment2Box, 'uicontextmenu',Comm2Menu)

PrevFileMenu = uicontextmenu;
for ic = 1:length(handles.PrevFileSuffixes)
    CallBack     = sprintf('%s%i%s', 'SaveDialog(''SetMenuItem_PrevFile'', guidata(gco),', ic, ')');
    uimenu(PrevFileMenu, 'Label', handles.PrevFileSuffixes{ic}, 'Callback', CallBack);
end
set(handles.FileSuffixBox, 'uicontextmenu',PrevFileMenu)

handles.Save   = 0;
guidata(hObject, handles);

set(hObject, 'Name', 'File Dialog')

% Make the GUI modal
set(handles.FileDialog,'WindowStyle','modal')

% UIWAIT makes SaveDialog wait for user response (see UIRESUME)
uiwait(handles.FileDialog);



function SetMenuItem_Comm1( handles, ic )
set(handles.Comment1Box,            'String',  handles.PrevComments1{ic})
return

function SetMenuItem_Comm2( handles, ic )
set(handles.Comment2Box,            'String',  handles.PrevComments2{ic})
return

function SetMenuItem_PrevFile( handles, ic )
set(handles.FileSuffixBox,          'String',  handles.PrevFileSuffixes{ic})
return


function handles = DisplayDirectoryName(handles, DirText)
% Makes Directory name look nice 

handles.DirName = DirText;

[outstring,newpos] = textwrap(handles.DirNameBox, DirText);
set(handles.DirNameBox,       'String', outstring )

return


function varargout = SaveDialog_OutputFcn(hObject, eventdata, handles)
% Read display and output arguments
                                %Put current comment as first of PrevComments. Eliminate duplicates, and limit length.
Comm1           = get(handles.Comment1Box,         'String');
in = find(strcmp(handles.PrevComments1, Comm1), 1, 'first');
handles.PrevComments1     = [Comm1, handles.PrevComments1];
if isempty(in)
    handles.PrevComments1 = handles.PrevComments1(1:min([length(handles.PrevComments1), handles.MaxNumSavedComs]));
else
    handles.PrevComments1(in+1)   = [];
end
    
Comm2           = get(handles.Comment2Box,         'String');
in = find(strcmp(handles.PrevComments2, Comm2), 1, 'first');
handles.PrevComments2     = [Comm2, handles.PrevComments2];
if isempty(in)
    handles.PrevComments2 = handles.PrevComments2(1:min([length(handles.PrevComments2), handles.MaxNumSavedComs]));
else
    handles.PrevComments2(in+1)   = [];
end

FileSuffix           = get(handles.FileSuffixBox,   'String');
in = find(strcmp(handles.PrevFileSuffixes, FileSuffix), 1, 'first');
handles.PrevFileSuffixes     = [FileSuffix, handles.PrevFileSuffixes];
if isempty(in)
    handles.PrevFileSuffixes = handles.PrevFileSuffixes(1:min([length(handles.PrevFileSuffixes), handles.MaxNumSavedComs]));
else
    handles.PrevFileSuffixes(in+1)   = [];
end
                                %Place comments in output
varargout{1} = handles.PrevComments1;
varargout{2} = handles.PrevComments2;
varargout{3} = handles.PrevFileSuffixes;
varargout(4) = handles.DirName;
varargout{5} = handles.Save;
guidata(hObject, handles);

FileDialog_CloseRequestFcn(hObject, eventdata, handles)



function FileDialog_CloseRequestFcn(hObject, eventdata, handles)

if isequal(get(handles.FileDialog, 'waitstatus'), 'waiting')
    uiresume(handles.FileDialog);
else
    delete(handles.FileDialog);
end


function FileDialog_KeyPressFcn(hObject, eventdata, handles)

% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'),'escape')
    % User said no by hitting escape
    handles.output = 'No';
    
    % Update handles structure
    guidata(hObject, handles);
    
    uiresume(handles.FileDialog);
end    
    
if isequal(get(hObject,'CurrentKey'),'return')
    uiresume(handles.FileDialog);
end    



function SavePushButton_Callback(hObject, eventdata, handles)
%Exits if DataDirectory exists, setting value of save so measure will save

handles.Save = 1;
guidata(hObject, handles);
uiresume(handles.FileDialog);


function DontSaveButton_Callback(hObject, eventdata, handles)
%Exits, setting value of save so measure will NOT save
handles.Save = 0;
guidata(hObject, handles);
uiresume(handles.FileDialog);


function FindDirButton_Callback(hObject, eventdata, handles)
% Creates dialog box to find data directory

DirName = uigetdir(char(handles.DirName));

if DirName~=0
    handles.DirName = {DirName};
    DisplayDirectoryName(handles, handles.DirName);
end
guidata(hObject, handles);

return






