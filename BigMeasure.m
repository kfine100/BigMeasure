function varargout = BigMeasure(varargin)
% BigMeasure is a GUI to display and save data taken by multi-channel
% digitizers.
%                                   kfine Nov 2007
% v1.1.....DataSaveSetup saved even if halted..................May 2008
% v1.2.....HasAIn and HasAOut added to deal with NI6210........May 2008
% v1.3.....adds labels to channels.............................Jun 2008
% v1.4.....add 200,500,1000 s; bugs corrected:
%                   1) Does not allow no graphs (which sticks)
%                   2) Hdwr chan for single now same as diff
%..............................................................Jul 2008
% v1.5.....includes choice of HwDigital trigger channel
%          corrected bug in ChanTitles with call to guidata in CreatePlotTitle?
%..............................................................Oct 2008
% BigMeasure........complete re-write to work with multiple devices.
%                   also dynamically creates screens...........Oct 2009
%
% Last Modified by GUIDE v2.5 08-Oct-2009 12:38:48
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BigMeasure_OpeningFcn, ...
                   'gui_OutputFcn',  @BigMeasure_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT




function BigMeasure_OpeningFcn(hObject, eventdata, handles, varargin)

set(handles.BigMeasure, 'Name', sprintf('Measure Initializing...'))
handles.output = hObject;

handles = BigMeasureParameters( handles );                  %Parameters specific to BigMeasure
[handles, UseCfgFile, Cfg] = GetConfigFile( handles );      %See if user wants a configuration file

if UseCfgFile                                               %If config is used, load in device values from it
    handles.Dev     = Cfg.Dev;
    handles.Screen  = Cfg.Screen;
else                                                        %If no config, setup from scratch
    handles = GetDevices( handles );                            %Find out which DAQ devices are being used
    if handles.Dev.DeviceUsed == 0;                             %User wants to exit, or there is error
        BigMeasure_CloseRequestFcn(hObject, eventdata, handles)
        return
    end

    [handles, Success] = Get_DAQ_ParametersMulti( handles );    %Setup hardware card parameters
    if ~handles.Dev.In.HasAIn                                   %Handle error conditions
        errordlg('Card does not report having Analog Input')
        BigMeasure_CloseRequestFcn(hObject, eventdata, handles)
        return
    end
    if Success==0
        errordlg('Error setting up card in Get_DAQ_Parameters')
        BigMeasure_CloseRequestFcn(hObject, eventdata, handles)
        return
    end
end
                                                            %Setup display to reflect device using handles.Dev
handles = InitializeDisplay(hObject, handles);              %Also, set display default values in handles.Disp
if UseCfgFile                                               %If config file used, overwrite default values in 
    handles.Disp    = Cfg.Disp;                             %  handles.Disp
end
WriteToDisplay( handles );                                  %Write values in handles onto display

handles = ReadFromDisplay(hObject, handles );               %Corrects controls like duration
                                                            %Put device(s) used and version in title bar
TitText = sprintf('BigMeasure v%2.1f: %s', handles.ThisVersion, handles.Dev.DeviceNames{1});
for iDevice = 1:handles.Dev.nDevices
    TitText = [TitText, sprintf(', %s', handles.Dev.BoardIDs{iDevice})];
end
set(handles.BigMeasure, 'Name', TitText)
% 
% if handles.Dev.DeviceUsed==2 && handles.Dev.Out.HasAOut     %If NI card with Analog Out, can do WaveGen
%     set(handles.WaveGenButton, 'Visible', 'on')
% end

guidata(hObject, handles);                                  %Update handles structure

return



function varargout = BigMeasure_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;





function [handles, Success] = InitializeDisplay(hObject, handles)
% Intializes menu of display to correct values for device(s) used. Also, sets default values of display controls.

set(handles.TriggerIndicator,   'visible', 'off')
set(handles.TimeWindow,         'visible', 'off')

                            %Setup trigger box************************************************
set(handles.TrigSlopeBox,    'String', handles.Dev.In.TrigSlopes)           %Slope... 
handles.Disp.In.TrigSlope   =       1;                                      %Default value
set(handles.TrigTypeBox,     'String', handles.Dev.In.TrigTypes)            %Type... (Immediate/HWDigital...)
Ind                         = find(strcmp(handles.Dev.In.TrigTypes, 'Immediate'), 1, 'first');
if isempty(Ind)                                                             %Default is immediate
    handles.Disp.In.TrigType    =       1;
else
    handles.Disp.In.TrigType    =  Ind(1);
