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
pid = num2str(feature('getPid'));
fhandle = SharedMemory('attach', 'fhandle');
data = SharedMemory('attach', 'data');
param = SharedMemory('attach', pid);
% Evaluate Functions
% Write results in SharedMemory
% Inform Master the Slave status
% Detach SharedMemroy
% Ready to terminate
end

