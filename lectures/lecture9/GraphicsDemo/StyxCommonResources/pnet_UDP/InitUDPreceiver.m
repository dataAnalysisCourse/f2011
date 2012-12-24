function socket = InitUDPreceiver(localPort)

socket = pnet('udpsocket',localPort);