end
set(handles.DigTrigSourceBox,'String', handles.Dev.In.DigTrigSources)       %Dig sources: PFI0-9
handles.Disp.In.TrigSource  =       1;                                      %Default value
set(handles.TrigModeBox,     'String', {'Continuous', 'Single'})            %Trig Mode choices
handles.Disp.In.TrigMode    =       2;                                      %Default value is "Continuous"
handles.Disp.In.TrigLevel   =       0;                                      %Default trigger level in volts
handles.Disp.In.TrigDelay   =       0;                                      %Default trigger delay in secs

                             %Setup Sampling box**********************************************                                                                  
set(handles.InputTypeBox,    'String', handles.Dev.In.AvailInputTypes)
handles.Disp.In.InputType   =    min(3,length(handles.Dev.In.AvailInputTypes));    %Default index (differential) of input type used
set(handles.nSampControl,    'SliderStep', [1 1]/(length(handles.nSamples)-1))
set(handles.nSampControl,    'Max',               length(handles.nSamples)   )
set(handles.nSampControl,    'Min',                             1            )
handles.Disp.In.nSampIndex  =   1;                                          %Default n samples is 500
set(handles.DurationControl, 'SliderStep', [1 1]/(length(handles.DurText) -1))
set(handles.DurationControl, 'Max',               length(handles.DurText)    )
set(handles.DurationControl, 'Min',                             1            )
handles.Disp.In.DurIndex    =   8;                                          %Default duration is 1 second

                             %Setup Memory box************************************************
if datenum(version('-date'))>=733448    %Memory statistics only for versions R2008a or later                             
    MemOn = 'on';
else
    MemOn = 'off';
end
set(handles.MemoryText,      'Visible', MemOn)
set(handles.MemUsedText,     'Visible', MemOn)
set(handles.MemorySlashText, 'Visible', MemOn)
set(handles.MemAvailText,    'Visible', MemOn)

                             %Load nChanBox***************************************************
indLast         = find(numel(handles.Dev.In.HWChansDiff) > handles.ScrSet.AvailChanMax, 1, 'last') +1;
indLast         = min([indLast    length(handles.ScrSet.AvailChanMax)]);  
set(handles.nChanBox, 'String', num2str(handles.ScrSet.AvailChanMax(1:indLast)) )

if ~isfield(handles.Disp.In, 'nChanIndex')      %Setup if doesn't exist
    handles.Disp.In.nChanIndex  = indLast;
else                                            %Otherwise be sure does not exceed number of strings in box
    handles.Disp.In.nChanIndex  = min([handles.Disp.In.nChanIndex   indLast]);
end


                             %Create channel graphs and controls******************************
if ~isfield(handles, 'Screen')                              %Set default for num of chans, if not loaded from cfg
    handles.Screen.DispChanMax  = min([numel(handles.Dev.In.HWChansDiff)  handles.ProgramChMax]);
end

                                                            %Create all channel objects if necessary
[handles, Success] = CreateChannelPlots( handles );
if ~Success
    return
end
                                                            %Setup channel sliders, set default values
handles.Disp.In.VoltRange   = size(handles.Dev.In.VoltRanges,1)*ones(handles.Screen.DispChanMax,1);
handles.Disp.In.OnState     = ones(handles.Screen.DispChanMax,1);
handles.Screen.DispChanList = find(handles.Disp.In.OnState);

for ic=1:handles.Screen.DispChanMax
    set(handles.Chan.ChanSlider(ic), 'SliderStep', [1/(size(handles.Dev.In.VoltRanges,1)-1)    1] )
    set(handles.Chan.ChanSlider(ic), 'Max',               size(handles.Dev.In.VoltRanges,1)       )
    set(handles.Chan.ChanSlider(ic), 'Min',                 1                                     )
end

return




function handles = CreatePlotTitle(Chan, handles)
%Puts title onto plot. Sets up callback for future modification

xPos        = 0.5;
yPos        = 0.9;
h = text(xPos, yPos, handles.Disp.ChanTitles{Chan},...
    'HorizontalAlignment', 'center',                'Units', 'normalized',              'FontSize', 9,          ...
    'Color', 'r',                                   'FontWeight', 'Bold',               'Interpreter', 'none',  ...
    'Tag',                  ['Ch', num2str(Chan,'%02d'), 'Title'],...               %This Tag allows ChangeTitle to read channel number
    'Parent',               handles.Chan.ChanAxis(Chan),...                              %Attach to correct axis
    'ButtonDownFcn',        'BigMeasure(''ChangeTitle'',gcbo,guidata(gcbo))');      %When clicked, ChangeTitle will be called
