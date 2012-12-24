% Game 3012 - 3D Radial Center-Out Training Game (Corner Targets)
% 

classdef G_3012_Start < StyxState
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        %GAME OBJECTS
        world       % game object handle for threeDworld
        TC          % game object handle for technician cursor
        targets     % array of handles of Target objects
        GS          % array of handles to the other states
        director    % game object handle of the Director that determines target 
                    % presentation sequence               
        floor       % game world floor
        floorMesh1  % mesh walls right atop floor to add perspective
        wall_N   % rear mesh-wall used to help with perspective
        wall_W   % West mesh-wall
        wall_E  % East mesh-wall
        
        crossh_W % cross-hair connects cursor to where wall_W is
        crossh_N % cross-hair connects cursor to where wall_N is
        crossh_E % cross-hair connects cursor to where wall_E is
        crossh_D % cross-hair connects cursor to wherefloor is
		
        % PARAMETERS
        numSequences = 5;  % default for how many full sequences of each of the targets to go through. Note that if this is changed
                    % after construction, you actually have to
                    % change the corresponding property in
                    % director object
        timeToTarget = 3; % default for how long each center->out or out->center movement takes
		dwellTimeRequired = 1 ;    % how long for dwell time
		
        % COMMUNICATIONS
        gameUDP     % handle of the StyxUDPcommunicator that the game uses to
                    % send out velocity. Usually this is supplied by the
                    % STYX class which has confirmed that the two-way
                    % communication is working fine. It uses the IP and
                    % ports in the below properties, which are set when the
                    % game is started based on what NCS instructed STYX.
        gameReceivePort
        gameSendTargetIP
        gameSendTargetPort                      
        % GAME INFORMATION 
        version = [3012 1 1 2]; % Version of the game. Huge conceptual changes increment 
                                % the second number. Major changes which would
                                % change the way NCS or BG2Core should
                                % interact with the game should increment the
                                % third value. Minor changes should increment
                                % the fourth value. First number is the
                                % game code.
        
    end %properties (Access = public)
  
    
    
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        % CONSTRUCTOR
        function obj = G_3012_Start (varargin )
            % Note that StyxState immediately calls InitializeState method
            % after the constructor.
            obj = obj@StyxState(varargin);

        end %function obj =  G_3012_Start ( )
        
        function obj = InitializeState( obj, varargin )
            % InitializeState is a pseudo constructor, with the advantage
            % of it being able to be called from without to "reset" this
            % state.
            
            propAndValues = varargin{1}; % unpack property-value pairs
            % if called by STYX then it's doubly packed
            if max( size( propAndValues ) ) == 1 
                propAndValues = propAndValues{1};
            end
            
            for i = 1: 2 : length(propAndValues)
                obj.(propAndValues{i}) = propAndValues{i+1};
            end
                       
            % Create the logger object
            obj.logger_h = StyxLogger( 'gameDescriptiveName', obj.descriptiveName, 'version', obj.version );
            
            % Create the gameUDP object which is passed to
            % TargetSeekingCursor_st so that it can inform NCS/BG2 core of
            % the cursor position at all times
