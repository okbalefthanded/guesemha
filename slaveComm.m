clc;
fprintf('Wokrer Pid %d\n', feature('getPid'));
masterPort = 9090;
slavePort = 9091;
slaveSocket = udp('Localhost', masterPort, 'LocalPort', slavePort);
flag = 1;
while(flag)
    if(strcmp(slaveSocket.status,'closed'))
        fprintf('Opening slave socket\n');
        fopen(slaveSocket);
        fprintf(slaveSocket, '%d', feature('getPid'));
        
        
        fprintf('writing data to socket \n');                
    else
        fprintf('Closing slave socket\n');
        fclose(slaveSocket);
        flag = 0;
    end
end
%%
% while(1)
%
%     while get(udpA,'BytesAvailable')==0      % loop untile receive something
%         data=fscanf(masterSocket)     % listen to port
%     end
%
%
% end