%  STYX GAME STATE ENGINE
% (c) 2009 Sergey Stavisky, Providence VAMC, BrainGate
% This is the top-level Styx function. When called, it will start a UDP
% listener tuner and wait for external UDP commands which can specify which game
% to load, and then start or close the game. STYX also handles
% communicating any communication between the game and external sources,
% such as sending kinematics into the BG2 core.

classdef STYX < handle
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        StyxUDP     % game object handle of the StyxUDPcommunicator used to
        % send or receive UDP packets from NCS or BG2 core to
        % and from the active games.
        LoadedGames = cell(100,1) % STYX permits up to 100 simult. loaded games
                     % cell array of loaded games. Since Styx games are designed such
                     % that the G_XXXX_Start state provides entry to all
                     % the games states, LoadedGames will contain handles
                     % to the G_XXXX_Start state of each game.
                     
    end % properties (Access = public)
    properties (GetAccess = public, SetAccess = protected)
       receivePort = '8000'
	   sendPort = '9000'
	   slotStatus = cell(100,1) % Keeps track of whether each game is loaded 
		                         % or has been started. Note that currently
		                         % if a game can end on its own (i.e. fixed
		                         % number of trials) there's isn't a way to
		                         % inform STYX of this, so the game would
		                         % still show up as 'started'.
    end % properties (GetAccess = public, SetAccess = protected)
    properties (Access = protected)
        UDPtimer_h; % handle of UDP timer object which periodically checks
        % for handshake or start commands sent by UDP
        UDPtimer_checkPeriod = 0.200 % determines the period of UDPtimer_h in sec.
        % Want it to be fast enough so game responds
        % to incoming UDP requests frequently enough
        % without taking up too many resources. 200ms seems fine for
        % starting and stopping the game
    end % properties (Access = protected)
    
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        % CONSTRUCTOR
        function obj = STYX(  )
            % Add the shared Styx classes to the path if running within
            % MATLAB
            if ~isdeployed
                addpath( genpath( [ fileparts(which(mfilename)) filesep 'StyxCommonResources'] ) );
            end
            fprintf('\n****************************************************\n')
            fprintf(2,'*                      STYX                        *')
            fprintf('\n*   MATLAB state machine and graphics game engine  *')
            fprintf('\n*   (c)2009 Sergey Stavisky BrainGate/VAMC         *')
            fprintf('\n****************************************************\n')
            
            
            % Create the UDP object
            obj.StyxUDP = StyxUDPcommunicator('descriptiveName', 'STYX_UDP_Communicator', 'receivePort', obj.receivePort, 'sendPort', obj.sendPort);
            
            % Create the UDP receive timer which will periodically check
            % for received UDP packets and respond appropriately to either
            % a.) reply to a handshake ping request, b.) start a game
            % given a start command, c.) stop a game given a stop
            % command.
            obj.UDPtimer_h = timer(...
                'TimerFcn', { @obj.listenForCommands_TimerFcn },  ...
                'BusyMode', 'drop', 'TasksToExecute', Inf, ...
                'ExecutionMode', 'fixedRate', 'Period', obj.UDPtimer_checkPeriod , ...
                'Name', 'UDPtimer');
            start( obj.UDPtimer_h ) % start listening immediately
            fprintf('STYX has started...\n') % DEV
        end  % constructor
        
        function delete( obj ) % Destructor
            delete( obj.StyxUDP ) % very important, or subsequent UDP connection attempts on
            % same sockets will fail
            stop( obj.UDPtimer_h )
            delete( obj.UDPtimer_h )
        end % delete( obj )
        
        % -------------------------------------------------------------
        %     Starting Games and Handling Ongoing UDP Communication
        % -------------------------------------------------------------
        function replyPacket = LoadGame( obj, receivedPacket ) % unpack a UDP packet containing
            % instructions on which game to Load and which parameters to
            % use when calling that game's _Start state.
            game = receivedPacket(3); % an interger, e.g. 3011 for G_3011
            slot = receivedPacket(2); % integer
			if ~isempty( obj.LoadedGames{slot} ) % make sure you're not trying to load a game into a slot with a game already loaded
				if strcmp( obj.slotStatus{slot}, 'started' )
					fprintf('There already is a game started in slot %i!\n', slot)
					error(['There already is a game started in slot ' slot '!'])
				elseif strcmp( obj.slotStatus{slot}, 'loaded' ) % if there is a game loaded in this slot but it hasn't been started, then close it
					CloseGame( obj, [0 slot] ); % abnornmal call to CloseGame method; the slot is extracted from element two
					                             % of what it thinks is receivedPacket, hence the vector I'm sending is just 
					                             % slot in element two and the rest is placeholder
				end
            end
            
            params_struct = vector_to_struct( receivedPacket( 4:end)' ); % for some vector_to_struct must use a column vector
            % unpack the parameters structure into a property-values cell array 
            parameters = fields(params_struct);
            paramValuePairs = cell(0);
            for i = 1 : length( parameters )
                paramValuePairs{end+1} = parameters{i};
                paramValuePairs{end+1} = params_struct.(parameters{i});
            end               
            
            % Clear other games from path
            % DEV NOTE: once I start using multiple games this will cause
            % interference. I'll not do this and will instead have each
            % game keep a full copy of its resources so if a different game
            % uses a custom version of a resource they won't interfere.
            % However, even with that there'll be issues with ordering.
            % I'll need to look into the @folder style of doing things...
            warning off % otherwise it complains when trying to remove from path things that aren't there but were picked up by the genpath
            rmpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxGames'])  ); % clear other games from path
            warning on
            
            % Call game-specific load method
            command = ['obj.Game' sprintf('%-.4i', game) '( slot, paramValuePairs );'];
            eval(command)
			version = obj.LoadedGames{slot}.version;
			
			% update the slotStatus to reflect that a game has been loaded
			% in this slot.
			obj.slotStatus{slot} = 'loaded';
			% prepare replyPacket which is echo of receivedPacket and the
			% version.
			replyPacket = [receivedPacket version];
        end %function LoadGame
        
                
        function StartGame( obj, receivedPacket )
            slot = receivedPacket(2);
            FalseToTrue( obj.LoadedGames{slot} ); % starts the game                  
			obj.slotStatus{slot} = 'started';     % update slotstatus
        end %function StartGame 
        
        
        function CloseGame (obj, receivedPacket )
            slot = receivedPacket(2);
            delete( obj.LoadedGames{slot} ); % close the game
            obj.LoadedGames{slot} = [];   % empty that slot
			obj.slotStatus{slot} = [];    % empty the slotstatus
        end %function CloseGame
        
        % -------------------------------------------------------------
        %                       INDIVIDUAL GAME LOADERS
        % -------------------------------------------------------------
        % Currently it just creates the start state of each game, so it
        % might seem like a general loader could be made. However, I've
        % kept this switch-like list so that future games that might
        % require something special before loading (change monitor
        % resolution? Ask for more parameters if not enough have been
        % sent?) can have this happen here. 
        
        function Game2011( obj, slot,  paramValuePairs )
            if ~isdeployed
                addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxCommonResources'] ) )
				addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxGames' filesep 'G_2011'] ) )
            end
            obj.LoadedGames{slot} = G_2011_Start( paramValuePairs );
        end %function Game2011
        
        function Game2013( obj, slot,  paramValuePairs )
            if ~isdeployed
                addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxCommonResources'] ) )
                addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxGames' filesep 'G_2013'] ) )
            end
            obj.LoadedGames{slot} = G_2013_Start( paramValuePairs );
        end %function Game2011
        
        function Game3011( obj, slot,  paramValuePairs )
            if ~isdeployed
				addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxCommonResources'] ) )
				addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxGames' filesep 'G_3011'] ) )
            end
            obj.LoadedGames{slot} = G_3011_Start( paramValuePairs );            
        end %function Game3011
        
        function Game3013( obj, slot,  paramValuePairs )
            if ~isdeployed
                addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxCommonResources'] ) )
                addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxGames' filesep 'G_3013'] ) )
            end
            obj.LoadedGames{slot} = G_3013_Start( paramValuePairs );
        end %function Game3013
		
		function Game7001( obj, slot,  paramValuePairs )
			if ~isdeployed
				addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxCommonResources'] ) )
				addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxGames' filesep 'G_7001'] ) )
			end
			obj.LoadedGames{slot} = G_7001_Start( paramValuePairs );
		end %function Game7001
		
        function Game8002( obj, slot,  paramValuePairs )
            if ~isdeployed
				addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxCommonResources'] ) )
				addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxGames' filesep 'G_8002'] ) )
            end
            obj.LoadedGames{slot} = G_8002_Start( paramValuePairs );
        end %function Game8002
        
        function Game8003( obj, slot,  paramValuePairs )
            if ~isdeployed
				addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxCommonResources'] ) )
				addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxGames' filesep 'G_8003'] ) )
            end
            obj.LoadedGames{slot} = G_8003_Start( paramValuePairs );
        end %function Game8003
        
        function Game8004( obj, slot,  paramValuePairs )
            if ~isdeployed
				addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxCommonResources'] ) )
				addpath( genpath( [fileparts( which( mfilename ) ) filesep 'StyxGames' filesep 'G_8004'] ) )
            end
            obj.LoadedGames{slot} = G_8004_Start( paramValuePairs );
        end %function Game8004
        
        
    end % methods (Access = public)
    
    methods (Access = private)
        function listenForCommands_TimerFcn( obj, timerObj, event )
            if isdeployed
               fprintf('.') % so I know its running 
            end
            
            receivedPacket = StyxReceiveUDP( obj.StyxUDP );
            if ~isempty( receivedPacket )
                packetTypeFlag = receivedPacket(1);
                % Do different things depending on the packet type and what
                % it says
                switch packetTypeFlag
                    case 101 % handshake request.
                        display('101 flag received') % DEV
                        % the remainder of the packet should contain the IP
                        % and listening port of the sender (presumably
                        % NCS). I will add these to the StyxUDP object,
                        % establish a connection, and send back a
                        % confirmation packet. 
                        fprintf('Establishing outbound connection with NCS... \n')
                        NCS_IP = [ num2str( receivedPacket(2) ) '.' num2str( receivedPacket(3) ) ...
                            '.' num2str( receivedPacket(4) ) '.' num2str( receivedPacket(5) )];
                        NCS_receivePort = num2str( receivedPacket(6) );
                        obj.StyxUDP.sendTargetIP = NCS_IP;
                        obj.StyxUDP.sendTargetPort = NCS_receivePort;
                        EstablishSendConnection( obj.StyxUDP );
                        % now send back confirmation by echoing the
                        % receivedPacket
                        replyPacket = receivedPacket;
                        StyxSendUDP( obj.StyxUDP, replyPacket );
                        
                    case 102 % game load request
                        display('102 flag received') % DEV
						try replyPacket = LoadGame( obj, receivedPacket ); % load the game. The method also adds the game version
                                                           % to the receivedPacket to generate the replyPacket
							replyPacket = [replyPacket 1]; % successfully loaded
						catch
							replyPacket = [receivedPacket 0]; % unsuccessful
						end
                        StyxSendUDP( obj.StyxUDP, replyPacket )
                        
                    case 103 % game start request
                        display('103 flag received') % DEV
                        try StartGame( obj, receivedPacket )  % call the game start method
                            replyPacket = [receivedPacket 1]; % successfully started
                        catch
                            replyPacket = [receivedPacket 0]; % unsuccessful
                        end % try..
                        StyxSendUDP( obj.StyxUDP, replyPacket )
                        
                    case 104 % game close request
                        display('104 flag received') % DEV
                        try CloseGame( obj, receivedPacket ) % call the game close method
                            replyPacket = [receivedPacket 1]; % successfully started
                        catch
                            replyPacket = [receivedPacket 0]; % unsuccessful
                        end % try..
                        StyxSendUDP( obj.StyxUDP, replyPacket )
                      
                end % switch packetTypeFlag
            end % if ~isempty( received )
        end %function UDPtimer_TimerFcn( obj, timerObj, event )
        
        
    end %methods (Access = private)   
    
    
end %classdef