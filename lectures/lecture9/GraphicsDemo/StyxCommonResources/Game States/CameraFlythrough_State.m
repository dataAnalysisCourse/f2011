classdef CameraFlythrough_State < StyxState
    % While this state is true the camera moves to a pre-determined
    % end-point. For now just the < > and < > are moved linearly between
    % their start and end position but the idea is
    % that this State can be added to make more complex camera-work.
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        duration;       % number of seconds to reach specified camera end 
                        % positions
        rate;           % camera changes per second.
		
		% Camera endpoint properties; the state will move the relevant
		% camera properties to this over the course of duration.
		goalCameraPosition
		goalCameraUpVector
		goalCameraTarget
		goalCameraViewAngle
		
    end %properties (Access = public)
    
    properties (GetAccess = public, SetAccess = private)
        world_h         % handle to a World game object which is expected to have
                        % set methods for various camera properties (e.g.
                        % view)          
    end %(GetAccess = public, SetAccess = private)
    
    properties (Access = private)
        timer_h         % each movement of camera happens every 1/obj.rate seconds
                        % thanks to this timer. Most of the action in this
                        % State happens in the timer's callbacks
		tasksRemaining = 0; % I use my own counter instead of querying the timer object
		                % properties because it is much faster.
    end %properties (Access = private)
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)        
        function obj = CameraFlythrough_State( varargin )
            % Note that StyxState immediately calls InitializeState method
            % after the constructor.
            obj = obj@StyxState(varargin);
        end %function obj =  Pause_State ( )
        
        function obj = InitializeState( obj, varargin )
            % InitializeState is a pseudo constructor, with the advantage
            % of it being able to be called from without to "reset" this
            % state.
            propAndValues = varargin{1}; % unpack property-value pairs
            for i = 1: 2 : length(propAndValues)
                obj.(propAndValues{i}) = propAndValues{i+1};
            end
            
            % Create the timer object
            obj.timer_h = timer(...
                'TimerFcn',  {@obj.CFT_TimerFcn} ,  ...
                'StopFcn', {@obj.CFT_TimerStopFcn}, ...
                'BusyMode', 'drop', 'TasksToExecute', obj.duration*obj.rate, ...
                'ExecutionMode', 'fixedRate', 'Period', 1/obj.rate, ...
                'Name', 'CameraFlythroughTimer', ...
                'StartDelay', 1/obj.rate);
			obj.tasksRemaining = get( obj.timer_h, 'TasksToExecute' );
            
        end %function obj = InitializeState()
        
        function obj = FalseToTrueImplement( obj )
            % Start the timer 
            start( obj.timer_h )
        end
        
        function obj = TrueToFalseImplement( obj )
            % currently undefined
        end
        
        % DESTRUCTOR
        function delete( obj )
            % delete the timer
            delete( obj.timer_h )
        end
        
    end %methods (Access = public)
    
    methods (Access = private)
        
        function CFT_TimerFcn( state_Obj, timerObj, event )
		% Primary timer function; happens every 1/obj.rate seconds for
		% obj.duration seconds. In this timer function I change the various
		% camera properties that have a goal defined by an amount equal to
		% the linear distance between their current and goal values divided
		% by the remaining number of tasks executed; the goal is to
		% reach to goal destination at the end of duraiton.
		
			% CAMERA POSITION 
            if ~isempty( state_Obj.goalCameraPosition )
				currValue = state_Obj.world_h.cameraPosition;
				delta = state_Obj.goalCameraPosition - currValue;
				state_Obj.world_h.cameraPosition = currValue + delta / state_Obj.tasksRemaining; 
			end
			
			% CAMERA UP VECTOR
            if ~isempty( state_Obj.goalCameraUpVector )
				currValue = state_Obj.world_h.cameraUpVector;
				delta = state_Obj.goalCameraUpVector - currValue;
				state_Obj.world_h.cameraUpVector = currValue + delta / state_Obj.tasksRemaining; 
			end
			
			% CAMERA TARGET
            if ~isempty( state_Obj.goalCameraTarget )
				currValue = state_Obj.world_h.cameraTarget;
				delta = state_Obj.goalCameraTarget - currValue;
				state_Obj.world_h.cameraTarget = currValue + delta / state_Obj.tasksRemaining; 
			end			
					
			% CAMERA VIEW ANGLE
            if ~isempty( state_Obj.goalCameraViewAngle )
				currValue = state_Obj.world_h.cameraViewAngle;
				delta = state_Obj.goalCameraViewAngle - currValue;
				state_Obj.world_h.cameraViewAngle = currValue + delta / state_Obj.tasksRemaining; 
			end
			
			
            
			state_Obj.tasksRemaining = state_Obj.tasksRemaining - 1;

        end
        
        function CFT_TimerStopFcn( state_Obj, timerObj, event )

            
            % When the timer finishes it's time to move to the next state
            
            NextState( state_Obj, 1:length(state_Obj.nextStateChoices ) ); % transition to all the next state choices
        end
        
                       
    end %methods (Access = private)        
    
    
end %classdef
