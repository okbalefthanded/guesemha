function  terminateSlaves
% Close slaves processes by PID
% date created 06-14-2018
% last modified -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>

% [~,result] = system('tasklist /FI "imagename eq matlab.exe" /fo table /nh');
% pid_raw = strsplit(result,' ');
% row = 5;
% col = (length(pid_raw) - 1) / row;
% pid_raw = reshape(pid_raw(1:end-1), row, col);

pids = getWorkersPids();

for proc = 1:length(pids)
    %     system(['taskkill -f -PID ' pid_raw{2, proc}]);
    system(['taskkill -f -PID ' pids{proc}]);
end

end