handles.ChannelTitle(Chan) = h;

return



function ChangeTitle(hObject, handles)
% Allows user to enter title for channel, to be displayed on plot and recorded in data file.
                            %Extract channel number, encoded in Tag when title was created.
CallTag  = get(hObject, 'Tag');
ic      = str2double(CallTag(3:4));
                            %Create dialog box to ask for new title
ChanTitle = char(inputdlg(['Input title for Channel ', num2str(ic)], 'Channel Title', 1, {handles.Disp.ChanTitles{ic}}));

if isempty(ChanTitle)       %Case where cancel was input
    return
end
                            %Set channel title to new value
set(handles.ChannelTitle(ic), 'String', ChanTitle)
handles.Disp.ChanTitles{ic} = ChanTitle;

guidata(hObject, handles);  % Update handles structure

return




function WriteToDisplay( handles )
% Reads values in handles and updates display to match them

                            %Write to trigger box*********************************************
set(handles.TrigSlopeBox,    'Value',   handles.Disp.In.TrigSlope)          %Slope... 
set(handles.TrigTypeBox,     'Value',   handles.Disp.In.TrigType)           %Type... (Internal/External)
set(handles.DigTrigSourceBox,'Value',   handles.Disp.In.TrigSource)         %Dig sources: PFI0-9
set(handles.TrigModeBox,     'Value',   handles.Disp.In.TrigMode)           %Trig Mode choices
                                                                            %Trig level and delay
set(handles.TrigLevelBox,    'String',  num2str(handles.Disp.In.TrigLevel, '%7.3f'))
set(handles.TrigDelayBox,    'String',  num2str(handles.Disp.In.TrigDelay, '%8.3f'))


                             %Write to  nChanBox**********************************************
set(handles.nChanBox, 'Value', handles.Disp.In.nChanIndex)


                             %Write to Sampling box*******************************************                                                                
set(handles.InputTypeBox,    'Value',       handles.Disp.In.InputType                       )
set(handles.nSampControl,    'Value',       handles.Disp.In.nSampIndex                      )
set(handles.nSampValue,      'String',      handles.nSamplesText{handles.Disp.In.nSampIndex})
set(handles.DurationControl, 'Value',       handles.Disp.In.DurIndex                        )
[Duration, DurIndex] = GetDuration( handles );  %Writes duration to DurationValue box


                             %Write to graphs and controls************************************
for ic=1:handles.Screen.DispChanMax
    set(handles.Chan.ChanSlider(ic), 'Value',               handles.Disp.In.VoltRange(ic)          )
    xlim(handles.Chan.ChanAxis(ic), [0  Duration]);
    ylim(handles.Chan.ChanAxis(ic), handles.Dev.In.VoltRanges(handles.Disp.In.VoltRange(ic))*[-1 1]);
    set(handles.ChannelTitle(ic), 'String', handles.Disp.ChanTitles{ic});
    set(handles.Chan.ChanOnButton(ic), 'Value',  handles.Disp.In.OnState(ic));
end
ChannelControlsVisibility( handles )                        %Make graphs visible or not

return





function handles = ReadFromDisplay(hObject, handles )
% Reads values from display and updates handles values to match.

                                                    %If nChan Max has been changed, screen might need to be redrawn
nChanMaxOld                     = handles.ScrSet.AvailChanMax(handles.Disp.In.nChanIndex);
handles.Disp.In.nChanIndex      = get(handles.nChanBox, 'Value');
nChanMax                        = handles.ScrSet.AvailChanMax(handles.Disp.In.nChanIndex);
if nChanMax ~= nChanMaxOld
    handles.Screen.DispChanMax  = nChanMax;
    [handles, Success]          = InitializeDisplay(hObject, handles);
    WriteToDisplay( handles )                       %Write new settings to display
end

                                                    %Read which channels are active
for ic = 1:handles.Screen.DispChanMax
    handles.Disp.In.OnState(ic)     =   get(handles.Chan.ChanOnButton(ic), 'Value');
end
                                                    %Set active channels to match list
handles.Screen.DispChanList         = find(handles.Disp.In.OnState);
                                                    %Make sure at least one channel is on
if isempty(handles.Screen.DispChanList)
    handles.Disp.In.OnState(1)      =       1;
end

handles = UpdateTrigger( handles );                 %SetupTrigger
handles = UpdateScopeTBase(handles);                %Make Duration value correspond to slider control
 
                                                    %Update x, y limits, titles on channel graphs
