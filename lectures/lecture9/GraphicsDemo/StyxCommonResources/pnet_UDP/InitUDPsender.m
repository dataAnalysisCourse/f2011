function socket = InitUDPsender(localPort,remoteIP,remotePort)

socket = pnet('udpsocket',localPort);
pnet(socket,'udpconnect',remoteIP,remotePort);