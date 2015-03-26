function handles = GetDevices( handles )
%        handles = GetDevices( handles )
% Finds which NI DAQ devices are connected and returns info about them.
% Outputs..........handles.Dev.DeviceUsed.........0   = user wants to quit
%                                  ...............1   = user wants to make fake data
%                                  ...............2   = National Instruments device(s) have been found.
%                                  ..............>2  = reserved for future devices (Wavebook?).
%       ...........handles.Dev.DeviceNames.......if n>0 contains name of device(s) (e.g. "USB-6259 (BNC)"
%       ...........handles.Dev.BoardIDs..........if n>1 contains ID for use in constructing interface objects, e.g. "Dev1"
%
%                                           kfine Mar 2008
% ...multi Modified for multiple cards,     kfine Oct 2009

hw          = daqhwinfo('nidaq');           %This routine returns info about attached NI devices
DeviceName  = hw.BoardNames;

if isempty(DeviceName)                      %Case where no device is found
    prompt = 'No DAQ device detected, is device powered? Create fake data?';
    answer = questdlg(prompt, 'No DAQ Card', 'Fake Data', 'Quit', 'Quit');
    if ~strcmpi(answer, 'Fake Data')        %User wants to exit
        handles.Dev.DeviceUsed      = 0;
    else                                    %User wants Fake Data
        handles.Dev.DeviceUsed      = 1;
        handles.Dev.BoardIDs        = {'Fake1',   'Fake2'  };
        handles.Dev.DeviceNames     = {'FakeDev', 'FakeDev'};
        handles.Dev.nDevices        =     length(handles.Dev.DeviceNames);
    end
else                                        %Normal case where something has been found
    handles.Dev.DeviceUsed          = 2;
    if length(DeviceName)>1                 %Multiple devices attached, choose among them
        Selection = listdlg('PromptString',     'Select devices (Must be same type)',...
                            'SelectionMode',    'multiple',...
                            'ListSize',         [250 200],...
                            'ListString',       hw.BoardNames,...
                            'Name',             'Select Devices');
       if isempty(Selection)
           handles.Dev.DeviceUsed   = 0;
           return
       end
    else                                    %Only one device attached, use it
        Selection                   = 1;
    end
                                            %Put chosen device(s) in handles
    handles.Dev.DeviceNames         = hw.BoardNames(Selection);
    handles.Dev.nDevices            = length(handles.Dev.DeviceNames);
                                            %Verify that for multiple devices, they are all same type.
    if any(strcmpi(handles.Dev.DeviceNames{1}, handles.Dev.DeviceNames)) == 0
        errordlg('VerifyMultiDevice: Only one type of device can be selected. Click continue to try again.')
        handles = VerifyCardMulti( handles );
        return
    end
    handles.Dev.BoardIDs            = hw.InstalledBoardIds(Selection);
                                            %Now test device to make sure it works
    try
        ai = analoginput('nidaq', handles.Dev.BoardIDs{1});
        chans = addchannel(ai,0);       %Should fail to add channel if not connected
        delete(ai)                      %Clean up
    catch
        errordlg(sprintf('%s on list, but does not respond, may need to restart Matlab. Exiting.', handles.Dev.DeviceNames{1}),...
            'DAQ does not Respond')
        handles.Dev.DeviceUsed = 0;
    end

end     

return