for ic = 1:handles.Screen.DispChanMax
    TimeRange                       = [0 GetDuration( handles )];
    set(handles.Chan.ChanAxis(ic), 'XLim', TimeRange)
    
    handles.Disp.In.VoltRange(ic)   = get(handles.Chan.ChanSlider(ic),      'Value' );
    handles.Disp.ChanTitles{ic}     = get(handles.ChannelTitle(ic),         'String');
end
                                                    %Write BACK to display. This is necessary because some objects have
WriteToDisplay( handles )                           %  changed, e.g., the axes ylimits when voltage slider is changed.
guidata(hObject, handles);                          % Update handles structure

return




function handles = UpdateTrigger( handles )
% Reads trigger settings on display and sets their values in handles

set(handles.TriggerIndicator,'Visible','off')

                                                                                    %Read trigger Slope, Type, Dig Source
handles.Disp.In.TrigSlope       = get(handles.TrigSlopeBox,       'Value');
handles.Disp.In.TrigType        = get(handles.TrigTypeBox,        'Value');
handles.Disp.In.TrigSource      = get(handles.DigTrigSourceBox,   'Value');

handles.Disp.In.TrigDelay       = str2double(get(handles.TrigDelayBox, 'String'));  %Delay...

handles.Disp.In.TrigMode        = get(handles.TrigModeBox,'Value');                 %Mode (Continuous/Single)

                                                                                    %Get level, make sure in range
handles.Disp.In.TrigLevel       = str2double( get(handles.TrigLevelBox, 'String'));
VLimit                          = handles.Dev.In.VoltRanges(handles.Disp.In.VoltRange(handles.Screen.DispChanList(handles.Dev.In.AnalogTrigChan)));
handles.Disp.In.TrigLevel       = max(min(handles.Disp.In.TrigLevel, VLimit), -VLimit);
set(handles.TrigLevelBox, 'String', num2str(handles.Disp.In.TrigLevel))

                                                        %Turn trigger control visibility on and off to match conditions
TrigControlsVisibility(handles)
   
return




function TrigControlsVisibility( handles )
% Turns visibility of trigger controls on or off, depending on trigger state.
%Trig delay unsupported for moment

switch handles.Dev.In.TrigTypes{handles.Disp.In.TrigType}
    case('Immediate')   %Set.........Slope....Dig Source...Trig level....Delay (Unsupported now)
        Val                =    {   'off',      'off',      'off',          'off'   };
    case('HwDigital')
        Val                =    {   'on',       'on',       'off',          'off'   };
    case('HwAnalogChannel')
        Val                =    {   'on',       'off',      'on',           'off'   };
    otherwise
        errordlg('Unsupported trigger type')
        return
end

set(handles.TrigSlopeTitle,   'Visible', Val{1})
set(handles.TrigSlopeBox,     'Visible', Val{1})
set(handles.DigSourceText,    'Visible', Val{2})
set(handles.DigTrigSourceBox, 'Visible', Val{2})
set(handles.TrigLevelTitle,   'Visible', Val{3})
set(handles.TrigLevelBox,     'Visible', Val{3})
set(handles.TrigLevelUnits,   'Visible', Val{3})
set(handles.TrigDelayTitle,   'Visible', Val{4})
set(handles.TrigDelayBox,     'Visible', Val{4})
set(handles.TrigDelayUnits,   'Visible', Val{4})

return



function MemoryCheck(handles)
% Checks available memory for arrays. Only seems to work for Matlab version R2008a (or later).

[userview systemview] = memory;
MaxBytes              = userview.MaxPossibleArrayBytes;
BytesPerWord          = 8;
nChans                = length(handles.Screen.DispChanList);
DataArraySize         = handles.nSamples(handles.Disp.In.nSampIndex) * BytesPerWord *nChans;
nSampIndex            = round(get(handles.nSampControl,'Value'));

set(handles.nSampValue,   'String', handles.nSamplesText{nSampIndex});      %Set value in window
set(handles.MemUsedText,  'String', num2str(DataArraySize/1e6, '%8.0f'))
set(handles.MemAvailText, 'String', num2str(MaxBytes/1e6,      '%8.0f'))

if DataArraySize > MaxBytes
    msg = sprintf('Memory limit of %8.0f MBytes exceeded.\nRemove channels or free memory for more samples', MaxBytes);
    warndlg(msg,'Not enough memory', 'modal')
end

return



function handles = UpdateScopeTBase(handles)
%Reads Duration and nSamples from screen and updates handles. Keeps sampling rate in valid range for device.
                                                                        %Update InputType
