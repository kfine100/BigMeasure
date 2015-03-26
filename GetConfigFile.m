function [handles, UseCfgFile, Cfg] = GetConfigFile( handles )
%        [handles, UseCfgFile, Cfg] = GetConfigFile( handles )
% Searches for configuration file for BigMeasure, and if multiple exist, asks user which one to use
%
%
%                                       kfine Oct 2009


                                            %Make Config directory if it does not exist
if exist(handles.CfgDirName)~=7
    mkdir(handles.CfgDirName);
end
                                            %See how many config files there are
FilterSpec = fullfile(handles.CfgDirName, ['*', handles.ConfigFileExt]);
Listings = dir(FilterSpec);

UseCfgFile                          = false;
Cfg                                 = [];

if ~isempty(Listings)                       %If there is in directory, ask user what he wants
    [FileName,PathName,FilterIndex] = uigetfile(['*', handles.ConfigFileExt], 'Load Config file',...
                                                        fullfile(handles.CfgDirName, handles.LastCgfName));
   if FileName~=0                           %If user has selected one, load it in
       UseCfgFile                   = true;
       Cfg                          = load(fullfile(PathName, FileName), '-mat');
   end
end

return
    