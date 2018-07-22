function setup
%SETUP compile dependencies and add the toolbox to MATLAB path.
% created 07-22-2018
% last modification -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>

if(~isempty(which('SharedMemory')))
    fprintf('SharedMemory is already installed.\n');
else
    % add SharedMemory to path
    ShMemDir = 'dependencies\sharedmatrix\sharedmatrix_windows_by_andrew_smith';
    ShMemMex = dir([ShMemDir '\mexbin']);
    if(length(ShMemMex)<3)
        fprintf('compiling SharedMemory...');
        cd([ShMemDir '\mexbin']);
        SharedMemory_install;
        setup;
    else
        addpath(fullfile(pwd, ShMemDir, 'mexbin'));
    end
end
% add Guessemha to path
addpath(fullfile(pwd, 'examples'));
addpath(pwd);
savepath;
fprintf('Setup successful\n');
end

