function [pids] = getWorkersPids
%GETWORKERSPIDS Summary of this function goes here
%   Detailed explanation goes here

% created 06-20-2018
% last modification -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>

[~,result] = system('tasklist /FI "imagename eq matlab.exe" /fo table /nh');
pid_raw = strsplit(result,' ');
row = 5;
col = (length(pid_raw) - 1) / row;
pid_raw = reshape(pid_raw(1:end-1), row, col);
pids = pid_raw(2,2:end);
end

