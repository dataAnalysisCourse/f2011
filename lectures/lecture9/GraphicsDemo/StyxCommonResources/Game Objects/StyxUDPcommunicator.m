
classdef StyxUDPcommunicator < handle
	% Needs to have it's receivePort specified upon construction. However,
	% the sendTargetIP and sendTargetPort can be left empty and specified
	% later, for instance after listening for an incoming packet with those
	% instructions from NCS. Manages multiple instances of itself by
	% incrementing sendPorts with each successive StyxUDPcommunicator
	% contruction and throwing an error if the receivePort specified isn't
	% unique.
	
	% *****************************************************
	%                       PROPERTIES
	% *****************************************************
	properties (Access = public)
		descriptiveName = '';    % should be named when created.
		receiveMode = 'latest' ; % 'latest' packet or 'next' packet in buffer
		sendTargetIP % IP this object will try to send to. should be set dynamically
		sendTargetPort % Port this object should be set dynamically.
	end % properties (Access = public)
	properties (GetAccess = public, SetAccess = protected)
		receivePort = '8000' % default STYX udp receive port. Set upon construction
		sendPort = '9000'    % default STYX udp send port. Set upon construction
	end % properties (GetAccess = public, SetAccess = protected)
	properties (Access = protected)
		receiveSocket
		sendSocket
	end % properties (Access = public)
	
	
	% *****************************************************
	%                       METHODS
	% *****************************************************
	methods (Access = public)
		% CONSTRUCTOR
		function obj = StyxUDPcommunicator( varargin )
			% parameter-value pair constructor
			for i = 1: 2 : length(varargin)
				obj.(varargin{i}) = varargin{i+1};
			end
			
			% Since there can be multiple instances of
			% StyxUDPcommunicator, it checks whether the currently
			% defined sendPort and receivePort has already been used.
			% If the sendPort has already been used it just takes the
			% next higher sendPort. However, if the receivePort has
			% already been used then it throws a warning since this
			% means the user hasn't properly thought through which port
			% this StyxUDPcommunicator should listen on.
			persistent otherInstanceHandles
			if ~isempty( otherInstanceHandles )
				% CHECK THAT THIS receivePort ISNT BEING USED ELSEWHERE
				for i = 1 : length( otherInstanceHandles ) %loop through all these other handles
					if isvalid( otherInstanceHandles{i} ) % since it might have been deleted
						if strcmp( otherInstanceHandles{i}.receivePort, obj.receivePort )
							fprintf('WARNING: Another instance of StyxUDPcommunicator is listening on port %s!\n', obj.receivePort)
							error('WARNING: Another instance of StyxUDPcommunicator is listening on port %s!', obj.receivePort)
						end
						if strcmp( otherInstanceHandles{i}.sendPort, obj.receivePort )
							fprintf('WARNING: Another instance of StyxUDPcommunicator is using port %s as a sendPort!\n', obj.receivePort)
							error('WARNING: Another instance of StyxUDPcommunicator is using port %s as a sendPort!', obj.receivePort)
						end
					end
				end %for i = 1 : length( otherInstanceHandles )
				
				% FIND NEXT AVAILABLE sendPort
				keepSearching = true;
				while keepSearching
					okSoFar = true;
					for i = 1 : length( otherInstanceHandles )
						if isvalid( otherInstanceHandles{i} ) % since it might have been deleted
							if strcmp( otherInstanceHandles{i}.sendPort, obj.sendPort )
								okSoFar = false;
								break
							end
						end
					end %for i = 1 : length( otherInstanceHandles )
					if okSoFar == false
						obj.sendPort = num2str( (str2double(obj.sendPort) + 1 ) );
					elseif okSoFar == true
						keepSearching = false;
					end
				end %while keepSearching
			end
			
			% add my own handle to otherInstanceHandles
			otherInstanceHandles{end+1} = obj;
			
			% -------------------------------------------
			%    Establish UDP  Receive Sockets
			% -------------------------------------------
			% 2 tries to open receive socket
			obj.receiveSocket = pnet('udpsocket', obj.receivePort );
			if obj.receiveSocket >= 0
				fprintf(['UDP receive established on port ' obj.receivePort '\n']);
			else
				obj.receiveSocket = pnet('udpsocket', obj.receivePort );
				if obj.receiveSocket >= 0
					fprintf(['UDP receive established on port ' obj.receivePort ' on second attempt\n']);
				else
					error(['Error: could not establish UDP receive on port ' obj.receivePort '\n'])
				end
			end
			
			% -------------------------------------------
			%  Establish UDP Send Sockets if target known
			% -------------------------------------------
			if ~isempty( obj.sendTargetIP ) && ~isempty( obj.sendTargetPort )
				% 2 tries to open send socket
				obj.sendSocket = pnet( 'udpsocket', obj.sendPort);
				pnet( obj.sendSocket, 'udpconnect', obj.sendTargetIP, obj.sendTargetPort );
				if obj.sendSocket >= 0
					fprintf(['UDP send established on port ' obj.sendPort ' targeting  ' obj.sendTargetIP ':' obj.sendTargetPort '\n']);
				else
					obj.sendSocket = pnet( 'udpsocket', obj.sendPort);
					pnet( obj.sendSocket, 'udpconnect', obj.sendTargetIP, obj.sendTargetPort );
					
					if obj.sendSocket >= 0
						fprintf(['UDP send established on port ' obj.sendPort ' targeting  ' obj.sendTargetIP ':' obj.sendTargetPort ' on second attempt\n']);
					else
						error(['Could not establish UDP send on port ' obj.sendPort ' targeting  ' obj.sendTargetIP ':' obj.sendTargetPort '\n']);
					end
				end
			end
		end  % constructor
		
		function delete( obj ) % Destructor
			% Close both sockets that this object opened.
			if ~isempty( obj.receiveSocket )
				CloseUDP( obj.receiveSocket )
				fprintf(['Closed receive socket on port ' obj.receivePort '\n']);
			end
			if ~isempty( obj.sendSocket )
				CloseUDP( obj.sendSocket )
				fprintf(['Closed send socket on port ' obj.sendPort '\n']);
			end
		end % delete( obj )
		
		% -------------------------------------------
		%  Establish UDP Send Sockets after construction
		% -------------------------------------------
		function status = EstablishSendConnection( obj )
			if ~isempty( obj.sendTargetIP ) && ~isempty( obj.sendTargetPort )
				% 2 tries to open send socket
				obj.sendSocket = pnet( 'udpsocket', obj.sendPort);
				pnet( obj.sendSocket, 'udpconnect', obj.sendTargetIP, obj.sendTargetPort );
				if obj.sendSocket >= 0
					fprintf(['UDP send established on port ' obj.sendPort ' targeting  ' obj.sendTargetIP ':' obj.sendTargetPort '\n']);
					status = 1;
				else
					obj.sendSocket = pnet( 'udpsocket', obj.sendPort);
					pnet( obj.sendSocket, 'udpconnect', obj.sendTargetIP, obj.sendTargetPort );
					if obj.sendSocket >= 0
						fprintf(['UDP send established on port ' obj.sendPort ' targeting  ' obj.sendTargetIP ':' obj.sendTargetPort ' on second attempt\n']);
						status = 1;
					else
						status = -1;
						fprintf(['Could not establish UDP send on port ' obj.sendPort ' targeting  ' obj.sendTargetIP ':' obj.sendTargetPort '\n']);
					end
				end
			else
				fprintf('no sendTargetIP or sendTargetPort specified\n')
				status = -1;
			end
		end %function status = EstablishSendConnection( obj )
		
		
		
		% -------------------------------------------
		%        UDP Send and Receive Methods
		% -------------------------------------------
		function StyxSendUDP( obj, data )
			%                 SendUDP( obj.sendSocket, data )
            if ~isempty( obj.sendSocket ) % don't send stuff if I'm not connected
                pnet( obj.sendSocket,'write',data,'intel' );
                pnet( obj.sendSocket,'writepacket' );
            else
                fprintf('[StyxUDPcommunicator] did not send UDP packet because no sendSocket exists. Did you establish outgoing connection?\n')
            end
        end
		
		function dataReceived = StyxReceiveUDP( obj )
			% mode is either
			%   'latest' gets the most recent UDP packet in buffer and discards the
			%            older ones.
			%   'next'   gets the next UDP packet in buffer.	
			
			switch obj.receiveMode
				case 'latest'
                    dataReceived = [];
					packetSize = pnet( obj.receiveSocket,'readpacket') ;
					while  packetSize ;
						dataReceived = pnet(obj.receiveSocket,'read',packetSize,'double','intel');
						packetSize = pnet(obj.receiveSocket,'readpacket') ;
					end
				case 'next'
					packetSize = pnet(obj.receiveSocket,'readpacket') ;
					dataReceived = pnet(obj.receiveSocket,'read',packetSize,'double','intel');
				otherwise
					error(['' mode ' is not a valid ReceiveUDP mode argument'])
			end
		end %function dataReceived = StyxReceiveUDP( obj )
	end  % methods (Access = public)
	
	% -------------------------------------------
	%        Set/Get Methods
	% -------------------------------------------
	methods
		function set.sendTargetIP( obj, value )
			if isempty( obj.sendSocket )
				obj.sendTargetIP = value;
			else
				if value ~= obj.sendTargetIP
					error('Cannot set sendTargetIP after send socket has already been created. That is, you''ve already established an outgoing connection');
				end
			end
		end %function set.sendTargetIP( obj, value
		
		function set.sendTargetPort( obj, value )
			if isempty( obj.sendSocket )
				obj.sendTargetPort = value;
			else
				if value ~= obj.sendTargetPort
					error('Cannot set sendTargetIP after send socket has already been created. That is, you''ve already established an outgoing connection');
				end
			end
		end %function set.sendTargetPort( obj, value
		
		
		
	end % methods
end %classdef