handles.Disp.In.InputType   = get(handles.InputTypeBox,'Value');
                                                                        %Update nSamp
handles.Disp.In.nSampIndex  = get(handles.nSampControl,'Value');
nSamp                       = handles.nSamples(handles.Disp.In.nSampIndex);             %Read value
set(handles.nSampValue, 'String', handles.nSamplesText{handles.Disp.In.nSampIndex});    %Set value in window
                                                                        %Check to see if memory is exceeded
if datenum(version('-date'))>=733448                                    %Only for versions R2008a or later
    MemoryCheck(handles)
end
                                                                        %Make sure samp rate is supported by device...
[Duration, DurIndex]        = GetDuration( handles );                   %Find max number of channels on devices
MaxNChan                    = max(histc(handles.Dev.ChanDevices(handles.Screen.DispChanList), 1:handles.Dev.nDevices));
                                                                        %Use this to calc peak aggregrate sample rate
AggSampRate                 = (nSamp/Duration) *MaxNChan;
DurIndexMax                 = length(handles.DurText);
                                                                        %Set duration increasing longer until
while AggSampRate>handles.Dev.In.MaxCardRate && DurIndex<=DurIndexMax   % valid aggregate sample rate is reached
    set(handles.DurationControl, 'Value', DurIndex+1)
    [Duration, DurIndex]    = GetDuration( handles );
    AggSampRate             = (nSamp /Duration) *MaxNChan;
end
SampRate                    = AggSampRate/MaxNChan;
handles.Disp.In.DurIndex    = get(handles.DurationControl, 'Value');
set(handles.SampleRateValue, 'String', num2str(SampRate, '%10.0f'))     %Set sample rate indicator (not aggregate!)

return





function [Duration, DurIndex] = GetDuration( handles )
% Gets current duration value in by reading Duration control on display.

DurIndex = round(get(handles.DurationControl,'Value'));
Text     = handles.DurText(DurIndex,:);
set(handles.DurationValue,'String',Text)
Duration = sscanf(Text,'%f');
if strfind(Text,'mS')
    Duration = Duration*.001;
end

return





function ChannelControlsVisibility( handles )
% Turns visibility of individual channel controls on and off. Used with On/Off Radio buttons.

for ic = 1:handles.Screen.DispChanMax
    if handles.Disp.In.OnState(ic) == 1
        set(handles.Chan.ChanAxis(ic),                          'Visible', 'on' )
        set(handles.ChannelTitle(ic),                           'Visible', 'on' )
%         set(findall(handles.Chan.ChanAxis(ic), 'Type', 'line'), 'Visible', 'on' )
    else
        set(handles.Chan.ChanAxis(ic),                          'Visible', 'off')
        set(handles.ChannelTitle(ic),                           'Visible', 'off')
%         set(findall(handles.Chan.ChanAxis(ic), 'Type', 'line'), 'Visible', 'off')
        delete(findall(handles.Chan.ChanAxis(ic), 'Type', 'line'))
    end
end

return



function EnableControls(handles, Val)
%Enable or disable controls during acquisition. Used to disable controls that should not be clicked while running.

set(handles.TrigTypeBox,                'Enable', Val)
set(handles.DigTrigSourceBox,           'Enable', Val)
set(handles.TrigModeBox,                'Enable', Val)
set(handles.TrigLevelBox,               'Enable', Val)
set(handles.TrigDelayBox,               'Enable', Val)
set(handles.TrigSlopeBox,               'Enable', Val)
set(handles.DurationValue,              'Enable', Val)
set(handles.DurationControl,            'Enable', Val)
set(handles.nSampValue,                 'Enable', Val)
set(handles.nSampControl,               'Enable', Val)
set(handles.InputTypeBox,               'Enable', Val)
set(handles.nChanBox,                   'Enable', Val)
set(handles.SaveConfigButton,           'Enable', Val)
set(handles.RecallConfigButton,         'Enable', Val)

for ic=1:handles.Screen.DispChanMax
    set(handles.Chan.ChanSlider(ic),    'Enable',   Val)
    set(handles.Chan.ChanOnButton(ic),  'Enable',   Val)
end

if strcmpi(Val,'on')                %It is necessary to reset slider controls after disable (why??)
    set(handles.DurationControl,    'Value',round(get(handles.DurationControl,  'Value')))
    set(handles.nSampControl,       'Value',round(get(handles.nSampControl,     'Value')))
end

return





