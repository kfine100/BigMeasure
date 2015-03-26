function varargout = WaveGen(varargin)
% WAVEGEN M-file for WaveGen.fig
%      WAVEGEN, by itself, creates a new WAVEGEN or raises the existing
%      singleton*.
%
%      H = WAVEGEN returns the handle to a new WAVEGEN or the handle to
%      the existing singleton*.
%
%      WAVEGEN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WAVEGEN.M with the given input arguments.
%
%      WAVEGEN('Property','Value',...) creates a new WAVEGEN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before WaveGen_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to WaveGen_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help WaveGen

% Last Modified by GUIDE v2.5 28-Jan-2008 09:03:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @WaveGen_OpeningFcn, ...
                   'gui_OutputFcn',  @WaveGen_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


function WaveGen_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

handles = VerifyCard( handles );                        %Find out which DAQ device is being used
if handles.Dev.DeviceUsed == 0;                               %User wants to exit, or there is error
    WaveGen_CloseRequestFcn(hObject, eventdata, handles)
    return
end

[handles, Success] = Get_DAQ_Parameters( handles );     %Setup hardware card parameters
if ~handles.Dev.Out.HasAOut                                     %Handle error conditions
    errordlg('Card does not report having Analog Output')
    WaveGen_CloseRequestFcn(hObject, eventdata, handles)
    return
end
if Success==0
    errordlg('Error setting up card in Get_DAQ_Parameters')
    WaveGen_CloseRequestFcn(hObject, eventdata, handles)
    return
end

handles = WaveGenParameters(handles);
handles = LoadSettingsFile(handles);
handles = ReadDisplay(hObject, eventdata, handles);
set(handles.WaveGen, 'Name', sprintf('WaveGen v%2.1f: %s', handles.ThisVersion, handles.Dev.DeviceNames))

guidata(hObject, handles);


function varargout = WaveGen_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;



function handles = ReadDisplay(hObject, eventdata, handles) 
%Reads display and updates handles.

handles.Frequency = str2double(get(handles.FrequencyBox, 'String'));
handles.AmpPToP   = str2double(get(handles.AmplitudeBox, 'String'));
handles.Duration  = str2double(get(handles.DurationBox,  'String'));
handles.Offset    = str2double(get(handles.OffsetBox,    'String'));

handles.Frequency = min(max(handles.Frequency,handles.MinFrequency), handles.MaxFrequency);
set(handles.FrequencyBox, 'String', num2str(handles.Frequency))
handles.Dev.Out.SampRate = max( min( handles.NPtsPerCycle*handles.Frequency, handles.Dev.Out.MaxCardRate), handles.Dev.Out.MinCardRate);

handles.AmpPToP = min(max(handles.AmpPToP,0),2*handles.VoltLimits(2));
set(handles.AmplitudeBox, 'String', num2str(handles.AmpPToP))
                                                            %Constrain Offset to remain within voltage limits
handles.Offset    = max(handles.Offset, handles.VoltLimits(1)+handles.AmpPToP/2);
handles.Offset    = min(handles.Offset, handles.VoltLimits(2)-handles.AmpPToP/2);
set(handles.OffsetBox, 'String', num2str(handles.Offset))

if handles.Duration > handles.MaxSingleDuration
    Repeats  = round(handles.Duration/handles.MaxSingleDuration);
    handles.Duration = Repeats *handles.MaxSingleDuration;
    set(handles.DurationBox, 'String', num2str(handles.Duration))
end

if get(handles.SineButton, 'Value') 
    handles.OutputType = 'Sine';
elseif get(handles.SawButton, 'Value')
    handles.OutputType = 'Saw';
else
    handles.OutputType = 'Square'; 
end

guidata(hObject, handles);
return



function EnableControls(handles, Val)
%Enable or disable controls during acquisition
set(handles.FrequencyBox,     'Enable', Val)
set(handles.AmplitudeBox,     'Enable', Val)
set(handles.DurationBox,      'Enable', Val)
set(handles.OffsetBox,        'Enable', Val)

