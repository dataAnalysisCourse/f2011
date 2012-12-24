function data = ReceiveUDP(socket, mode)
% mode is either
%   'latest' gets the most recent UDP packet in buffer and discards the 
%            older ones.
%   'next'   gets the next UDP packet in buffer.
% Note: only does vectors of doubles. If sending a matrix make sure you
% vecrtorize it and know how to unpack on the receiving end. 

switch mode
    case 'latest'
        steps = 0;
        packetSize = pnet(socket,'readpacket') ;
        data = pnet(socket,'read',packetSize,'double','intel');
        prevData = [];
        while  packetSize ;
            prevData = data;
            steps = steps + 1;
            packetSize = pnet(socket,'readpacket') ;
            data = pnet(socket,'read',packetSize,'double','intel');
        end
        if isempty(data)
            data = prevData;
        end
    case 'next'
        packetSize = pnet(socket,'readpacket') ;
        data = pnet(socket,'read',packetSize,'double','intel');
    otherwise
        error(['' mode ' is not a valid ReceiveUDP mode argument'])
end