function StartScope_Callback(hObject, eventdata, handles)
% Runs (or Stops) Scope mode; MAIN DATA TAKING SUBROUTINE.
                                            %Case where "Stop" button has been clicked
if all(get(handles.StartScope, 'BackgroundColor')==handles.Red)
    EnableControls(handles, 'on')           %Turn back on controls
    set(handles.StartScope,'String','Go')
    set(handles.StartScope,'BackgroundColor',handles.Green)
    set(handles.TriggerIndicator,'Visible','off')
    if handles.TakenData                    %Turn on file button. If 'Single' have not taken data
        handles.TakenData = false;
        set(handles.SaveFileButton,'Visible','on')
    end
    return
end

set(handles.StartScope,'String','Stop')
set(handles.StartScope,'BackgroundColor',handles.Red)

set(handles.SaveFileButton,'Visible','off')
EnableControls(handles, 'off')          %Turn off controls while running

handles.TakenData = false;
                                        %Make sure handles are up to date
handles             = ReadFromDisplay(hObject, handles );
nSamp               = handles.nSamples(handles.Disp.In.nSampIndex);
Duration            = 0;

                                        %Data taking loop........................................................
while all(get(handles.StartScope, 'BackgroundColor')==handles.Red)
    
    nSampNew        = handles.nSamples(handles.Disp.In.nSampIndex);
    DurationNew     = GetDuration( handles );
    if Duration ~= DurationNew || nSamp ~= nSampNew         %Reset digitizer if a change
        nSamp                       = nSampNew;             %Load in new values
        Duration                    = DurationNew;

        handles.Dev.In.SampRate     = nSamp /Duration;      %Calculate new sample rate and load it
        [handles, Success]          = Setup_DAQ(handles, hObject );
        
        WriteToDisplay( handles );                          %Update display to reflect any changes made by Setup_DAQ
        if Success == 0                                     %Case where there was a problem
            StartScope_Callback(hObject, eventdata, handles)    %This will exit GO
            return
        end
    end
                                                            %Get data
    handles = Run_DAQ( handles, Duration, handles.Dev.In.SampRate, handles.Screen.DispChanList, nSamp);  
    
    if handles.Data(1,1) == -1e6        %handle case of a timeout error (repeat loop)
        handles  = UpdateScopeTBase(handles);               %Reset sampling values
        continue
    end
    
    if handles.Data(1,1) == -2e6                            %Return if Stop button has been clicked
        return
    end
    
    handles = SaveDataSetup(handles);                       %Save settings for File Save (if done, will have current settings)
    handles.TakenData = true;                               %Turn on taken data flag
    guidata(hObject, handles);
    handles.nSampData = nSamp;
    for ic=1:length(handles.Screen.DispChanList)            %Plot and process each channel
        iChan                   = handles.Screen.DispChanList(ic);
                                                            %Do plot and label it
        axes(handles.Chan.ChanAxis(iChan))
        handles.pHandle(iChan)  = plot(handles.Time, handles.Data(:,ic),           ...
            'ButtonDownFcn',    'BigMeasure(''ExpandChannel'', gco, guidata(gco))',...
            'Tag',              sprintf('ChanAxis%02i',  iChan));
        grid on  
        handles                 = CreatePlotTitle(iChan, handles);
        
        ylim(handles.Dev.In.VoltRanges(handles.Disp.In.VoltRange(iChan))*[-1 1]);
        xlim([0 Duration]);
        drawnow       
    end
    if handles.Disp.In.TrigMode == 2                        %Stop acq after one trigger if in Single mode
        StartScope_Callback(hObject, eventdata, handles)
    end
    set(handles.TriggerIndicator,'Visible','off')           %Turn off trigger state indicator
end                                                         %End of data taking loop............................
                                        
set(handles.SaveFileButton,'Visible','on')

guidata(hObject, handles);   % Update handles structure
return







function handles = SaveDataSetup(handles)
% Saves front panel settings in case "Save File" button is pushed. This way,
%  settings at time of data are stored in case front panel is changed before file save.

                                                    %Trigger Type
Index                       = get(handles.TrigTypeBox,   'Value' );  
Strings                     = get(handles.TrigTypeBox,   'String' ); 
handles.DataSetup.TrigType  = Strings{Index}; 
                                                    %Trigger source
Index                       = get(handles.DigTrigSourceBox,   'Value' );
Strings                     = get(handles.DigTrigSourceBox,   'String' );
if isempty(Index)
    handles.DataSetup.DigTrigSource = 'none';
elseif ischar(Strings)
    handles.DataSetup.DigTrigSource = Strings;