set(handles.SineButton,       'Enable', Val)
set(handles.SawButton,        'Enable', Val)
set(handles.SquareButton,     'Enable', Val)

return



function StartButton_Callback(hObject, eventdata, handles)
% Launches wave generator (and stops it)

if all(get(handles.StartButton, 'BackgroundColor')==handles.Red)
    try
        set(handles.ao, 'StopFcn', '')      %This keeps from doing WaveGen_OpeningFcn upon stop (why??)
        stop(handles.ao)
        delete(handles.ao)
    catch
    end
    set(handles.StartButton,'String','Go')
    set(handles.StartButton,'BackgroundColor',handles.Green)

    EnableControls(handles, 'on')
    return
end

EnableControls(handles, 'off')
set(handles.StartButton,'String','Stop')
set(handles.StartButton,'BackgroundColor',handles.Red)

                                            %Setup DAQ
[handles, Success] = Setup_DAQ(handles, hObject);
set(handles.ao, 'StopFcn', {@WaveGen, 'StartButton_Callback', 0, [], handles})

                                            %Calculate single duration as multiple of period, so no 'glitch' in signal
Period = 1/handles.Frequency;               %Also: Don't make one batch of data bigger than 100 periods
ActualSingleDuration = min(handles.MaxSingleDuration, 100*Period);                                           
ActualSingleDuration = round(ActualSingleDuration/Period)*Period;

if handles.Duration > ActualSingleDuration
    Duration = ActualSingleDuration;
    Repeats  = round(handles.Duration/ActualSingleDuration);
else
    Duration = handles.Duration;
    Repeats  = 1;
end

Arg = linspace(0,2*pi*handles.Frequency*Duration,Duration*handles.Dev.Out.SampRate)';
Arg = Arg(1:end-1);                         %Eliminate last point so each segment fits perfectly
switch handles.OutputType
    case ('Sine')
        Data = (handles.AmpPToP/2)*sin(Arg);
    case ('Saw')
        Data = (handles.AmpPToP/2)*sawtooth(Arg);
    case('Square')
        Data = (handles.AmpPToP/2)*square(Arg);
    otherwise
        warndlg('Unexpected OutputType')
        return
end
Data = Data +handles.Offset;                %Add in offset
if handles.Dev.DeviceUsed~=1                      %If not Fake data
    putdata(handles.ao,Data)
    set(handles.ao,'RepeatOutput',Repeats-1)
                                                %Calculate actual duration of signal and update display
    ActualRepeats  = get(handles.ao, 'RepeatOutput');
    ActualDuration = ActualRepeats*Duration;
    set(handles.DurationBox, 'String', num2str(ActualDuration, '%10.0f'));
                                                %GO GO GO
    start(handles.ao)
end


guidata(hObject, handles);   % Update handles structure
return




function SaveSettingsFile(handles)
%Save configuration settings for next start

Frequency    = handles.Frequency;
Duration     = handles.Duration;
Amplitude    = handles.AmpPToP;
Offset       = handles.Offset;
OutputType   = handles.OutputType;
   
save(handles.SettingsFile, 'Frequency', 'Duration', 'Amplitude', 'Offset', 'OutputType' )           
return




function handles = LoadSettingsFile(handles)
%Loads configuration from settings file
try
    load(handles.SettingsFile, '-mat');
    set(handles.FrequencyBox, 'String', num2str(Frequency))
    set(handles.DurationBox,  'String', num2str(Duration ))
    set(handles.AmplitudeBox, 'String', num2str(Amplitude))
    set(handles.OffsetBox,    'String', num2str(Offset   ))
    if strcmpi(OutputType,'Sine')
        set(handles.SineButton, 'Value', 1)
    elseif strcmpi(OutputType, 'Saw')
        set(handles.SawButton, 'Value', 1)
    else
        set(handles.SquareButton, 'Value', 1)
    end
catch
    errordlg('Error in loading settings file')
end
return


function WaveGen_CloseRequestFcn(hObject, eventdata, handles)
try
    SaveSettingsFile(handles)
catch
end
% daqreset
delete(hObject);
return


