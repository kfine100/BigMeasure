function handles = WaveGenParameters(handles)
%        handles = WaveGenParameters(handles)
% Define parameters for WaveGen

% NI USB 6259 parameters
handles.ThisVersion          =   1.0;                           %Version of WaveGen

handles.NPtsPerCycle         = 100;
handles.MinFrequency         =      handles.Dev.Out.MinCardRate;
handles.MaxFrequency         =      min(100000, handles.Dev.Out.MaxCardRate /handles.NPtsPerCycle);
set(handles.FrequencyBox, 'TooltipString',...
    sprintf('Can generate frequencies between %d Hz and %d Hz', handles.MinFrequency, handles.MaxFrequency))

handles.MaxSingleDuration    =       1;

handles.Dev.Out.ChanList          =       1;                         %Use first channel (HW Chan 0) for output
                                                                %Set voltage range to largest (ranges are sorted in WaveGenParameters)
handles.Dev.Out.VoltRangeInd = size(handles.Dev.Out.VoltRanges,1) *ones(1,handles.Dev.Out.NChanMax);
handles.VoltLimits      = handles.Dev.Out.VoltRanges(handles.Dev.Out.VoltRangeInd(handles.Dev.Out.ChanList),:);
set(handles.AmplitudeBox, 'TooltipString',...
    sprintf('Must be between 0 and %d V', handles.VoltLimits(2)))

handles.SettingsFile         = 'WaveGen.set';

                                    %Constants....................................
handles.Red            = [ 1  0  0  ];   %Colors for buttons
handles.Yellow         = [ 1  1  0  ];
handles.Green          = [ 0  1  0  ];
handles.LYellow        = [ 1  1  0.5];

return