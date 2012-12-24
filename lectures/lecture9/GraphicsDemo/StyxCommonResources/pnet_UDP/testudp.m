% 26 Oct 2009
% Learning to use pnet

MachA_IP          = '128.148.107.69';
MachA_sendPort    = '1001';
MachA_receivePort = '1002';

MachB_IP          = '128.148.107.69';
MachB_sendPort    = '2001';
MachB_receivePort = '1987';



% send from Mach A to Mach B


% ********************************************
%                  Setup
% ********************************************
% Mach B code
BreceiveSocket = InitUDPreceiver( MachB_receivePort );
if BreceiveSocket >= 0
    fprintf(['MachB: UDP receive established on port ' MachB_receivePort '\n']);
else
    BreceiveSocket = InitUDPreceiver( MachB_receivePort );
    if BreceiveSocket >= 0
        fprintf(['MachB: UDP receive established on port ' MachB_receivePort ' on second attempt\n']);
    else
        fprintf(['Error: MachB could not establish UDP receive on port ' MachB_receivePort '\n'])
    end
end
% end Mach B code

% Mach A code
AsendSocket = InitUDPsender( MachA_sendPort, MachB_IP, MachB_receivePort);
if AsendSocket >= 0
    fprintf(['MachA: UDP send established on port ' MachA_sendPort ' targeting  ' MachB_IP ':' MachB_receivePort '\n']);
else
AsendSocket = InitUDPsender( MachA_sendPort, MachB_IP, MachB_receivePort);
    if AsendSocket >= 0
        fprintf(['MachA: UDP send established on port ' MachA_sendPort ' targeting  ' MachB_IP ':' MachB_receivePort ' on second attempt\n']);
    else
        fprintf(['Eror: MachA could not establish UDP send on port ' MachA_sendPort ' targeting  ' MachB_IP ':' MachB_receivePort '\n']);
    end
end
% end Mach A code


pause(0.01)
% ********************************************
%                  Communication
% ********************************************
%Mach A code
% send a bunch of UDP packets
for i = 1 : 5
    SendUDP( AsendSocket , i )
end
% end Mach A code
pause(0.1)
% Mach B code
dataReceived = ReceiveUDP( BreceiveSocket, 'latest' )




% ********************************************
%                  Communication
% ********************************************
%Mach A code
CloseUDP( AsendSocket )

%end Mach A code

%Mach B code
CloseUDP( BreceiveSocket )
% end Mach B code

