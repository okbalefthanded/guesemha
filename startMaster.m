%function [ resultCell ] = startMaster(fHandle, datacell, paramcell, settings)
function [resultCell] = startMaster(varargin)
%STARTMASTER Summary of this function goes here
%   Detailed explanation goes here
% created 06-20-2018
% last modification -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>

if(naragin < 3)
    error('Not enough input arguments');
end

if(nargin < 4)
    % Default settings
    settings.isWorker = false;
    settings.nWorkers = feature('numCores');
else
    fHandle = varargin{1};
    dataCell = varargin{2};
    paramCell = varargin{3};
    settings = varargin{4};
end

% launch workers
workersPid = launchWorkers(settings.nWorkers);
%
resultCell = cell(1, settings.nWorkers);
isMasterOn = true;
isSlavesOn = true;
workersDone = 0;
paramUnitSize = length(paramCell);
% keys = cell(1, settings.nWorkers);

% set IPC
masterPort = 9090;
slavePort = 9091;
masterSocket = udp('Localhost', slavePort, 'LocalPort', masterPort);
if(strcmp(masterSocket.status,'closed'))
    fopen(masterSocket);
end

% generate SharedMemory fhandle
SharedMemory('clone', 'fhandle', fHandle);
% generate SharedMemory data
SharedMemory('clone', 'data', dataCell);
% generate SharedMemory params
for worker = 1:settings.nWorkers
    SharedMemory('clone', workersPid{worker}, paramCell{worker});
end

% Send start command
% fprintf(masterSocket, 'startworker');

% master loop
% while(isMasterOn && isSlavesOn)
while(1)
    % evaluate if isWorker
    if(settings.isWorker)
        masterResult = cell(1, length(paramCell{1}));
        for evaluation = 1:length(paramCell{1})
            masterResult{evaluation} = feval(fhandle, dataCell{1, evaluation}, paramCell{1, evaluation});
        end
    end
    % collect results
   
%     IPC version
%     if(strcmp(masterSocket.status,'open'))
%         for worker = 1:settings.nWorkers
%             workermsg = fscanf(masterSocket);
%             if(strcmp(workermsg,['done' workersPid{worker}]))
%                 workersDone = workersDone + 1;
%             end
%             resultCell{worker} = SharedMemory('attach', workersPid{worker});            
%         end
%     end
    % terminate workers if all jobs are done
    if(workersDone == settings.nWorkers)
        terminateSlaves;
        isSlavesOn = true;        
    end
end

