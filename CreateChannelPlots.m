function [handles, Success] = CreateChannelPlots( handles )
% Creates best layout of channel displays on figure for number of channels


Success = false;
                                %Check to see if channel objects exist already
if isfield(handles, 'Chan')
    if length(handles.Chan.ChanSlider) == handles.Screen.DispChanMax
        Success = true;
        return                  %Number of objects is correct; no need to recreate
    else                        %Number not correct, delete all objects and recreate
        delete(handles.Chan.ChanPanel)
        handles.Chan    = [];   %Delete handles objects that have been deleted
    end
end

                                %Retrieve pre-calculated axes arrangements based on number of channels
[NumAxes, GraphFont, Positions, Success] = GetChannelParameters( handles );
if ~Success                     %Exit with error if number of channels not on prepared list
    return
end

                                %Calculate positions of panels each of which contain a graph and controls
[iX, iY]            = meshgrid(1:NumAxes(1), 1:NumAxes(2));

PanelSize           = (handles.ScrSet.Size -handles.ScrSet.Borders) ./NumAxes;
TopLeftX            = handles.ScrSet.ZeroPt(1) +(iX-1)*PanelSize(1);
TopLeftY            = handles.ScrSet.ZeroPt(2) -(iY  )*PanelSize(2);


                                %Create individual channel panels and controls
for iAxis = 1:handles.Screen.DispChanMax
                                %Create panel
    PanelPosition        = [TopLeftX(iAxis)  TopLeftY(iAxis)  floor(PanelSize)];
    Title = '';
    PanelTag        = sprintf('ChanPanel%02i',  iAxis);
    handles.Chan.ChanPanel(iAxis)       = uipanel('Parent', handles.BigMeasure, 'Title', Title, 'Units', 'pixels',...
        'Position', PanelPosition, 'Tag', PanelTag, 'BackgroundColor', handles.ScrSet.ChanBkgds(handles.Dev.ChanDevices(iAxis),:) );
    
                                %Create axis in panel
    AxisTag         = sprintf('ChanAxis%02i',  iAxis);
    handles.Chan.ChanAxis(iAxis)         = axes('Parent', handles.Chan.ChanPanel(iAxis), 'Position', Positions.GraphPosition,...
        'Tag', AxisTag, 'FontSize',  GraphFont, 'ButtonDownFcn', 'BigMeasure(''ExpandChannel'', gco, guidata(gco))' );
    grid on
    handles.Disp.ChanTitles{iAxis}       = ['Ch', num2str(iAxis,'%02d')];
    handles = BigMeasure('CreatePlotTitle', iAxis, handles);
    
                                %Create control panel
    CntlPanelTag    = sprintf('ChanCtrlPanel%02i',  iAxis);
    CtrlPanelText   = sprintf('Ch%02i',             iAxis);
    handles.Chan.ChanCntlPanel(iAxis)   = uipanel('Parent', handles.Chan.ChanPanel(iAxis), 'Title', CtrlPanelText, 'Units', 'normalized',...
        'Position', Positions.CtrlPanelPosition, 'Tag', CntlPanelTag, 'FontSize',  GraphFont, 'FontWeight', 'demi',...
        'BackgroundColor', handles.ScrSet.ChanBkgds(handles.Dev.ChanDevices(iAxis),:) );
                         
                                %Create slider for voltage control
    SliderTooltip   = 'Change Voltage (yaxis) scale. Changes gain of digitizer for more accuracy.';
    SliderTag       = sprintf('ChanSlider%02i',  iAxis);
    handles.Chan.ChanSlider(iAxis)      = uicontrol(handles.Chan.ChanCntlPanel(iAxis), 'Style', 'slider', 'Units', 'normalized',...
        'Position', Positions.SliderPosition, 'Tag', SliderTag, 'TooltipString', SliderTooltip, 'Value', 1,...
        'Callback', 'BigMeasure(''ReadFromDisplay'', gco, guidata(gco))');

                                %Create on/off button
    OnButtonToolTip = 'Turns channel on or off';
    OnButtonTag     = sprintf('ChanOnButton%02i',  iAxis);
    handles.Chan.ChanOnButton(iAxis)    = uicontrol(handles.Chan.ChanCntlPanel(iAxis), 'Style', 'radiobutton', 'Units', 'normalized',...
        'Position', Positions.OnButtonPosition, 'Tag',  OnButtonTag, 'String', 'On', 'TooltipString', OnButtonToolTip,...
        'BackgroundColor', handles.ScrSet.ChanBkgds(handles.Dev.ChanDevices(iAxis),:), 'FontSize',  GraphFont, 'Value', 1,...
        'Callback', 'BigMeasure(''ReadFromDisplay'', gco, guidata(gco))');
end

Success = true;
return






function [NumAxes, GraphFont, Positions, Success] = GetChannelParameters( handles )
                                %Choose best configuration of channels
                                %Find index in list of prepared channels
ChanIndex = find(handles.Screen.DispChanMax <= handles.ScrSet.AvailChanMax, 1, 'first');

if length(ChanIndex) == 1       %Set values for nice display
    NumAxes                         = handles.ScrSet.NumAxes(ChanIndex,:);
    GraphFont                       = handles.ScrSet.GraphFont(ChanIndex);
    Positions.GraphPosition         = handles.ScrSet.GraphPosition(ChanIndex,:);
    Positions.CtrlPanelPosition     = handles.ScrSet.CtrlPanelPosition(ChanIndex,:);
    Positions.SliderPosition        = handles.ScrSet.SliderPosition(ChanIndex,:);
    Positions.OnButtonPosition      = handles.ScrSet.OnButtonPosition(ChanIndex,:);
    Success = true;
else                            %Should never reach here, display error
    Mess = sprintf('CreateChannelPlots: Cannot find correct display setup for %i Channels', handles.Screen.DispChanMax);
    NumAxes         = [];
    GraphFont       = [];
    Positions       = [];
    Success         = false;

    errordlg(Mess)
end
    
    
return