%             obj.gameUDP = StyxUDPcommunicator( 'descriptiveName', 'G_3012_UDP_communicator', ...
%                 'receivePort', obj.gameReceivePort, 'sendTargetIP', obj.gameSendTargetIP, ...
%                 'sendTargetPort', obj.gameSendTargetPort );
%            
            % Create the world, targets, and the technician cursor
			GenerateGameObjects( obj );
            
            % Create the Director for this game, which will generate the
            % the sequence of targets and then feed them to the instances of
            % Target_Acquired_State when they ask it for which
            % Target_Active_State they should transition to.             
            % i've decided that for the center target_acquired state, its
            % next states will be in indexes 1,3,5,7 (radial targets), and
            % 10 is the terminate state
            obj.director = Director( 'maxNumSequences', obj.numSequences, 'nextStateIndices', [1 3 5 7], 'terminateStateIndex', 10 );          
            
            % Create the other state objects
			% Game initiation consists of a pause followed by camera
			% flythrough to give the participant a better understanding of
			% the 3D space.
            obj.GS.pause1_st = Pause_State('descriptiveName', 'pause1_st', 'logger_h', obj.logger_h, 'pause_sec', 1);
			
			obj.GS.camFlyThrough1_st = CameraFlythrough_State( 'descriptiveName', 'camFlyThrough1', 'logger_h', obj.logger_h, 'rate', 31.25, 'world_h', obj.world, ...
				'goalCameraPosition', [-0.0195474 -0.759162 2.24704], 'goalCameraUpVector', [0.00150085 0.92818 0.372128], ...
				'goalCameraTarget', [-0.0180793 0.148765 -0.0175677], 'goalCameraViewAngle', 47, ...
				'duration', 1.5);
			obj.GS.camFlyThrough2_st = CameraFlythrough_State( 'descriptiveName', 'camFlyThrough2', 'logger_h', obj.logger_h, 'rate', 31.25, 'world_h', obj.world, ...
				'goalCameraPosition', [0.00153097 -2.30368 1.02899], 'goalCameraUpVector', [0.00107894 0.432654 0.901559], ...
				'goalCameraTarget', [0.0073 0.0097 -0.0812], 'goalCameraViewAngle', 47, ...
				'duration', 2.5);						
			obj.GS.camFlyThrough3_st = CameraFlythrough_State( 'descriptiveName', 'camFlyThrough3', 'logger_h', obj.logger_h, 'rate', 31.25, 'world_h', obj.world, ...
				'goalCameraPosition', [2.07981 -0.741837 0.321091], 'goalCameraUpVector', [-0.164173 0.066967 0.984156], ...
				'goalCameraTarget', [-0.00408257 0.108195 -0.0843758], 'goalCameraViewAngle', 47, ...
				'duration', 4);				
			obj.GS.camFlyThrough4_st = CameraFlythrough_State( 'descriptiveName', 'camFlyThrough4', 'logger_h', obj.logger_h, 'rate', 31.25, 'world_h', obj.world, ...
				'goalCameraPosition', [0.0034   -1.5542    0.2125], 'goalCameraUpVector', [0.0005    0.1846    0.9828], ...
				'goalCameraTarget', [0.0073    0.0097   -0.0812], 'goalCameraViewAngle', 47, ...
				'duration', 4);

			
            obj.GS.targetNEU_st = Target_Active_State( 'descriptiveName', 'target_NEU_goal_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{1}, 'dwellTimeRequired', obj.dwellTimeRequired);
            obj.GS.targetNEU_acquired_st = Target_Acquired_State( 'descriptiveName', 'target_NEU_acquired_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{1}, 'acquired_color_change', [0 0 0]);
            obj.GS.targetSEU_st = Target_Active_State( 'descriptiveName', 'target_SEU_goal_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{2}, 'dwellTimeRequired', obj.dwellTimeRequired);
            obj.GS.targetSEU_acquired_st = Target_Acquired_State( 'descriptiveName', 'target_SEU_acquired_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{2}, 'acquired_color_change', [0 0 0]);
            obj.GS.targetSWU_st = Target_Active_State( 'descriptiveName', 'target_SWU_goal_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{3}, 'dwellTimeRequired', obj.dwellTimeRequired);
            obj.GS.targetSWU_acquired_st = Target_Acquired_State( 'descriptiveName', 'target_SWU_acquired_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{3}, 'acquired_color_change', [0 0 0]);
            obj.GS.targetNWU_st = Target_Active_State( 'descriptiveName', 'target_NWU_goal_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{4}, 'dwellTimeRequired', obj.dwellTimeRequired);
            obj.GS.targetNWU_acquired_st = Target_Acquired_State( 'descriptiveName', 'target_NWU_acquired_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{4}, 'acquired_color_change', [0 0 0]);            
			obj.GS.targetNED_st = Target_Active_State( 'descriptiveName', 'target_NED_goal_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{5}, 'dwellTimeRequired', obj.dwellTimeRequired);
            obj.GS.targetNED_acquired_st = Target_Acquired_State( 'descriptiveName', 'target_NED_acquired_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{5}, 'acquired_color_change', [0 0 0]);
			obj.GS.targetSED_st = Target_Active_State( 'descriptiveName', 'target_SED_goal_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{6}, 'dwellTimeRequired', obj.dwellTimeRequired);
            obj.GS.targetSED_acquired_st = Target_Acquired_State( 'descriptiveName', 'target_SED_acquired_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{6}, 'acquired_color_change', [0 0 0]);
			obj.GS.targetSWD_st = Target_Active_State( 'descriptiveName', 'target_SWD_goal_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{7}, 'dwellTimeRequired', obj.dwellTimeRequired);
            obj.GS.targetSWD_acquired_st = Target_Acquired_State( 'descriptiveName', 'target_SWD_acquired_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{7}, 'acquired_color_change', [0 0 0]);
			obj.GS.targetNWD_st = Target_Active_State( 'descriptiveName', 'target_NWD_goal_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{8}, 'dwellTimeRequired', obj.dwellTimeRequired);
            obj.GS.targetNWD_acquired_st = Target_Acquired_State( 'descriptiveName', 'target_NWD_acquired_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{8}, 'acquired_color_change', [0 0 0]);
	
			
			
			obj.GS.targetC_st = Target_Active_State( 'descriptiveName', 'target_C_goal_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{9}, 'dwellTimeRequired', obj.dwellTimeRequired);
            % targetC_acquired_st is special; it uses the Director to determine its
            % next state from acquired_st
            obj.GS.targetC_acquired_st = Target_Acquired_State( 'descriptiveName', 'target_C_acquired_st', 'logger_h', obj.logger_h, 'target_h', obj.targets{9}, 'director_h', obj.director, 'acquired_color_change', [0 0 0] );
            
            obj.GS.targetSeeking_Cursor_st = TargetSeeking_Cursor_State('descriptiveName', 'targetSeeking_Cursor_st', 'logger_h', obj.logger_h, 'cursor_h', obj.TC, ...
                'gameUDP', obj.gameUDP, 'timeToTarget', obj.timeToTarget);
            obj.GS.end_st = EndFreeze_State( 'descriptiveName', 'Game_finished_state', 'logger_h', obj.logger_h);
            
            % Create the nextState state transition rules for each of the states.
			SetNextStateChoice( obj.GS.pause1_st, 1, obj.GS.camFlyThrough1_st );
			SetNextStateChoice( obj.GS.camFlyThrough1_st, 1, obj.GS.camFlyThrough2_st );
			SetNextStateChoice( obj.GS.camFlyThrough2_st, 1, obj.GS.camFlyThrough3_st );
			SetNextStateChoice( obj.GS.camFlyThrough3_st, 1, obj.GS.camFlyThrough4_st );			
			SetNextStateChoice( obj.GS.camFlyThrough4_st, {1 2}, {obj.GS.targetC_acquired_st, obj.GS.targetSeeking_Cursor_st} ); % note that target_C_st must be true first so it is listening for cursor to appear inside of it
            
			SetNextStateChoice( obj.GS.targetNEU_st, 1, obj.GS.targetNEU_acquired_st );
			SetNextStateChoice( obj.GS.targetNEU_acquired_st, 1, obj.GS.targetC_st );
            
			SetNextStateChoice( obj.GS.targetSEU_st, 1, obj.GS.targetSEU_acquired_st );
			SetNextStateChoice( obj.GS.targetSEU_acquired_st, 1, obj.GS.targetC_st );
			
			SetNextStateChoice( obj.GS.targetSWU_st, 1, obj.GS.targetSWU_acquired_st );
			SetNextStateChoice( obj.GS.targetSWU_acquired_st, 1, obj.GS.targetC_st );
			
			SetNextStateChoice( obj.GS.targetNWU_st, 1, obj.GS.targetNWU_acquired_st );
			SetNextStateChoice( obj.GS.targetNWU_acquired_st, 1, obj.GS.targetC_st );
			
			SetNextStateChoice( obj.GS.targetNED_st, 1, obj.GS.targetNED_acquired_st );
			SetNextStateChoice( obj.GS.targetNED_acquired_st, 1, obj.GS.targetC_st );
			
			SetNextStateChoice( obj.GS.targetSED_st, 1, obj.GS.targetSED_acquired_st );
			SetNextStateChoice( obj.GS.targetSED_acquired_st, 1, obj.GS.targetC_st );
			
			SetNextStateChoice( obj.GS.targetSWD_st, 1, obj.GS.targetSWD_acquired_st );
			SetNextStateChoice( obj.GS.targetSWD_acquired_st, 1, obj.GS.targetC_st );
			
			SetNextStateChoice( obj.GS.targetNWD_st, 1, obj.GS.targetNWD_acquired_st );
			SetNextStateChoice( obj.GS.targetNWD_acquired_st, 1, obj.GS.targetC_st );
                        
			SetNextStateChoice( obj.GS.targetC_st, 1, obj.GS.targetC_acquired_st);
% 			SetNextStateChoice( obj.GS.targetC_acquired_st, {1 2 3 4 5 6 7 8 10}, {obj.GS.targetNEU_st, obj.GS.targetSEU_st, obj.GS.targetSWU_st, obj.GS.targetNWU_st, ...
% 				obj.GS.targetNED_st, obj.GS.targetSED_st, obj.GS.targetSWD_st, obj.GS.targetNWD_st ,obj.GS.end_st} );

            SetNextStateChoice( obj.GS.targetC_acquired_st, {1 3 5 7  10}, {obj.GS.targetNEU_st, obj.GS.targetSWU_st, ...
				obj.GS.targetNED_st, obj.GS.targetSWD_st, obj.GS.end_st} );
            % Do other operations on these states necessary to their
            % function in this game.            
              % Link the targetSeeking_Cursor_st to all of the target_active
              % states. This allows that state to be notified of when
              % targets become active or inactive, and
              % targetSeeking_Cursor_st can in turn move the cursor to
              % them. Linking is done by passing an event generated in the 
              % target_st that targetSeeking_Cursor_st should listen to.
			 LinkToTargetActiveState( obj.GS.targetSeeking_Cursor_st, obj.GS.targetNEU_st, 'ActiveOrInactive');
% 			 LinkToTargetActiveState( obj.GS.targetSeeking_Cursor_st, obj.GS.targetSEU_st, 'ActiveOrInactive');
			 LinkToTargetActiveState( obj.GS.targetSeeking_Cursor_st, obj.GS.targetSWU_st, 'ActiveOrInactive');
% 			 LinkToTargetActiveState( obj.GS.targetSeeking_Cursor_st, obj.GS.targetNWU_st, 'ActiveOrInactive');
			 LinkToTargetActiveState( obj.GS.targetSeeking_Cursor_st, obj.GS.targetNED_st, 'ActiveOrInactive');
% 			 LinkToTargetActiveState( obj.GS.targetSeeking_Cursor_st, obj.GS.targetSED_st, 'ActiveOrInactive');
			 LinkToTargetActiveState( obj.GS.targetSeeking_Cursor_st, obj.GS.targetSWD_st, 'ActiveOrInactive');
% 			 LinkToTargetActiveState( obj.GS.targetSeeking_Cursor_st, obj.GS.targetNWD_st, 'ActiveOrInactive');
			 LinkToTargetActiveState( obj.GS.targetSeeking_Cursor_st, obj.GS.targetC_st, 'ActiveOrInactive');
                        
             % Waits until FalseToTrue method is called before game begins
%             obj.FalseToTrue; % as soon as Start becomes true, it moves to next state and game goes.
        end %function obj = InitializeState()      
        
        function obj = FalseToTrueImplement( obj )
            % The G_3011_Start state, as soon as it is set to true,
            % transitions to the first pause state.
			SetNextStateChoice( obj, 1, obj.GS.pause1_st );
			NextState( obj, 'pause1_st' );    
        end
        
        function obj = TrueToFalseImplement( obj )
            % currently undefined
        end
        
        % DESTRUCTOR
        function delete( obj )
           % call in turn the destructors of all its other Styx states in
           % game.
           states = fields( obj.GS );
           for i = 1 : length( fields( obj.GS ) )
               delete( obj.GS.(states{i}) );               
           end %for i = 1 : length( fields( obj.GS ) )
           
           % Delete all remaining game world objects
           delete(obj.world)   % this in turn deletes all targets, cursors, in that world.

           % delete the game UDP object
		   delete( obj.gameUDP );

           % delete special objects
           delete( obj.logger_h );
           delete( obj.director );           
        end
        
        
    end %methods (Access = public)
    
    methods (Access = private)
        function obj = GenerateGameObjects( obj )
            % Creates the world, targets, and the technician cursor.
            % Details of the target layout are hardcoded in here.
            
            % Create the world
            obj.world = ThreeDwindow( 'descriptiveName', 'world', 'logger_h', obj.logger_h, ...
				'cameraViewAngle', 47, 'cameraPosition', [0 -0.029971 1.71703], 'cameraUpVector', [0 0.9998 0.0174524]);
            
            % Create the floor - a solid base and meshwall on top
            obj.floor = Floor( obj.world, 'descriptiveName', 'floor', 'logger_h', obj.logger_h, ...
                'textureFile', [], 'simpleColor', [.45 .4 .4], 'numTiles', 16, 'altitude', -0.5, 'XLim', [-.5 .5], 'YLim', [-.5 .5]);          
            obj.floorMesh1 = MeshWall( obj.world, 'descriptiveName', 'floorMesh1', 'logger_h', obj.logger_h, 'color', [.3 .3 .3], 'numLinesD1', 15, 'numLinesD2', 15, ...
				'linewidth', 2, 'vert1', [-.5 -.5 -.5], 'vert2', [-.5 .5 -.5],  'vert3', [.5 .5 -.5], 'vert4', [.5 -.5 -.5]);
            
            % Add the walls
            obj.wall_N = MeshWall( obj.world, 'descriptiveName', 'wall_N', 'logger_h', obj.logger_h, 'color', [.7 .7 .7], 'numLinesD1', 5, 'numLinesD2', 8, ...
				'vert1', [-.5 .5 -.5], 'vert2', [-.5 .5 .5],  'vert3', [.5 .5 .5], 'vert4', [.5 .5 -.5]);
            obj.wall_W = MeshWall( obj.world, 'descriptiveName', 'wall_W', 'logger_h', obj.logger_h, 'color', [.7 .7 .7], 'numLinesD1', 5, 'numLinesD2', 8, ...
                'vert1', [-.5 .5 -.5], 'vert2', [-.5 .5 .5], 'vert3', [-.5 -.5 .5], 'vert4', [-.5 -.5 -.5] );
            obj.wall_E = MeshWall( obj.world, 'descriptiveName', 'Wall_E', 'logger_h', obj.logger_h, 'color', [.7 .7 .7], 'numLinesD1', 5, 'numLinesD2', 8, ...
                'vert1', [.5 .5 -.5], 'vert2', [.5 .5 .5], 'vert3', [.5 -.5 .5], 'vert4', [.5 -.5 -.5] );

    
            % Add a technician cursor. I start it off-screen
            obj.TC = Cursor(obj.world, 'descriptiveName', 'Technician_Cursor', 'logger_h', obj.logger_h, ...
				'color', [0 0 1], 'xyz', [ 0 0 0]); 
			obj.TC.emitsLight = 1; % No light emission in 3D game (messes up floor color)
            
            % Create the crosshair and attach these objects to the training% cursor. 
            obj.crossh_W = Crosshair( obj.world, 'logger_h', obj.logger_h, 'descriptiveName', 'crossh_W', 'freeVertex', [0 0 0], 'planeVertex', [-.5 0 0], 'lockedPlaneDim', 1 );
            obj.crossh_N = Crosshair( obj.world, 'logger_h', obj.logger_h, 'descriptiveName', 'crossh_N', 'freeVertex', [0 0 0], 'planeVertex', [0 .5 0], 'lockedPlaneDim', 2 );
            obj.crossh_E = Crosshair( obj.world, 'logger_h', obj.logger_h, 'descriptiveName', 'crossh_E', 'freeVertex', [0 0 0], 'planeVertex', [.5 0 0], 'lockedPlaneDim', 1 );
            obj.crossh_D = Crosshair( obj.world, 'logger_h', obj.logger_h, 'descriptiveName', 'crossh_D', 'freeVertex', [0 0 0], 'planeVertex', [0 0 -.5], 'lockedPlaneDim', 3 );

            AttachCrosshair( obj.TC, obj.crossh_W)
            AttachCrosshair( obj.TC, obj.crossh_N)
            AttachCrosshair( obj.TC, obj.crossh_E)
            AttachCrosshair( obj.TC, obj.crossh_D)
            
            
            % Generate the targets. Targets 1 through 8 are the corner
            % targets, and target 9 is the center target
            numTargets = 9;

            target_loc{1} = [ 0.4         0.4        0.4]; % NEU (North-East-Up)
            target_loc{2} = [ 0.4        -0.4        0.4]; % SEU
            target_loc{3} = [-0.4        -0.4        0.4]; % SWU
            target_loc{4} = [-0.4         0.4        0.4]; % NWU
            target_loc{5} = [ 0.4         0.4       -0.4]; % NED
            target_loc{6} = [ 0.4        -0.4       -0.4]; % SED
            target_loc{7} = [-0.4        -0.4       -0.4]; % SWD
            target_loc{8} = [-0.4         0.4       -0.4]; % NWD
            target_loc{9} = [ 0            0         0  ]; % Center
            % name the targets
            target_name{1} = 'target_NEU';
            target_name{2} = 'target_SEU';
            target_name{3} = 'target_SWU';
            target_name{4} = 'target_NWU';
            target_name{5} = 'target_NED';
            target_name{6} = 'target_SED';
            target_name{7} = 'target_SWD';
            target_name{8} = 'target_NWD';
            target_name{9} = 'target_C';
            
			targetsNeedingLinking = [ 1 3 5 7 9 ]; % which targets should be
			% linked to cursor. I only link the
			% ones that the cursor might go over in this training game to
			% reduce computational load of having every target constantly
			% checking distance of the cursor to it.
            obj.targets = cell(numTargets,1);
            for i = 1 : numTargets
                obj.targets{i} = Target(obj.world, 'descriptiveName', target_name{i}, 'logger_h', obj.logger_h, 'xyz', target_loc{i}, ...
					'cursorWithinColorChange', [0.2 0.2 0]); % changes color when cursor within to make it easier to tell this has happened.
                % I link all the targets to the cursor so they listen to
                % its movements and respond accordingly
				if any ( i == targetsNeedingLinking )
					LinkToCursor( obj.targets{ i }, obj.TC, 'MoveEvt');
				end
            end                        
        end %function obj = GenerateGameObjects( obj )
        
    end %methods (Access = private)
    
end %classdef