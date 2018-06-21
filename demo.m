%% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz> 21-06-2018
% startMaster(fHandle, datacell, paramcell, settings)
% load training data
load iris_dataset
x = irisInputs';
[y, ~] = find(irisTargets);
datacell = {y, x};
fHandle = 'svmtrain';
% generate param cell
Cs = [0.001, 0.01, 0.1, 1, 10, 100];
gammas = [0.001, 0.01, 0.1, 1, 10, 100];
svmopts = '-s 0 -t 2';
paramcell = cell(1, 3);
for i=1:3
    
end
%% start parallel
res = startMaster(fHandle, datacell, paramcell);

