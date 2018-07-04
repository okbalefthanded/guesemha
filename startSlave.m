function [] = startSlave
%STARTSLAVE Summary of this function goes here
%   Detailed explanation goes here
% created 06-20-2018
% last modification -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>
clc;
% Recover Shared Memory
fprintf('Recovering shared memory.\n');
% pid = num2str(feature('getPid'));
% pids = getWorkersPids();
nWorkers = length(getWorkersPids());
[~, workerRank] = find(sort(cellfun(@str2num, getWorkersPids()))==feature('getPid'));
% pid = num2str(find(sort(cellfun(@str2num, getWorkersPids()))==feature('getPid')));
pid = num2str(workerRank);
% Set IPC
masterPorts = 9091:9091+nWorkers;
% slavePort = 9091;
slavePorts = 9191:9191+nWorkers;
% slaveSocket = udp('Localhost', masterPort, 'LocalPort', slavePort);
fprintf('Worker %d Opening communication channel on port: %d\n', feature('getPid'), slavePorts(workerRank));
slaveSocket = udp('Localhost', masterPorts(workerRank), ...
    'LocalPort', slavePorts(workerRank));
fopen(slaveSocket);
% a pause to wait for master to write in SharedMemory
% pause(0.3);

% fhandle = str2func(SharedMemory('attach', 'shared_fhandle'));
fhandle = SharedMemory('attach', 'shared_fhandle');
% str2func(fhandle)
data = SharedMemory('attach', 'shared_data');
fprintf('Data recovery succeded\n');
param = SharedMemory('attach', ['shared_' pid]);
workerResult = cell(1, length(param));

% Evaluate Functions
fprintf('Worker %s Evaluating job\n', pid);
fprintf('Evaluatating function: %s\n', fhandle);
% disp(param{:});
for p = 1:length(param)
    workerResult{p} = feval(str2func(fhandle), data{1}, data{2}, param{p});
end
% workerResult{1}
% workerResult{2}
% Detach SharedMemroy
fprintf('Worker %s Detaching sharedMemory\n', pid);
SharedMemory('detach', 'shared_fhandle', fhandle);
SharedMemory('free', 'shared_fhandle');

SharedMemory('detach', 'shared_data', data);
SharedMemory('free', 'shared_data');

SharedMemory('detach', ['shared_' pid], param);
SharedMemory('free', ['shared_' pid]);

% Write results in SharedMemory
fprintf('Worker %s Writing results in sharedMemory\n', pid);
resKey = ['res_' pid];
fprintf('Worker %s shared result key %s\n', pid, resKey);
SharedMemory('clone', resKey, workerResult)

% Inform Master the Slave status, send pid to indicate worker is done.
% flag = 1;
% while(flag)
%     if(strcmp(slaveSocket.status,'closed'))
%         fopen(slaveSocket);
fprintf('Opening slave socket\n');
fprintf('writing data to socket \n');
fprintf(slaveSocket, '%d', feature('getPid'));
fprintf('Data sent : %d to %d\n', slaveSocket.ValuesSent, slaveSocket.propinfo.RemotePort.DefaultValue);
%     else
%             fprintf('Closing slave socket\n');
%             fclose(slaveSocket);
%     end
% end
fclose(slaveSocket);
delete(slaveSocket);
% wait for Master order to terminate
% free
% SharedMemory('detach', resKey, workerResult);
% SharedMemory('free', resKey);
% Ready to terminate
end

