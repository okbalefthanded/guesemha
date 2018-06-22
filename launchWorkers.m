function [pids] = launchWorkers(max_instances)
%LAUNCHWORKERS Summary of this function goes here
%   Detailed explanation goes here

% created 06-20-2018
% last modification -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>

% [~, result] = system('tasklist /FI "imagename eq matlab.exe" /fo table /nh'); 
% currently_running = length(strfind(result,'MATLAB.exe'));

% for i = 1:(max_instances-currently_running)
for i = 1:(max_instances)
% !"C:\Program Files\MATLAB\R2014a\bin\matlab.exe" -nodisplay -nosplash -nodesktop -r "run('startSlave.m');exit;" 
!"C:\Program Files\MATLAB\MATLAB Production Server\R2015a\bin\matlab.exe" -nodisplay -nosplash -nodesktop -r "run('startSlave.m');" 
end
pids = getWorkersPids();
end

