function [handles, Success] = Get_DAQ_ParametersMulti( handles )
%        [handles, Success] = Get_DAQ_ParametersMulti( handles )
% Defines parameters for active devices
% Multi.........version sets up multiple devices.......Oct 2009

switch handles.Dev.DeviceUsed
    
    case 1                      %FAKE device**********************************************************
        [handles, Success] = Fake_DAQ_Parameters(handles);
        
    case 2                      %NI Devices (NI 6259 (USB), NI USB 6211*******************************
        [handles, Success] = NI_DAQ_Parameters(handles);
    otherwise
        errordlg('Do not recognize CardUsed = %d', handles.Dev.DeviceUsed)
        Success = 0;
        return
end

return






function [handles, Success] = Fake_DAQ_Parameters(handles)
%Sets up Fake parameters for Fake Card in a Faky way

handles.Dev.In.HasAIn               = true;                                 %Flags if analog In/Out exists
handles.Dev.Out.HasAOut             = true;                                 % e.g. NI6210 has In but no Out


                        %ANALOG INPUT PROPERTIES...............................
                        
                        %.........InputTypes...............
handles.Dev.In.AvailInputTypes      = {'Single','Differential'};


                        %.........Triggers.................
handles.Dev.In.TrigTypes            = {'Immediate'};
handles.Dev.In.DigTrigSources       = 'none';
handles.Dev.In.TrigSlopes           = {'Pos';'Neg'};
handles.Dev.In.AnalogTrigChan       = 1;                                    %Some devices limited to triggering on first channel



                        %.........Sampling.................
handles.Dev.In.MaxCardRate          = 2e5;
handles.Dev.In.MinCardRate          =   1;
handles.Dev.In.SampRate             = handles.Dev.In.MaxCardRate;           %Set to maximum for default



                        %.........Channels.................
handles.Dev.In.HWChansDiff          = repmat((0:39)', 1, handles.Dev.nDevices);
handles.Dev.In.HWChansSingle        = repmat((0:39)', 1, handles.Dev.nDevices);
                                                                            %Create list of which device is with each channel
handles.Dev.ChanDevices             = repmat((1:handles.Dev.nDevices), size(handles.Dev.In.HWChansDiff,1), 1);

                                                                           %Set default length to number of Diff chans
handles.Dev.In.SWChans              = reshape(1:numel(handles.Dev.ChanDevices), [], handles.Dev.nDevices);

    



                        %.........Voltage Ranges...........
handles.Dev.In.MaxVolts             = 10;                                   %Can this be read somewhere??
handles.Dev.In.VoltRanges           = sort(handles.Dev.In.MaxVolts ./[1 2 5 10]);   %Allowed voltage ranges for device
handles.Dev.In.VoltRanges           = repmat(handles.Dev.In.VoltRanges', 1, handles.Dev.nDevices);





                        %ANALOG OUTPUT PROPERTIES...............................
                        
                        %.........Sampling.................
handles.Dev.Out.MaxCardRate         = 2e5;                                  %Min/Max sampling rates
handles.Dev.Out.MinCardRate         = 1;
handles.Dev.Out.SampRate            = handles.Dev.Out.MaxCardRate;              %Set to maximum for default


                        %.........Channels.................
handles.Dev.Out.HWChans             = 1:4;                                  %Available HW chans
handles.Dev.Out.NChanMax            = length(handles.Dev.Out.HWChans);
handles.Dev.Out.SWChans             = 1:handles.Dev.Out.NChanMax;               %SW channels start at 1 and are sequential
handles.Dev.Out.ChanList            = [];                                   %Will not setup unless channels are added


                        %.........Voltage Ranges...........
handles.Dev.Out.VoltRanges          = [-5 5; -10 10];                       %Out voltage ranges for device
handles.Dev.Out.VoltRangeInd        = ones(1,handles.Dev.Out.NChanMax);         %Index for each channel

Success                             = 1;

return








function [handles, Success] = NI_DAQ_Parameters(handles)
% Sets up parameters for National Instruments devices. For multiple devices, bases all properties on first device, since all are same.

Success = 0;                                                                %Be pessimistic
handles.Dev.In.HasAIn               = false;                                %Flags if analog In/Out exists
handles.Dev.Out.HasAOut             = false;                                % e.g. NI6210 has In but no Out




try                     %OPEN DEVICE TO READ Input PROPERTIES.....................                                  
    ai   = analoginput('nidaq', handles.Dev.BoardIDs{1});
    hwi1 = propinfo(ai);
    hwi2 = daqhwinfo(ai);
    delete(ai)                  %Clean up
    handles.Dev.In.HasAIn  = true;
end

try                     %OPEN DEVICE TO READ Output PROPERTIES.....................  
    ao   = analogoutput('nidaq', handles.Dev.BoardIDs{1});
    hwo1 = propinfo(ao);
    hwo2 = daqhwinfo(ao);
    delete(ao)
    handles.Dev.Out.HasAOut = true;
end

if ~handles.Dev.In.HasAIn && ~handles.Dev.Out.HasAOut   %Device has nothing!!!!
    errordlg('Failed to establish device connection in NI_DAQ_Parameters','DAQ error')
    return
end




                        %ANALOG INPUT PROPERTIES...............................
if handles.Dev.In.HasAIn
    
                        %.........InputTypes...............
    handles.Dev.In.AvailInputTypes          = hwi1.InputType.ConstraintValue;

    
   
                        %.........Triggers.................
    handles.Dev.In.TrigTypes                = intersect(handles.Dev.In.SupTrigTypes, hwi1.TriggerType.ConstraintValue);
                                                                            %Create list of digital trigs valid with Matlab
    MatlabValidDigTrigs                     = {'PFI0','PFI1','PFI2','PFI3','PFI4','PFI5','PFI6','PFI7','PFI8','PFI9'};
    DIndex = zeros(size(MatlabValidDigTrigs));
    for iC=1:length(MatlabValidDigTrigs)
        DIndex(iC) = any(strcmpi(MatlabValidDigTrigs{iC}, hwi1.HwDigitalTriggerSource.ConstraintValue));
    end
    handles.Dev.In.DigTrigSources           = {MatlabValidDigTrigs{DIndex==1}};

    handles.Dev.In.TrigSlopes               = {'Pos';'Neg'};
    handles.Dev.In.AnalogTrigChan           = 1;                            %Some devices limited to triggering on first channel
    
    
                        %.........Sampling.................
    handles.Dev.In.MaxCardRate              = hwi2.MaxSampleRate;
    handles.Dev.In.MinCardRate              = hwi2.MinSampleRate;
    if findstr(handles.Dev.DeviceNames{1}, '625')                           %AGGREGATE device rate lower for NI 625x (for others too??)
        if findstr(handles.Dev.DeviceNames{1}, '6255')                      %For 6255 devices
            handles.Dev.In.MaxCardRate      = 750e3;
        else                                                                %For 625x devices
            handles.Dev.In.MaxCardRate      = 1e6;
        end
    end
    handles.Dev.In.SampRate                 = handles.Dev.In.MaxCardRate;   %Set to maximum for default

    
    
                    %.........Channels.................
    handles.Dev.In.HWChansDiff              = repmat(hwi2.DifferentialIDs', 1, handles.Dev.nDevices);
    handles.Dev.In.HWChansSingle            = repmat(hwi2.SingleEndedIDs',  1, handles.Dev.nDevices);
    
                                                                            %Make list of device number for each channel
    handles.Dev.ChanDevices                 = repmat((1:handles.Dev.nDevices), size(handles.Dev.In.HWChansDiff,1), 1);

    handles.Dev.In.SWChans                  = reshape(1:numel(handles.Dev.ChanDevices), [], handles.Dev.nDevices);


    
    
                    %.........Voltage Ranges...........
    handles.Dev.In.MaxVolts                 = 10;                           %Can this be read somewhere??
    handles.Dev.In.VoltRanges               = sort(handles.Dev.In.MaxVolts ./hwi2.Gains);   %Allowed voltage ranges for channel
    handles.Dev.In.VoltRanges               = repmat(handles.Dev.In.VoltRanges', 1, handles.Dev.nDevices);

end





                        %ANALOG OUTPUT PROPERTIES...............................
                        
if handles.Dev.Out.HasAOut
    
                            %.........Sampling.................
    handles.Dev.Out.MaxCardRate             = hwo2.MaxSampleRate;           %Min/Max sampling rates
    handles.Dev.Out.MinCardRate             = hwo2.MinSampleRate;
    handles.Dev.Out.SampRate                = handles.Dev.Out.MaxCardRate;  %Set to maximum for default

    
                            %.........Channels.................
    handles.Dev.Out.HWChans                 = hwo2.ChannelIDs;              %Available HW chans
    handles.Dev.Out.NChanMax                = length(handles.Dev.Out.HWChans);
    handles.Dev.Out.SWChans                 = 1:handles.Dev.Out.NChanMax;   %SW channels start at 1 and are sequential
    handles.Dev.Out.ChanList                = [];                           %Will not setup unless channels are added
    
    
                            %.........Voltage Ranges...........
    handles.Dev.Out.VoltRanges              = hwo2.OutputRanges;            %Out voltage ranges for device
    [dum, indOutVolts]                      = sort(handles.Dev.Out.VoltRanges(:,2));    %Make sure sorted in ascending order
    handles.Dev.Out.VoltRanges              = handles.Dev.Out.VoltRanges(indOutVolts,:);
    handles.Dev.Out.VoltRangeInd            = ones(1,handles.Dev.Out.NChanMax);         %Index for each channel
end

Success                                     = 1;

return
