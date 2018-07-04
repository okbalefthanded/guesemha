%function [ resultCell ] = startMaster(fHandle, datacell, paramcell, settings)
function [resultCell, resKeys] = startMaster(varargin)
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

resultCell = cell(1, settings.nWorkers);
isMasterOn = 1;
isSlavesOn = 1;
workersDone = 0;

% set IPC
% masterPort = 9090;
% slavePorts = 9091:9091+settings.nWorkers;
masterPorts = 9091:9091+settings.nWorkers-1;
slavePorts = 9191:9191+settings.nWorkers-1;
commChannels = cell(1, settings.nWorkers);

for channel=1:settings.nWorkers
    % masterSocket = udp('Localhost', slavePort, 'LocalPort', masterPort);
    fprintf('Creating a comm channel on port: %d\n', slavePorts(channel));
    commChannels{channel} = udp('Localhost', slavePorts(channel),....
                                'LocalPort', masterPorts(channel));
    commChannels{channel}.ReadAsyncMode = 'continuous';
    
end

% if(strcmp(masterSocket.status,'closed'))
%     fprintf('Opening Master socket.\n');
%     fopen(masterSocket);
% end

fprintf('Generating Shared memory.\n');
% generate SharedMemory fhandle
SharedMemory('clone', 'shared_fhandle', fHandle);
% generate SharedMemory data
SharedMemory('clone', 'shared_data', dataCell);
% generate SharedMemory params
for worker = 1:settings.nWorkers
    %     SharedMemory('clone', workersPid{worker}, paramCell{worker})
    SharedMemory('clone', ['shared_' num2str(worker)], paramCell{worker});
end

% launch workers
fprintf('Workers to launch: %d\n', settings.nWorkers);
workersPid = launchWorkers(settings.nWorkers);
disp({'Workers launched: ', workersPid{:}});
sorted = sort(cellfun(@str2num, workersPid));
disp(masterPorts);
disp(slavePorts);
disp(sorted);

% Send start command
% fprintf(masterSocket, 'startworker');
receivedData = [];
processStat = zeros(1, settings.nWorkers);
flag = 1;
resKeys = [];
% master loop
while(isMasterOn && isSlavesOn)

    % evaluate if isWorker
    if(settings.isWorker && workersDone==settings.nWorkers)
        fprintf('Master is worker, evaluating job.\n');
        masterResult = cell(1, length(paramCell{1}));
        for evaluation = 1:length(paramCell{1})
            masterResult{evaluation} = feval(fHandle, dataCell{1, evaluation}, paramCell{1, evaluation});
        end
    end
    pause(2);
    % collect results
    %     while(flag)
    for channel=1:settings.nWorkers
        %             fprintf('process stats: %d\n', processStat);
        disp(['process stats: ' num2str(processStat)]);
        if(processStat(channel))
%             fprintf('process at %d can be terminated\n', sorted(channel));
            break;
        end
        if(strcmp(commChannels{channel}.status,'closed'))
            %             if(strcmp(masterSocket.status,'closed'))
            %                 fprintf('Opening Master socket.\n');
            %                 fopen(masterSocket);
            fprintf('-Channel remote port: %d\n', commChannels{channel}.propinfo.RemotePort.DefaultValue);
            fprintf('-Opening communication channel on port: %d\n', slavePorts(channel));
            fprintf('-Waiting for worker %d to finish Job ---\n', sorted(channel));
            fopen(commChannels{channel});
        end
        %             tmp = fscanf(masterSocket, '%d');
        %             fclose(masterSocket);
        %         while get(commChannels{channel},'BytesAvailable')==0      % loop untile receive something
        %             tmp=fscanf(commChannels{channel});     % listen to port
        %         end
        tmp = fscanf(commChannels{channel}, '%d');
        fprintf('--values received %d on port %d finished job\n',commChannels{channel}.ValuesReceived, slavePorts(channel));
        fprintf('--Data recieved %d on port %d finished job\n', tmp, slavePorts(channel));
        fclose(commChannels{channel});
        fprintf('--Closing communication channel on port: %d\n', slavePorts(channel));
        if(~isempty(tmp))
            fprintf('---Worker %d finished job\n', tmp);
            %                 fprintf('Data recieved %d on port %d finished job\n', tmp, slavePorts(channel));
            %                 w = num2str(find(sort(cellfun(@str2num, workersPid))==tmp));
            %                 worker = find(sort(cellfun(@str2num, workersPid))==tmp);
            worker = find(sorted==tmp);
            w = num2str(worker);
            processStat(channel) = 1;
            resKey = ['res_' w];
            resKeys = [resKeys, resKey];
            fprintf('---Collecting results from worker: %d \n', sorted(worker));
            fprintf('---Attaching worker %d with key %s \n', sorted(worker), resKey);
            % resultCell{worker} = SharedMemory('attach', resKey);
            receivedData = [receivedData, tmp];
            disp(['---receivedData : ' num2str(receivedData)]);
            if (length(receivedData)==settings.nWorkers)
                % all workers have finished their jobs
                workersDone = settings.nWorkers;
                fprintf('**All workers have finished their jobs**.\n');
                flag = 0;
            end
        else
            fprintf('did not receive packet: Lost or unwritten\n');
        end
        
    end
    disp(['process stats: ' num2str(processStat)]);
    %     end
    
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
        %         terminateSlaves;
        isSlavesOn = 0;
    end
end
% fclose(masterSocket);
fclose('all');
delete(commChannels);
fprintf('Master freeing Shared memory.\n');
% free SharedMemory fhandle
% SharedMemory('detach', 'shared_fhandle', fHandle);
SharedMemory('free', 'shared_fhandle');
% % free SharedMemory data
% SharedMemory('detach', 'shared_data', dataCell);
SharedMemory('free', 'shared_data');
% % free SharedMemory params
for worker = 1:settings.nWorkers
    %     SharedMemory('detach', workersPid{worker}, paramCell{worker});
    %     SharedMemory('detach', ['shared_' num2str(worker)], paramCell{worker})
    SharedMemory('free', ['shared_' num2str(worker)]);
end

end


