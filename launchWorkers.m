function [pids] = launchWorkers(max_instances)
%LAUNCHWORKERS Summary of this function goes here
%   Detailed explanation goes here

% created 06-20-2018
% last modification -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>

% [~, result] = system('tasklist /FI "imagename eq matlab.exe" /fo table /nh');
% currently_running = length(strfind(result,'MATLAB.exe'));

% for i = 1:(max_instances-currently_running)
% find matlab path
matlabPath = ['"' findMatlabPath '"'];
opts = ' -nodisplay -nosplash -nodesktop -r';
scriptToRun =  ' "run(''startSlave.m'');"';
cmdToRun = strcat(matlabPath, opts, scriptToRun);
for i = 1:(max_instances)
    system(cmdToRun);
end
pids = getWorkersPids();
end

