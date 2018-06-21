%function [ resultCell ] = startMaster(fHandle, datacell, paramcell, settings)
function [resultCell] = startMaster(varargin)
%STARTMASTER Summary of this function goes here
%   Detailed explanation goes here
% created 06-20-2018
% last modification -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>

if(nargin < 3)
    error('Not enough input arguments');
end

if(nargin < 4)
    % Default settings
    settings.isWorker = false;
    settings.nWorkers = feature('numCores') - 1;    
else
    settings = varargin{4};
end

fHandle = varargin{1};
dataCell = varargin{2};
paramCell = varargin{3};

fprintf('Workers to launch: %d\n', settings.nWorkers);
% launch workers
workersPid = launchWorkers(settings.nWorkers);
disp({'Workers launched: ', workersPid{:}});
%
resultCell = cell(1, settings.nWorkers);
isMasterOn = 1;
isSlavesOn = 1;
workersDone = 0;

% set IPC
masterPort = 9090;
slavePort = 9091;
masterSocket = udp('Localhost', slavePort, 'LocalPort', masterPort);
if(strcmp(masterSocket.status,'closed'))
    fprintf('Opening Master socket.\n');
    fopen(masterSocket);
end

fprintf('Generating Shared memory.\n');
% generate SharedMemory fhandle
SharedMemory('clone', 'fhandle', fHandle);
% generate SharedMemory data
SharedMemory('clone', 'data', dataCell);
% generate SharedMemory params

for worker = 1:settings.nWorkers
    SharedMemory('clone', workersPid{worker}, paramCell{worker})
end

% Send start command
% fprintf(masterSocket, 'startworker');
receivedData = [];
flag = 1;

% master loop
while(isMasterOn && isSlavesOn)
    % while(1)
    % evaluate if isWorker
    if(settings.isWorker)
        fprintf('Master is worker, evaluating job.\n');
        masterResult = cell(1, length(paramCell{1}));
        for evaluation = 1:length(paramCell{1})
            masterResult{evaluation} = feval(fhandle, dataCell{1, evaluation}, paramCell{1, evaluation});
        end
    end
    
    % collect results
    while(flag)
        tmp = fscanf(masterSocket, '%d');
        fprintf('tmp is %s\n', tmp);
        if(~isempty(tmp))
            receivedData = [receivedData, tmp];
            if (length(receivedData)==settings.nWorkers)
                % all workers have finished their jobs
                workersDone = settings.nWorkers;
                fprintf('All workers have finished their jobs.\n');
                for worker = 1:settings.nWorkers
                    fprintf('Collecting results from worker: %s\n', workersPid{worker});
                    resKey = ['res_' workersPid{worker}];
                    resultCell{worker} = SharedMemory('attach', resKey);
                    SharedMemory('detach', resKey, resultCell{worker});
                end
                flag = 0;
            end
        end
    end
    
    % Order Workers to terminate
    %     fprintf(masterSocket, 'terminate');
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
        isSlavesOn = 0;
    end
end
fclose(masterSocket);

fprintf('Master freeing Shared memory.\n');
% free SharedMemory fhandle
SharedMemory('detach', 'fhandle', fHandle);
SharedMemory('free', 'fhandle');
% free SharedMemory data
SharedMemory('detach', 'data', dataCell);
SharedMemory('free', 'data');
% free SharedMemory params
for worker = 1:settings.nWorkers
    SharedMemory('detach', workersPid{worker}, paramCell{worker});
    SharedMemory('free', workersPid{worker});
end


