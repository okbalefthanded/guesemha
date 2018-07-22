%% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz> 06-21-2018
% load training data

nworkers = 3;
settings.isWorker = true;
settings.nWorkers = nworkers;
load iris_dataset
x = irisInputs';
[y, ~] = find(irisTargets);
datacell = {y, x};
fHandle = 'svmtrain';
% generate param cell
Cs = [0.001, 0.01, 0.1, 1, 10, 100];
gammas = [0.001, 0.01, 0.1, 1, 10, 100];
% svmopts = '-s 0 -t 2';
paramcell = cell(1, nworkers);
paramsplit = length(Cs) / nworkers;
index = 0;
for i=1:nworkers
    for k=1:paramsplit
        tmp{k} = ['-t 2 -g ',num2str(gammas(k+index)),' ','-c ',num2str(Cs((k+index))),' ','-w1 1 -w-1 1'];
    end
    paramcell{i} = tmp;
    index = index + paramsplit;
end

%% start parallel
[res, resKeys] = startMaster(fHandle, datacell, paramcell, settings);
% Do something with res
% detach Memory
SharedMemory('detach', resKeys{1}, res);
terminateSlaves; 