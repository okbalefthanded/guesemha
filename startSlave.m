function [] = startSlave
%STARTSLAVE Summary of this function goes here
%   Detailed explanation goes here
% created 06-20-2018
% last modification -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>
clc;
fprintf('Recovering shared memory.\n');
wPids = getWorkersPids();
nWorkers = length(wPids);
[~, workerRank] = find(sort(cellfun(@str2num, wPids))==feature('getPid'));
pid = num2str(workerRank);
clear wPids
% Set IPC
masterPorts = 9091:9091+nWorkers;
slavePorts = 9191:9191+nWorkers;
fprintf('Worker %d Opening communication channel on port: %d\n', ...
         feature('getPid'), ...
         slavePorts(workerRank)...
         );
slaveSocket = udp('Localhost', masterPorts(workerRank), ...
                  'LocalPort', slavePorts(workerRank)...
                  );
fopen(slaveSocket);

% Recover Shared Memory
fHandle = SharedMemory('attach', 'shared_fhandle');
datacell = SharedMemory('attach', 'shared_data');
fprintf('Data recovery succeded\n');
param = SharedMemory('attach', ['shared_' pid]);
workerResult = cell(1, length(param));

% Evaluate Functions
fprintf('Worker %s Evaluating job\n', pid);
% fprintf('Evaluatating function: %s\n', fhandle);

if(isstruct(fHandle) && isstruct(datacell))
    % Train & Predict mode
    mode = 'double';
else
    % Train only mode
    mode = 'single';
end

for p=1:length(param)
    if(strcmp(mode, 'single'))
        workerResult{p} = feval(fHandle, datacell{:}, param{p});
    else
        if(strcmp(mode, 'double'))
            % split data and evaluate folds
            nfolds = max(datacell.fold);
            acc_folds = zeros(1, nfolds);
            for f=1:nfolds
                idx = datacell.fold==f;
                train = ~idx;
                test = idx;
                af = eval_fold(fHandle, ...
                               datacell.data, ...
                               param{p}, ...
                               train,...
                               test...
                               );
                acc_folds(f) = af;
            end
            workerResult{p} = mean(acc_folds);
        end
    end
end

% Detach SharedMemroy
fprintf('Worker %s Detaching sharedMemory\n', pid);
SharedMemory('detach', 'shared_fhandle', fHandle);
SharedMemory('detach', 'shared_data', datacell);
SharedMemory('detach', ['shared_' pid], param);
clear fhandle datacell param
%
% Write results in SharedMemory
fprintf('Worker %s Writing results in sharedMemory\n', pid);
resKey = ['res_' pid];
fprintf('Worker %s shared result key %s\n', pid, resKey);
SharedMemory('clone', resKey, workerResult);

fprintf('Opening slave socket\n');
fprintf('writing data to socket \n');
fprintf(slaveSocket, '%d', feature('getPid'));
fprintf('Data sent : %d to %d\n',... 
         slaveSocket.ValuesSent, ...
         slaveSocket.propinfo.RemotePort.DefaultValue...
         );
fclose(slaveSocket);
delete(slaveSocket);
end

function af = eval_fold(fdle, data, param, trainIdx, predictIdx)
dTrain = getSplit(data, trainIdx);
dPredict = getSplit(data, predictIdx);
if(isstruct(data))  
    slaveModel  = feval(fdle.tr, dTrain, param{:});
    predFold = feval(fdle.pr, dPredict, slaveModel);
else    
    slaveModel  = feval(fhandle.tr, dTrain{:}, param);
    predFold = feval(fhandle.pr, dPredict{:}, slaveModel);
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