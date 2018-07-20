function [] = startSlave
%STARTSLAVE Summary of this function goes here
%   Detailed explanation goes here
% created 06-20-2018
% last modification -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>
clc;
fprintf('Recovering shared memory.\n');
nWorkers = length(getWorkersPids());
[~, workerRank] = find(sort(cellfun(@str2num, getWorkersPids()))==feature('getPid'));
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

% Recover Shared Memory
% fhandle = str2func(SharedMemory('attach', 'shared_fhandle'));
fhandle = SharedMemory('attach', 'shared_fhandle');
datacell = SharedMemory('attach', 'shared_data');
fprintf('Data recovery succeded\n');
param = SharedMemory('attach', ['shared_' pid]);
workerResult = cell(1, length(param));


% Evaluate Functions
fprintf('Worker %s Evaluating job\n', pid);
% fprintf('Evaluatating function: %s\n', fhandle);

if(isstruct(fhandle) && isstruct(datacell))
    % Train & Predict mode
%     func.tr = str2func(fhandle.train);
%     func.pr = str2func(fhandle.predict);    
%     workerResult = eval_job(workerResult, fhandle, datacell, param, 'double');
mode = 'double';
else
    % Train only mode
%     func = str2fun(fhandle);
%     workerResult = eval_job(workerResult, fhandle, datacell, param, 'single');
mode = 'single';
end

for p=1:length(param)
    if(strcmp(mode, 'single'))
        workerResult{p} = feval(fhandle, datacell{:}, param{p});
    else
        if(strcmp(mode, 'double'))
            % split data and evaluate folds
            nfolds = max(datacell.fold);
            acc_folds = zeros(1, nfolds);
            for f =1:nfolds
                idx = datacell.fold==f;
                train = ~idx;
                test = idx;
                dTrain = getSplit(datacell.data, train);
                dPredict = getSplit(datacell.data, test);
                model = feval(fhandle.tr, dTrain{:}, param{p});
                predFold = feval(fhandle.pr, dPredict{:}, model);
                acc_folds(f) = getAccuracy(predFold, dPredict);
            end
            workerResult{p} = mean(acc_folds);
        end
    end
end

% for p = 1:length(param)
% %     workerResult{p} = feval(str2func(fhandle), data{1}, data{2}, param{p});
%     workerResult{p} = feval(str2func(fhandle), datacell{:}, param{p});
% end

% Detach SharedMemroy
fprintf('Worker %s Detaching sharedMemory\n', pid);
SharedMemory('detach', 'shared_fhandle', fhandle);
SharedMemory('detach', 'shared_data', datacell);
SharedMemory('detach', ['shared_' pid], param);
%
% Write results in SharedMemory
fprintf('Worker %s Writing results in sharedMemory\n', pid);
resKey = ['res_' pid];
fprintf('Worker %s shared result key %s\n', pid, resKey);
SharedMemory('clone', resKey, workerResult);
% SharedMemory('clone', resKey, pid);

fprintf('Opening slave socket\n');
fprintf('writing data to socket \n');
fprintf(slaveSocket, '%d', feature('getPid'));
fprintf('Data sent : %d to %d\n', slaveSocket.ValuesSent, slaveSocket.propinfo.RemotePort.DefaultValue);
fclose(slaveSocket);
delete(slaveSocket);

% wait for Master order to terminate
% free
% SharedMemory('free', resKey);
% Ready to terminate
end

% evaluate job
% function workerResult = eval_job(workerResult, func, data, param, mode)
% for p=1:length(param)
%     if(strcmp(mode, 'single'))
%         workerResult{p} = feval(func, data{:}, param{p});
%     else if(strcmp(mode, 'double'))
%             % split data and evaluate folds
%             nfolds = max(data.fold);
%             acc_folds = zeros(1, nfolds);
%             for f =1:nfolds
%                 idx = data.fold==f;
%                 train = ~idx;
%                 test = idx;
%                 dTrain = getSplit(data.data, train);
%                 dPredict = getSplit(data.data, test);
%                 model = feval(func.tr, dTrain{:}, param{p});
%                 predFold = feval(func.pr, dPredict{:}, model);
%                 acc_folds(f) = getAccuracy(predFold, dPredict); 
%             end
%             workerResult{p} = mean(acc_folds);
%         end
%     end
% end
% end

function d = getSplit(d, id)
d{1} = d{1}(id, :); 
d{2} = d{2}(id, :); 
end

function acc = getAccuracy(predFold, data)
if(size(data{1}, 2) > size(data{2}, 2))
    % Label data in second cell
   i = 2;
else
   i = 1;
end
 acc = (sum(data{i}==predFold) / length(data{i})) * 100;
end