else
    handles.DataSetup.DigTrigSource = Strings{Index};
end
                                                    %Trigger Mode
Index   = get(handles.TrigModeBox,   'Value' );    
Strings = get(handles.TrigModeBox,   'String' );   
handles.DataSetup.TrigMode   = Strings{Index};
                                                    %Trigger Level
handles.DataSetup.TrigLevel  = handles.Disp.In.TrigLevel;
                                                    %Trigger Slope
Index   = get(handles.TrigSlopeBox,   'Value' );      
Strings = get(handles.TrigSlopeBox,   'String' );     
handles.DataSetup.TrigSlope  = Strings{Index};    
                                                    %Trigger Delay
handles.DataSetup.TrigDelay  = str2double(get(handles.TrigDelayBox,    'String'));
                                                    %Input Type, Duration, nSamp
handles.DataSetup.InputType  = handles.Dev.In.AvailInputTypes{handles.Disp.In.InputType};
handles.DataSetup.Duration   = GetDuration( handles );
handles.DataSetup.nSamp      = handles.nSamples(handles.Disp.In.nSampIndex);                                              
                                                    %Channel list, VoltRanges, Channel Titles
handles.DataSetup.InChanList = handles.Screen.DispChanList;   
handles.DataSetup.VoltRanges = handles.Dev.In.VoltRanges(handles.Disp.In.VoltRange(handles.Screen.DispChanList))*[-1 1];
handles.DataSetup.ChanTitles = handles.Disp.ChanTitles(handles.Screen.DispChanList);

return




function SaveFileButton_Callback(hObject, eventdata, handles)
%Launches SaveFile window to store comments, and then saves file

                                            %Call SaveDialog; the first arg is a dummy so does not think is subfunction
[handles.Disp.PrevComm1, handles.Disp.PrevComm2, handles.Disp.PrevFileSuffix, handles.Disp.DataDirName, Save] =...
    SaveDialog(1, handles.Disp.PrevFileSuffix, handles.Disp.DataDirName, handles.MaxNumSavedComs, handles.Disp.PrevComm1, handles.Disp.PrevComm2);
                                            %Current comments are returned as first entry in cell array
    Comm1 = handles.Disp.PrevComm1{1};
    Comm2 = handles.Disp.PrevComm2{1};

if Save && isfield(handles, 'DataSetup')
                                                    %Create filename
    FileName = sprintf('%s_%s.mat', strrep(strrep(handles.DDateTime, ':', '-'),' ', '_'), handles.Disp.PrevFileSuffix{1});
    FullFileName = fullfile(handles.Disp.DataDirName, FileName);
                                                    %Computer, software information
    [status, ComputerID] = dos('hostname');
    Version              = handles.ThisVersion;
    for iDevice=1:handles.Dev.nDevices
        DevNames{iDevice}   = [handles.Dev.DeviceNames{1}, ': ', handles.Dev.BoardIDs{iDevice}];
    end
    DataDateTime         = handles.DDateTime;       %Time data was taken
    SaveDateTime         = datestr(now, 31);        %Time file was saved
                                                    %Channel info
    InChanList           = handles.DataSetup.InChanList;
    ChanTitles           = handles.DataSetup.ChanTitles;
                                                    %Data
    DataOut              = handles.Data;
    Time                 = handles.Time;
                                                    %Trigger setup
    TrigType             = handles.DataSetup.TrigType;     
    TrigMode             = handles.DataSetup.TrigMode;
    TrigLevel            = handles.DataSetup.TrigLevel;
    TrigDelay            = handles.DataSetup.TrigDelay;      
    TrigSlope            = handles.DataSetup.TrigSlope;      
    DigTrigSource        = handles.DataSetup.DigTrigSource;
                                                    %Input settings
    Duration             = handles.DataSetup.Duration;
    nSamp                = handles.DataSetup.nSamp;
    InputType            = handles.DataSetup.InputType;
    VoltRanges           = handles.DataSetup.VoltRanges;
    
    FileSuffix           = handles.Disp.PrevFileSuffix{1};     
                                                    %Write file
    if exist(handles.Disp.DataDirName, 'dir')~=7
        mkdir(handles.Disp.DataDirName);
    end
    
    try
        save(FullFileName, 'ComputerID',        'Version',          'DataDateTime',     'SaveDateTime',     'Comm1',    ...
                           'Comm2',             'TrigType',         'DigTrigSource',    'TrigMode',         'TrigDelay',...
                           'TrigSlope',         'TrigLevel', ...
                           'Duration',          'nSamp',            'VoltRanges',       'InChanList',                   ...
                           'FileSuffix',        'Time',             'DataOut',          'DevNames',         'InputType',...
                           'ChanTitles'    );
                           
        [outstring,newpos] = textwrap(handles.SavedFile, {FullFileName});
        set(handles.SavedFile, 'String', outstring);
        set(handles.SaveFileButton,'Visible','off')
    catch
        rethrow(lasterror)
        warndlg('No data file saved')
    end
