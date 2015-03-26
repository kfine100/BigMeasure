function handles = BigMeasureParameters( handles )
%Measure Parameters: parameters for Measure GUI

                                    %General defs.............................................
handles.ThisVersion         =  1.6;
handles.ProgramChMax        =      80;      %Max channels for this program

handles.MaxNumSavedComs     = 20;           %Max number of comments saved in Prev comment list
handles.TakenData           =  false;       %Flag to show data has been taken
handles.PSD_Divisor         = 10;           %Sets size of window for Pwelch routine in ExpandChannel



                                    %Devices defaults.........................................
handles.Dev.MaxNDevices                     =  4;           %Max number of allowed devices
handles.Dev.In.SupTrigTypes                 = {'Immediate','HwDigital','HwAnalogChannel'};%Kinds of sources supported by software
                                            %Setup of slave devices
handles.Dev.In.SlaveTrigSource              = 'PFI10';
handles.Dev.In.SlaveTrigSlope               = 'NegativeEdge';
handles.Dev.In.SlaveTrigType                = 'HwDigital';

handles.Dev.In.SlaveClockMode               = 'ExternalSampleAndScanCtrl';
% handles.Dev.In.SlaveClockMode               = 'ExternalScanCtrl';

handles.Dev.In.SlaveScanClockSource         = 'PFI12';
handles.Dev.In.SlaveSampleClockSource       = 'PFI11';

                                            %Setup of master device
handles.Dev.In.MasterScanClockOut           = 'PFI12';
handles.Dev.In.MasterSampleClockOut         = 'PFI11';
handles.Dev.In.MasterTriggerOut             = 'PFI10';




                                    %Initial Default Display Setup............................
handles.DurText             = [ '  5 mS'; ' 10 mS'; ' 20 mS'; ' 50 mS'; '100 mS'; '200 mS';...
                                '500 mS'; '   1 S'; '   2 S'; '   5 S'; '  10 S'; '  20 S';...
                                '  50 S'; ' 100 S'; ' 200 S'; ' 500 S'; '1000 S';];
handles.pHandle             = zeros(handles.ProgramChMax,1);  %Initialize plot handles




                                    %Data File Setup..........................................
