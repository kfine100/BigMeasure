function [handles, Success] = Setup_DAQ(handles, hObject)
%        [handles, Success] = Setup_DAQ(handles, hObject)
% Sets up DAQ devices
%
% Outputs........handles........structure
%        ........Success........1 if successful, 0 if not
% kfine Feb 2008
% Modified for BigMeasure           kfine Oct 2009

Success = 0;                %Will change to 1 if successful
if handles.Dev.DeviceUsed==1
    [handles, Success] = Setup_Fake(   hObject, handles);
elseif handles.Dev.DeviceUsed==2
    [handles, Success] = Setup_DAQ_NI( hObject, handles);
else
    errordlg(['Unexpected value of handles.Dev.DeviceUsed:', handles.Dev.DeviceUsed])
end

return




function [handles, Success] = Setup_Fake(hObject, handles)
% Sets up fake device
ai.TriggerDelay    = 0;
ai.SamplesAcquired = handles.nSamples(handles.Disp.In.nSampIndex);
handles.ai1        = ai;
handles.SampRate   = handles.nSamples(handles.Disp.In.nSampIndex) /BigMeasure('GetDuration', handles );

Success = 1;

return




function [handles, Success] = Setup_DAQ_NI(hObject, handles)
% Sets up National Instruments devices


                                %SETUP ANALOG INPUT................................................
                                
                                %Find max number of channels of any device (used for limiting sample rate)
MaxNChan                = max(histc(handles.Dev.ChanDevices(handles.Screen.DispChanList), 1:handles.Dev.nDevices));
                                %Scan through and set up each device
for iDevice = 1:handles.Dev.nDevices
    if handles.Dev.In.HasAIn && ~isempty(handles.Screen.DispChanList)
                                                        %Create object
        ai   = analoginput('nidaq', handles.Dev.BoardIDs{iDevice});
        
                                                        %Set Input Type ("Differential", "Single")
        set(ai,'InputType', handles.Dev.In.AvailInputTypes{handles.Disp.In.InputType})
                                                        %Find channels associated with iDevice
        ChanDevices     =  handles.Dev.ChanDevices(handles.Screen.DispChanList);
        DeviceChans     =  handles.Screen.DispChanList(ChanDevices==iDevice);
                                                        %Add desired channels, depends upon InputType
        if strcmpi(handles.Dev.In.AvailInputTypes(handles.Disp.In.InputType), 'Differential')   %For differential
            HWChans     = handles.Dev.In.HWChansDiff(DeviceChans);
            names       = makenames('NIDAQ_In_', DeviceChans);                                  %Setup channel names
            chs         = addchannel(ai, HWChans, names);   
        else                                                                                    %For SingleEnded or other
            HWChans     = handles.Dev.In.HWChansSingle(DeviceChans);
            names = makenames('NIDAQ_In_', DeviceChans);                                        %Setup channel names
            chs   = addchannel(ai, HWChans, names); 
        end
        
        
                                                        %Set voltage range for all channels
        for ic=1:size(DeviceChans)
            ai.Channel.InputRange(ic) = handles.Dev.In.VoltRanges(handles.Disp.In.VoltRange(DeviceChans(ic)))*[-1 1];
        end
        
        
                                                        %Set sample rate, first limit to allowable range
        handles.Dev.In.SampRate = max(min(handles.Dev.In.SampRate,handles.Dev.In.MaxCardRate/MaxNChan), handles.Dev.In.MinCardRate);
        handles.Dev.In.SampRate = setverify(ai,'SampleRate', handles.Dev.In.SampRate);
        
        
                                                        %Set number of samples
        set(ai,'SamplesPerTrigger', handles.nSamples(handles.Disp.In.nSampIndex));
                                        %Set Skew Mode to minimize ghosting (see NI M series manual), default is 'Minimum'
        handles.ChannelSkew     = setverify(ai,'ChannelSkewMode','Minimum');  
