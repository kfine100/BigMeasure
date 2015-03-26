function handles = Run_DAQ( handles, Duration, SampRate, ChanList, nSamp )
%        handles = Run_DAQ( handles, Duration, SampRate, ChanList, nSamp )
% Starts DAQ Card, waits until it stops, and then returns data
%
% Input.......handles........[struc]..........
%       ......Duration.........[1]............time length of samples, in seconds
%       ......SampRate.........[1]............sample rate, in Hz
%       ......ChanList.........[1]............channels to measure
%       ......nSamp............[1]............number of samples to take for each channel
% Output......handles.Data............[nSamp, nChan]..output voltages
%                                               ......-1e6 values indicates get data had a timeout error
%                                               ......-2e6 values indicates stop button has been clicked
%       ......handles.Time............[nSamp].........times corresponding to voltages
%       ......handles.DDateTime.......[string]........absolute time of start, in date string format 31 (reverse order)
%
% Modifications:
%   Dec 2003........add PreTime, which removes first few milliseconds of data, which contains a glitch
%   May-June 2004...Major mod to eliminate Save File, and replace with saving current scan. Several mods.
%                       Includes eliminating Countdown window, Warning message for data timeout (instead
%                       of crashing), and enabling  Stop button during long acquisition.
%   Oct 2009........Modified to deal with multiple devices and multiple object handles.




if datenum(version('-date'))>=733448            %Only for versions R2008a or later
    BigMeasure('MemoryCheck', handles)          %Check to see if enough memory
end
PreTime         = handles.PreTime(handles.Dev.DeviceUsed);      %Time to remove at beginning in seconds
PreSamp         = round(PreTime *SampRate);
nSampW          = nSamp +PreSamp;
                                                %Calculate number of channels for each device, allocate Data
nChan           = histc(handles.Dev.ChanDevices(handles.Screen.DispChanList), 1:handles.Dev.nDevices);
handles.Data    = zeros(nSampW, sum(nChan));

if handles.Dev.DeviceUsed>1
    for iDevice = handles.Dev.nDevices:-1:1
        eval(sprintf('%s%1i%s', 'flushdata(handles.ai', iDevice, ')'))  %Flush device buffers
        eval(sprintf('%s%1i%s',     'start(handles.ai', iDevice, ')'))  %Start device
    end
end
set(handles.TriggerIndicator,'String','Wait')
set(handles.TriggerIndicator,'Visible','on')    %Set Trigger indicator on display
set(handles.TriggerIndicator,'ForegroundColor',handles.Green)
pause(0.01)                                     %Delay so display updates
                                                %Wait for trigger to be received...
while handles.Dev.DeviceUsed>1 && strcmpi(get(handles.ai1,'Logging'),'off') && get(handles.ai1,'SamplesAcquired')==0 ...
                               && all(get(handles.StartScope, 'BackgroundColor')==handles.Red)
    pause(.01)
end
set(handles.TriggerIndicator,'String','Trgd')
set(handles.TriggerIndicator,'ForegroundColor',handles.Yellow)
pause(0.01)                                     %Delay so display updates

                                                %For Trigger Delays longer than MinTimeDisp seconds, show a countdown box
if  handles.Dev.DeviceUsed>1 && handles.Disp.In.TrigDelay>handles.MinTimeDisp...
                             && all(get(handles.StartScope, 'BackgroundColor')==handles.Red)
    set(handles.TimeLeftBox,'Visible','on')
    set(handles.TimeLeftTitle,'Visible','on')
    for t=handles.Disp.In.TrigDelay:-1:handles.MinTimeDisp
        set(handles.TimeLeftBox,'String',num2str(t));
        pause(1)
        if all(get(handles.StartScope, 'BackgroundColor')==handles.Green)   %Stop if "Stop" button has been clicked
            [handles.Data, handles.Time, handles.DDateTime] = StopAcq( handles, ChanList, nSamp );
            return
        end
    end
    set(handles.TimeLeftBox,'Visible','off')
    set(handles.TimeLeftTitle,'Visible','off')
end
                                                                            %Wait for Trigger Delay to pass
if handles.Dev.DeviceUsed>1                                               
    TrigTime = get(handles.ai1,'InitialTriggerTime');
    while all(get(handles.StartScope, 'BackgroundColor')==handles.Red) && etime(clock,TrigTime)<handles.Disp.In.TrigDelay
        pause(0.01)
    end
end

set(handles.TriggerIndicator,'String','Acq')
set(handles.TriggerIndicator,'ForegroundColor',handles.Red)                 %Acquiring data...
pause(0.01) %Delay so display updates
                                %For Duration times longer than MinTimeDisp seconds, show a countdown box
if Duration>handles.MinTimeDisp && all(get(handles.StartScope, 'BackgroundColor')==handles.Red) 
    set(handles.TimeLeftBox,'Visible','on')
    set(handles.TimeLeftTitle,'Visible','on')
    for t=Duration:-1:handles.MinTimeDisp
        set(handles.TimeLeftBox,'String',num2str(t));
        pause(1)
        if all(get(handles.StartScope, 'BackgroundColor')==handles.Green)   %Stop if "Stop" button has been clicked
            [handles.Data, handles.Time, handles.DDateTime] = StopAcq( handles, ChanList, nSamp );
            return
        end
    end
    set(handles.TimeLeftBox,'Visible','off')
    set(handles.TimeLeftTitle,'Visible','off')
