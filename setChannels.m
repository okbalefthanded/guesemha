% setChannels
%SETCHANNELS Summary of this function goes here
%   Detailed explanation goes here
% date created 06-21-2018
% last modified -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>

% slave channels ports
% ports = 9091:9091+nWorkers;
% masterPort = 9090;
% % channels = zeros(1, nWorkers);
% % udpA = udp(ipB,portB,'LocalPort',portA);
% for ch=1:nWorkers
%     channels(ch) = udp('Localhost',ports(ch), 'LocalPort', masterPort);
% end
% end
%%
masterPort = 9090;
slavePort = 9091;
masterSocket = udp('Localhost', slavePort, 'LocalPort', masterPort);
fopen(masterSocket);
data = [];
fprintf('Launching slaves...\n');
launchSlavesComm;
fprintf('Listening to incoming data...\n');
flag = 1;
while(flag)
    d=fscanf(masterSocket, '%d');    % listen to port
    if(~isempty(d))
        data = [data, d];
        if (length(data)==3)
            flag = 0;
        end
    end
    
end
fprintf('Data transfer is done\n');
fclose(masterSocket);