%         handles.ChannelSkew     = setverify(ai,'ChannelSkewMode','Equisample');                             
        
                                                        %If there is more than one DAQ, setup master clock
        if iDevice == 1 && handles.Dev.nDevices > 1
            set(ai, 'ExternalTriggerDriveLine',      handles.Dev.In.MasterTriggerOut    )
            set(ai, 'ExternalScanClockDriveLine',    handles.Dev.In.MasterScanClockOut  )
            set(ai, 'ExternalSampleClockDriveLine',  handles.Dev.In.MasterSampleClockOut)
        end

                                                        %SETUP TRIGGER************************************         
        if iDevice == 1                                 %Setup first device as Master
            switch handles.Dev.In.TrigTypes{handles.Disp.In.TrigType}
                case('Immediate')                       %Immediate trigger means no hardware triggering, software starts it
                    set(ai,'TriggerType','Immediate');
                    set(ai,'TriggerDelay', 0)           %No delay supported at moment
                case('HwDigital')                       %Trigger from digital input; Matlab presently supports PFI0 thru PFI9
                    set(ai,'TriggerType','HwDigital')
                    set(ai,'HwDigitalTriggerSource', handles.Dev.In.DigTrigSources{handles.Disp.In.TrigSource})
                    if strcmpi(handles.Dev.In.TrigSlopes{handles.Disp.In.TrigSlope},'Neg')
                        set(ai,'TriggerCondition', 'NegativeEdge' )
                    else
                        set(ai,'TriggerCondition', 'PositiveEdge')
                    end
                case('HwAnalogChannel')                 %Trigger from input channel; ONLY 1st chan supported; Level MUST be in range   
                    set(ai,'TriggerChannel',ai.Channel(handles.Dev.In.AnalogTrigChan))
                    VLimit = handles.Dev.In.VoltRanges(handles.Disp.In.VoltRange(handles.Screen.DispChanList(handles.Dev.In.AnalogTrigChan)));
                    handles.Disp.In.TrigLevel = max(min(handles.Disp.In.TrigLevel, VLimit), -VLimit);

                    set(ai,'TriggerType','HwAnalogChannel')

                    if strcmpi(handles.Dev.In.TrigSlopes{handles.Disp.In.TrigSlope},'Neg')
                        set(ai,'TriggerCondition', 'BelowLowLevel' )
                    else
                        set(ai,'TriggerCondition', 'AboveHighLevel')
                    end

                    set(ai,'TriggerConditionValue',handles.Disp.In.TrigLevel)
                otherwise
                    errordlg('Unsupported trigger type')
            end
        else                                            %Setup subsequenct devices as Slaves
            set(ai,'TriggerType',               handles.Dev.In.SlaveTrigType    )
            set(ai,'HwDigitalTriggerSource',    handles.Dev.In.SlaveTrigSource  )
            set(ai,'TriggerCondition',          handles.Dev.In.SlaveTrigSlope   )
            
            set(ai,'ClockSource',               handles.Dev.In.SlaveClockMode         )
            set(ai,'ExternalScanClockSource',   handles.Dev.In.SlaveScanClockSource   )
            set(ai,'ExternalSampleClockSource', handles.Dev.In.SlaveSampleClockSource )
        end
                                                        %END SETUP TRIGGER********************************
                                                        %Load input object into handles
        eval(sprintf('%s%1i%s', 'handles.ai', iDevice, ' = ai;'))
    end
end


%                                     %SETUP ANALOG OUTPUT...............................................
if handles.Dev.Out.HasAOut && ~isempty(handles.Dev.Out.ChanList)    %Setup for first device only
    ao     = analogoutput('nidaq', handles.Dev.BoardIDs{1});
                                                    %Setup channels, first make sure in range
    handles.Dev.Out.ChanList        = handles.Dev.Out.ChanList(handles.Dev.Out.ChanList <= handles.Dev.Out.NChanMax);
    names = makenames('NIDAQ_Out_', handles.Dev.Out.ChanList);                          %Setup channel names
    chs   = addchannel(ao, handles.Dev.Out.HWChans(handles.Dev.Out.ChanList), names);   %Associate with hardware

                                                    %Set output sample rate
    handles.Dev.Out.SampRate = min( handles.Dev.Out.SampRate, handles.Dev.Out.MaxCardRate/length(handles.Dev.Out.ChanList));
    handles.Dev.Out.SampRate = max( handles.Dev.Out.SampRate, handles.Dev.Out.MinCardRate );
    set(ao,'SampleRate',handles.Dev.Out.SampRate);
    handles.Dev.Out.SampRate = get(ao,'SampleRate');
                                                    %Set output ranges on each channel. Units range must be same for
    for ic=1:length(handles.Dev.Out.ChanList)       % output to equal input numbers in Volts
        ao.Channel.OutputRange(ic) = handles.Dev.Out.VoltRanges(handles.Dev.Out.VoltRangeInd(handles.Dev.Out.ChanList),:);
        ao.Channel.UnitsRange(ic)  = handles.Dev.Out.VoltRanges(handles.Dev.Out.VoltRangeInd(handles.Dev.Out.ChanList),:);
    end
                                                    %Load output object into handles
    handles.ao = ao;
end
    
Success = 1;

return


