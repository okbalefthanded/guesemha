%% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz> 21-06-2018
% startMaster(fHandle, datacell, paramcell, settings)
% load training data
nworkers = 3;
settings.isWorker = false;
% settings.isWorker = true;
% settings.nWorkers = feature('numCores') - 1;
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
% res = startMaster(fHandle, datacell, paramcell);
res = startMaster(fHandle, datacell, paramcell, settings);