handles.Disp.PrevComm1      = {'Comment1'}; %Parameters displayed in SaveFile Dialog
handles.Disp.PrevComm2      = {'Comment2'};
handles.Disp.PrevFileSuffix = {'MeasData'};
handles.BigFileLimit        = 50;   %Limit in MegaBytes for warning for big output file
handles.DDateTime           =  datestr(now, 31);
handles.Disp.DataDirName    = [fileparts(mfilename('fullpath')), '\Data\'   ];      %Default Directory for output files
handles.CfgDirName          = [fileparts(mfilename('fullpath')), '\Configs\'];
handles.ConfigFileExt       = '.cfg';
handles.LastCgfName         = ['Last', handles.ConfigFileExt];
addpath(fileparts(mfilename('fullpath')))                                           %Make sure BigMeasure directory is on path

                                    %Acquisition setup........................................
handles.WaitFactor          =     10;     %Max time to wait for acq to finish, times sampling time
handles.nSamples            = [ 500   1000    2000    5000    10000    20000    50000    100000    200000    500000    1000000     2000000     5000000     10000000];
handles.NPtsMax             = max(handles.nSamples);    %Max number of points
handles.nSamplesText        = {'500' '1,000' '2,000' '5,000' '10,000' '20,000' '50,000' '100,000' '200,000' '500,000' '1,000,000' '2,000,000' '5,000,000' '10,000,000'};
handles.nSampData           = nan;        %Number of samples of last data taken
handles.WaitFactor          =   1.5;      %Max time to wait for acq to finish, times sampling time
handles.PreTime             =   [0 0];    %Extra time to add to acq to eliminate initial spikes
handles.MinTimeDisp         =     1;      %Times shorter than this display in TimeLeftBox


  

                                    %Constants................................................
handles.Red                 = [ 1  0  0  ];   %Colors for buttons
handles.Yellow              = [ 1  1  0  ];
handles.Green               = [ 0  1  0  ];
handles.LYellow             = [ 1  1  0.5];
handles.Blue                = [ 0  0  1  ];
handles.White               = [ 1  1  1  ];
                            
                            
                            
                            
                            
                                     %Screen setup.............................................
handles.ScrSet.Size             = [1920  985];                  %Size of part of screen which displays graphs
handles.ScrSet.ZeroPt           = [   0 handles.ScrSet.Size(2)];%{X Y] position of upper left corner of first screen
handles.ScrSet.Borders          = [   0    2];                  %Padding around channels to look nicer                           
handles.ScrSet.AvailChanMax     = [  1   2   3   4   8  16  32  50  60  70  80]';
handles.ScrSet.NumAxes          = [  1   1;                     % 1 Channel
                                     1   2;                     % 2 Channels
                                     1   3;                     % 3 Channels
                                     1   4;                     % 4 Channels
                                     2   4;                     % 8 Channels
                                     2   8;                     %16 Channels
                                     4   8;                     %32 Channels
                                     5  10;                     %50 Channels
                                     6  10;                     %60 Channels
                                     7  10;                     %70 Channels
                                     8  10];                    %80 Channels
                                 
handles.ScrSet.GraphFont        = [ 12  12  12  12  12  10  10  10   8   8   8]';

handles.ScrSet.GraphPosition    = [ 0.090 0.070 0.890 0.900;    % 1 Channel
                                    0.090 0.070 0.890 0.900;    % 2 Channels
                                    0.090 0.070 0.890 0.900;    % 3 Channels
                                    0.090 0.100 0.890 0.830;    % 4 Channels
                                    0.170 0.100 0.800 0.830;    % 8 Channels
                                    0.170 0.155 0.780 0.790;    %16 Channels
                                    0.200 0.155 0.750 0.790;    %32 Channels
                                    0.250 0.200 0.700 0.700;    %50 Channels
                                    0.270 0.200 0.680 0.700;    %60 Channels
                                    0.270 0.200 0.680 0.700;    %70 Channels
                                    0.350 0.200 0.600 0.700];   %80 Channels
                                
handles.ScrSet.CtrlPanelPosition= [ 0.005 0.010 0.050 0.980;    % 1 Channels
                                    0.005 0.010 0.050 0.980;    % 2 Channels
                                    0.005 0.010 0.050 0.980;    % 3 Channels
                                    0.005 0.010 0.050 0.980;    % 4 Channels
                                    0.005 0.010 0.100 0.980;    % 8 Channels
                                    0.005 0.010 0.110 0.980;    %16 Channels
                                    0.005 0.010 0.110 0.980;    %32 Channels
                                    0.005 0.010 0.150 0.980;    %50 Channels
                                    0.005 0.010 0.150 0.980;    %60 Channels
                                    0.005 0.010 0.150 0.980;    %70 Channels
                                    0.005 0.010 0.180 0.980];   %80 Channels
                                
handles.ScrSet.SliderPosition   = [ 0.600 0.070 0.300 0.900;    % 1 Channels
                                    0.600 0.070 0.300 0.900;    % 2 Channels
                                    0.600 0.120 0.300 0.850;    % 3 Channels
                                    0.600 0.150 0.300 0.800;    % 4 Channels
                                    0.700 0.150 0.200 0.800;    % 8 Channels
                                    0.700 0.150 0.200 0.800;    %16 Channels
                                    0.700 0.250 0.200 0.700;    %32 Channels
                                    0.600 0.260 0.300 0.700;    %50 Channels
                                    0.600 0.260 0.300 0.700;    %60 Channels
                                    0.600 0.260 0.300 0.700;    %70 Channels
                                    0.600 0.260 0.300 0.700];   %80 Channels
                                
handles.ScrSet.OnButtonPosition = [ 0.200 0.000 0.600 0.050;    % 1 Channels
                                    0.200 0.000 0.600 0.050;    % 2 Channels
                                    0.200 0.030 0.600 0.050;    % 3 Channels
                                    0.200 0.030 0.600 0.070;    % 4 Channels
                                    0.100 0.030 0.700 0.070;    % 8 Channels
                                    0.200 0.030 0.600 0.120;    %16 Channels
                                    0.050 0.030 0.800 0.120;    %32 Channels
                                    0.050 0.030 0.800 0.160;    %50 Channels
                                    0.050 0.030 0.800 0.180;    %60 Channels
                                    0.050 0.030 0.800 0.180;    %70 Channels
                                    0.000 0.030 1.000 0.180];   %80 Channels
                                
handles.ScrSet.ChanBkgds        = [ 0.50 0.50 1.00;
                                    0.50 0.84 1.00;
                                    0.50 0.67 1.00;
                                    0.50 1.00 1.00];