end

if all(get(handles.StartScope, 'BackgroundColor')==handles.Green)           %Stop if "Stop" button has been clicked
    [handles.Data, handles.Time, handles.DDateTime] = StopAcq( handles, ChanList, nSamp );
    set(handles.TriggerIndicator,'Visible','off')
    return
end
                                                                            %Indicate data is being read
set(handles.TriggerIndicator,'String','Read')
set(handles.TriggerIndicator,'ForegroundColor',handles.White)
if handles.Dev.DeviceUsed>1                                                 %If there is a DAQ card installed...
	try                                                                     %Because of freq Timeout errors
        wait(handles.ai1, max(2,Duration+PreTime))                          %Wait for acq to stop (this aids to stop when click "Stop")
                                                %Acquire from Device 1
        indStart    =                     1;
        indEnd      = indStart +nChan(1) -1;
        [handles.Data(:,indStart:indEnd), handles.Time, StartTime   ]  = getdata(handles.ai1);
                                                %Acquire from Device 2
        if handles.Dev.nDevices > 1
            indStart    = indEnd             +1;
            indEnd      = indStart +nChan(2) -1;
            nSamplesAcq = get(handles.ai2, 'SamplesAcquired');
            [handles.Data(:,indStart:indEnd)                        ]  = getdata(handles.ai2);
        end
                                                %Acquire from Device 3
        if handles.Dev.nDevices > 2
            indStart    = indEnd             +1;
            indEnd      = indStart +nChan(3) -1;
            [handles.Data(:,indStart:indEnd)                        ]  = getdata(handles.ai3);
        end
                                                %Acquire from Device 4
        if handles.Dev.nDevices > 3
            indStart    = indEnd             +1;
            indEnd      = indStart +nChan(4) -1;
            [handles.Data(:,indStart:indEnd)                        ]  = getdata(handles.ai4);
        end
    catch                                                                   %in case of (frequent) Timeout errors
        [handles.Data, handles.Time, StartTime] = AcqError( handles, ChanList, nSampW );
    end
                                                                            %Remove pre-samples  
	handles.Data                = handles.Data(end-nSamp+1:end,:);                  
	handles.Time                = handles.Time(end-nSamp+1:end)-handles.Time(end-nSamp+1);

    handles.DDateTime           = datestr(StartTime, 31);
else                                                                        %If NO DAQ Card, then Fake data...
    [handles.Data, handles.Time, handles.DDateTime]     = FakeGetData( handles, Duration, nSamp, ChanList );
end

set(handles.TimeWindow, 'String', handles.DDateTime(end-8:end), 'Visible', 'on')

return



function [DataOut, TimeOut, StartTime] = StopAcq( handles, ChanList, nSamp )
% Stops acquisition, and sets values to exit data taking loop

if handles.Dev.DeviceUsed>1
    stop(handles.ai1)
    if handles.Dev.nDevices > 1
        stop(handles.ai2)
    end

    if handles.Dev.nDevices > 2
        stop(handles.ai3)
    end

    if handles.Dev.nDevices > 3
        stop(handles.ai4)
    end
end

DataOut     = -2e6*ones(nSamp,max(ChanList));
TimeOut     = -2e6*ones(nSamp,1);
StartTime   = datestr(now, 31);

set(handles.TimeLeftBox,    'Visible','off')
set(handles.TimeLeftTitle,  'Visible','off')

return




function [DataOut, TimeOut, StartTime] = AcqError( handles, ChanList, nSampW )
% Deals with case where there is a Acquisition error

msgstr          = lasterr;
nSampAcq        = get(handles.ai1,'SamplesAcquired');

msg = sprintf('Problem with getdata on %s\nSamples Acquired =%i out of %i requested, error message is:\n %s',...
    datestr(now), nSampAcq, nSampW,  msgstr);

DataOut         = -1e6*ones(nSampW,max(ChanList));
TimeOut         = -1e6*ones(nSampW,1);
StartTime       = datestr(now, 31);
hOld            = findobj('Tag','Msgbox_ACQ Err');

if ~isempty(hOld)
    delete(hOld)
end
hWarn           = warndlg(msg,'ACQ Err');
%         uiwait(h)

return





function [DataOut, TimeOut, StartTime] = FakeGetData( handles, Duration, nSamp, ChanList )
% Simulates real device(s)

StartTime       = datestr(now, 31);
pause(Duration)
                                %Create time vector
TimeOut         = linspace(0,Duration,nSamp)';
                                %Setup data as random sine waves on all channels
nChan           = length(ChanList);

Amp             = handles.Dev.In.VoltRanges(handles.Disp.In.VoltRange(ChanList))'  .*rand(1, nChan);
Freq            =                   (1/Duration) *100                               *rand(1, nChan);
Phase           =                       2*pi                                        *rand(1, nChan);

DataOut         = repmat(Amp, size(TimeOut,1), 1) .*sin(2*pi*TimeOut*Freq +repmat(Phase, size(TimeOut,1), 1));

return
