function [] = startSlave
%STARTSLAVE Summary of this function goes here
%   Detailed explanation goes here
% created 06-20-2018
% last modification -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>
clc;

% Set IPC
masterPort = 9090;
slavePort = 9091;
slaveSocket = udp('Localhost', masterPort, 'LocalPort', slavePort);

% Recover Shared Memory
fprintf('Recovering shared memory.\n');
pid = num2str(feature('getPid'));
fhandle = str2func(SharedMemory('attach', 'fhandle'));
data = SharedMemory('attach', 'data');
param = SharedMemory('attach', pid);
workerResult = cell(1, length(param));

% Evaluate Functions
fprintf('Worker %s Evaluating job\n', pid);
for p = 1:length(param)
    workerResult{p} = feval(fhandle, data{1}, data{2}, param{p});
end

% Detach SharedMemroy
fprintf('Worker %s Detaching sharedMemory\n', pid);
SharedMemory('detach', 'fhandle');
SharedMemory('detach', 'data');
SharedMemory('detach', pid);

% Write results in SharedMemory
fprintf('Worker %s Writing results in sharedMemory\n', pid);
resKey = ['res_' pid];
SharedMemory('clone', resKey, workerResult);

% Inform Master the Slave status, send pid to indicate worker is done.
flag = 1;
while(flag)
    if(strcmp(slaveSocket.status,'closed'))
        fprintf('Opening slave socket\n');
        fopen(slaveSocket);
        fprintf('writing data to socket \n');
        fprintf(slaveSocket, '%d', feature('getPid'));
    else
        fprintf('Closing slave socket\n');
        fclose(slaveSocket);
        flag = 0;
    end
end
% wait for Master order to terminate
% free
SharedMemory('detach', resKey);
SharedMemory('free', resKey);
% Ready to terminate
end