else
    warndlg('No data file saved')
    return      %This return avoids updating handles, and keeping lastest file prefix
end
guidata(hObject, handles);   % Update handles structure

return






function ExpandChannel(hObject, handles)
%Responds to Expand button and calls a routine to  make separate plot of channel for elementary data analysis

figBase  = 100;
                                    %Find out which channel called by looking at tag
CallTag  = get(hObject, 'Tag');
iChan    = str2double(CallTag(end-1:end));
ic       = find(handles.Screen.DispChanList==iChan);
figNum   = figBase +iChan;
                                    %Return if no data to plot
if ~isfield(handles, 'Time') || isempty(ic) || ic > size(handles.Data,2)      
    errordlg('No data to plot')
    return
end
                                    %Create figure with number corresponding to channel
figure(figNum), clf,
set(gcf, 'Name', sprintf('Channel %2.0f', iChan))
                                    %Do time series plot and label it
subplot(2,1,1)
plot(handles.Time, handles.Data(:,ic),'b-'); grid on;  
text = sprintf('Channel %i: %s,  %s', iChan, handles.Disp.ChanTitles{iChan}, handles.DDateTime);
title(text, 'Interpreter', 'none');

xlabel('Time (Secs)');
ylabel('Volts');

subplot(2,1,2)
[Pxx, freq] = pwelch(handles.Data(:,ic), [], [], round(size(handles.Data,1)/handles.PSD_Divisor), handles.Dev.In.SampRate);

plot(freq, 10*log10(Pxx), 'b-'), grid on
xlabel('Frequency (Hz)')
ylabel('Power / Hz (dB)')

return


function LaunchWaveGen
% Launches WaveGen application from BigMeasure

WaveGen

return




function SaveConfigButton_Callback(hObject, eventdata, handles)
% Saves .cfg file of current configuration for later recall

FilterSpec      = ['*',handles.ConfigFileExt];
DefaultName     = fullfile(handles.CfgDirName, ['Default', handles.ConfigFileExt]);
[FileName,PathName,FilterIndex] = uiputfile(FilterSpec, 'Save Config File', DefaultName);

Dev         = handles.Dev;
Disp        = handles.Disp;
Screen      = handles.Screen;

if FileName ~= 0
    save(fullfile(PathName, FileName), 'Dev', 'Disp', 'Screen')
end

return




function RecallConfigButton_Callback(hObject, eventdata, handles)
% Recalls .cfg file and loads into display

[handles, UseCfgFile, Cfg] = GetConfigFile( handles );
if UseCfgFile
    handles.Dev     = Cfg.Dev;
    handles.Screen  = Cfg.Screen;
                                                                %Setup display to reflect device using handles.Dev
    handles = InitializeDisplay(hObject, handles);              %Also, set display default values in handles.Disp
    handles.Disp    = Cfg.Disp;

    WriteToDisplay( handles );                                  %Write values in handles onto display
    handles = ReadFromDisplay(hObject, handles );               %Corrects controls like duration
                                                                %Put device(s) used and version in title bar
    TitText = sprintf('BigMeasure v%2.1f: %s', handles.ThisVersion, handles.Dev.DeviceNames{1});
    for iDevice = 1:handles.Dev.nDevices
        TitText = [TitText, sprintf(', %s', handles.Dev.BoardIDs{iDevice})];
    end
    set(handles.BigMeasure, 'Name', TitText)
end
guidata(hObject, handles);   % Update handles structure

return






function BigMeasure_CloseRequestFcn(hObject, eventdata, handles)
% Clean up and shut down program
                                    %Save config in Last Config file
LastCfgFullname = fullfile(handles.CfgDirName, handles.LastCgfName);
Dev         = handles.Dev;
Disp        = handles.Disp;

if isfield(handles, 'Screen')       %If user exits immmediately, handles.Screen does not exist; do not save config
    Screen      = handles.Screen;

    if exist(handles.CfgDirName, 'dir') == 7
        save(LastCfgFullname, 'Dev', 'Disp', 'Screen')
    end
end
                                    %Delete BigMeasure figure
delete(hObject);
return
