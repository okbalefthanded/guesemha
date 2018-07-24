function [results, key] = startMaster(varargin)
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
results = cell(1,settings.nWorkers + 1);
isMasterOn = 1;
isSlavesOn = 1;
workersDone = 0;

% set IPC
masterPorts = 9091:9091+settings.nWorkers-1;
slavePorts = 9191:9191+settings.nWorkers-1;
commChannels = cell(1, settings.nWorkers);

for channel=1:settings.nWorkers
    fprintf('Creating a comm channel on port: %d\n', slavePorts(channel));
    commChannels{channel} = udp('Localhost', slavePorts(channel),....
                                'LocalPort', masterPorts(channel));
    fopen(commChannels{channel});
    
end

fprintf('Generating Shared memory.\n');
% generate SharedMemory fhandle
SharedMemory('clone', 'shared_fhandle', fHandle);
% generate SharedMemory data
SharedMemory('clone', 'shared_data', dataCell);
% generate SharedMemory params
for worker = 1:settings.nWorkers
    SharedMemory('clone', ['shared_' num2str(worker)], paramCell{worker});
end

% launch workers
fprintf('Workers to launch: %d\n', settings.nWorkers);
workersPid = launchWorkers(settings.nWorkers);
disp(['Workers launched: ', workersPid]);
sorted = sort(cellfun(@str2num, workersPid));
disp(masterPorts);
disp(slavePorts);
disp(sorted);

receivedData = [];
processStat = zeros(1, settings.nWorkers);
resKeys = cell(1, settings.nWorkers);
inputsAreStructs = isstruct(fHandle) && isstruct(dataCell);
% master loop
while(isMasterOn || isSlavesOn)    
    % evaluate if isWorker
    if(settings.isWorker && isMasterOn)
        fprintf('Master is worker, evaluating job.\n');
        masterResult = cell(1, length(paramCell{1}));
        for evaluation = 1:length(paramCell{1})
            % Master evaluate CV
             if(inputsAreStructs)
                nfolds = max(dataCell.fold);
                acc_folds = zeros(1, nfolds);
                for f=1:nfolds
                    idx = dataCell.fold==f;
                    train = ~idx;
                    predict = idx;
                    af = eval_fold(fHandle, ...
                                   dataCell.data, ...
                                   paramCell{1}{evaluation}, ...
                                   train, ...
                                   predict...
                                   );
                    acc_folds(f) = af;
                end                
                masterResult{evaluation} = mean(acc_folds);
            else
                % TODO
                masterResult{evaluation} = feval(fHandle, dataCell{:}, paramCell{1, evaluation});
            end
        end        
        isMasterOn = 0;
        fprintf('...Master''s job is done...\n');
    else
        if(exist('dataCell','var') && exist('fHandle','var') && exist('paramCell','var'))
            clear dataCell fhandle paramCell
        end
        for channel=1:settings.nWorkers
            disp(['process stats: ' num2str(processStat)]);
            if(processStat(channel))
                break;
            end
            tmp = fscanf(commChannels{channel}, '%d');
            fprintf('--values received %d on port %d \n',commChannels{channel}.ValuesReceived, slavePorts(channel));
            fprintf('--Data recieved %d on port %d \n', tmp, slavePorts(channel));
            if(~isempty(tmp))
                fprintf('---Worker %d finished job\n', tmp);
                worker = find(sorted==tmp);
                w = num2str(worker);
                processStat(channel) = 1;
                resKey = ['res_' w];
                resKeys{worker} = resKey;
                fprintf('---Collecting results from worker: %d \n', sorted(worker));
                fprintf('---Attaching worker %d with key %s \n', sorted(worker), resKey);
                resultCell{worker} = SharedMemory('attach', resKey);
                fprintf(commChannels{channel},'%d', 1);
                receivedData = [receivedData, tmp];
                disp(['---receivedData : ' num2str(receivedData)]);
                if (length(receivedData)==settings.nWorkers)
                    % all workers have finished their jobs
                    workersDone = settings.nWorkers;
                    fprintf('**All workers have finished their jobs**.\n');
                end
            else
                fprintf('did not receive packet: Lost or unwritten (Timeout)\n');
            end
        end
        disp(['process stats: ' num2str(processStat)]);
        if(workersDone == settings.nWorkers)
            %         terminateSlaves;
            isSlavesOn = 0;
            if(~settings.isWorker)
                isMasterOn = 0;
                results = {resultCell,{}};
            else
                results = {resultCell, masterResult};
            end
            for channel=1:workersDone
                fclose(commChannels{channel});
                delete(commChannels{channel});
            end
        end
    end
end

fclose('all');
delete('all');

fprintf('Master freeing Shared memory.\n');
% free SharedMemory fhandle
SharedMemory('free', 'shared_fhandle');
% free SharedMemory data
SharedMemory('free', 'shared_data');
% free SharedMemory params
for worker = 1:settings.nWorkers
    SharedMemory('free', ['shared_' num2str(worker)]);
end
key = resKeys{1};
end

function af = eval_fold(fHandle, data, param, trainIdx, predictIdx)
dTrain = getSplit(data, trainIdx);
dPredict = getSplit(data, predictIdx);
if(isstruct(data))    
    masterModel  = feval(fHandle.tr, dTrain, param{:});
    predFold = feval(fHandle.pr, dPredict, masterModel);
else    
    masterModel  = feval(fHandle.tr, dTrain{:}, param);
    predFold = feval(fHandle.pr, dPredict{:}, masterModel);
end
 af = getAccuracy(predFold, dPredict);
end

function d = getSplit(d, id)
if(isstruct(d))
    d.x = d.x(id, :); 
    d.y = d.y(id, :);
else
    d{1} = d{1}(id, :);
    d{2} = d{2}(id, :);
end
end

function acc = getAccuracy(predFold, data)
if(iscell(data))
    if(size(data{1}, 2) > size(data{2}, 2))
        % Label data in second cell
        i = 2;
    else
        i = 1;
    end
    acc = (sum(data{i}==predFold) / length(data{i})) * 100;
else
    acc = (sum(data.y==predFold.y) / length(data.y)) * 100;
end
end

