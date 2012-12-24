classdef Target_Active_State < StyxState
    % When this state is true, the target with which the state is
    % associated (during initialization) becomes lit up. When it is
    % acquired, the target is dimmed and this state transitions the game
    % to its next state, which would typically be a pause or the next
    % target state.
    % state
    % 
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        target_h
        dwellTimeRequired = 0.5 ;    % how many secs cursor must be continually
                                     % in the target to have an acquisition
                                     % doesn't matter if dwell mode is
                                     % disabled.
        useDwell = true;             % whether this state's target can be
                                     % selected by dwelling over it. 
                                      
        timeoutTime = 0;             % if nonzero then state can timeout 
                                     % when target isn't acquired within
                                     % this many seconds. 
        sendingTargetPos = false;    % if true, sends current target position 
                                     % every time a new target becomes active.
    end %properties (Access = public)
    properties (Access = private)
        targetAcquiringTimer_h             % timer object used to count until
                                          % cursor has been held on target
                                          % long enough for successful
                                          % acquisition. 
        targetTimeoutTimer_h              % timer object that counts down until 
                                          % this target is timed out (i.e. wasn't
                                          % acquired fast enough).
                                          % Starts as soon as state becomes
                                          % active. 
        lh                                % structure containing the listener handles
        gameUDP
        targetPosUDP                 % StyxUDPcommunicator object handle that this state
		% uses to send target position if sendingTargetPos is true.
    end %properties (Access = private)
    
    % *****************************************************
    %                       EVENTS
    % *****************************************************
    events
        ActiveOrInactive % event that the target goes from active to inactive or vice versa
    end
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)        
        function obj = Target_Active_State( varargin )
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
            
            % check that the target_h it was given is a valid Target
            if ~strcmp( class( obj.target_h ), 'Target' )
                error('handle given to InitializeState is a %s, but a Target is expected',class( obj.target_h ) )
            end        
            
            % Create a listener to the CursorWithinEvt of this state's associated Target object
            obj.lh.cursorWithin = addlistener( obj.target_h, 'CursorWithinEvt', @obj.CursorWithinEvtCallback );
            obj.lh.cursorWithin.Enabled = false;
            % Create a listener to the ClickedEvt of this state's associated Target object
            obj.lh.clicked = addlistener( obj.target_h, 'ClickedEvt', @obj.ClickedEvtCallback );
            obj.lh.clicked.Enabled = false;
            
            
            % Create a timer object that will be used to see whether the
            % cursor is in the target long enough for a successful
            % acquisition.
            obj.targetAcquiringTimer_h = timer(...
                'TimerFcn',  {@obj.acquiringTimerFcn} ,  ...
                'ExecutionMode', 'singleShot',  ...
                'Name', 'targetAcquiringTimer', ...
                'StartDelay', obj.dwellTimeRequired);
            
            % Create timer used to see whether this target was not acquired
            % within the timeout period. Only do this if timeout is enabled
            if obj.timeoutTime            
                obj.targetTimeoutTimer_h = timer(...
                    'TimerFcn',  {@obj.timeoutTimerFcn} ,  ...
                    'ExecutionMode', 'singleShot',  ...
                    'Name', 'targetTimeoutTimer', ...
                    'StartDelay', obj.timeoutTime);
            end
            
        end %function obj = InitializeState()
        
        function obj = FalseToTrueImplement( obj )
            MakeActive( obj.target_h );
            obj.lh.cursorWithin.Enabled = true;
            obj.lh.clicked.Enabled = true;
            notify( obj, 'ActiveOrInactive' );
            % start timeout timer if its being used
            if obj.timeoutTime
                start( obj.targetTimeoutTimer_h )
            end
            
            % send target position to SLC every time a new target becomes true
            if obj.sendingTargetPos
                sendPacket = zeros(1,64); % The convention is to send 64 double packets
                sendPacket(1:5) = [16 datenum(clock) obj.target_h.xyz];
                StyxSendUDP( obj.targetPosUDP, sendPacket );
            end            
        end
        
        function obj = TrueToFalseImplement( obj )
            MakeInactive( obj.target_h );
            obj.lh.cursorWithin.Enabled = false;
            obj.lh.clicked.Enabled = false;
            notify(obj, 'ActiveOrInactive' );
            % stop timeout timer if it exists
            if ~isempty( obj.targetTimeoutTimer_h )
                stop( obj.targetTimeoutTimer_h )
            end
        end
        
        
        % DESTRUCTOR
        function delete( obj )
            % delete the time
            if strcmp( obj.targetAcquiringTimer_h.Running, 'on')
                stop( obj.targetAcquiringTimer_h )
            end
            delete( obj.targetAcquiringTimer_h )
            if ~isempty( obj.targetTimeoutTimer_h )
                stop( obj.targetTimeoutTimer_h )
                delete( obj.targetTimeoutTimer_h )
            end
        end %delete( obj )
        
    end %methods (Access = public)
    
    methods (Access = private)
        function obj = CursorWithinEvtCallback(obj, eventSrc, eventData )
            % if this callback is triggered that means the Target
            % associated with this state has broadcast that the cursor has
            % just entered or left it. If it entered, we want to start the
            % targetAcquisition timer. If it left, we want to stop the
            % targetAcquisition timer. This only happens if useDwell is
            % true.
            if obj.useDwell            
                if eventSrc.cursorWithin == true
                    start( obj.targetAcquiringTimer_h )
                elseif eventSrc.cursorWithin == false
                    stop( obj.targetAcquiringTimer_h )
                end
            end
        end %obj = CursorWithinEvtCallback(obj, eventSrc, eventData )
        
         function obj = ClickedEvtCallback(obj, eventSrc, eventData )
         % if clicked, move to the target acquired nextStateChoice. Note that the
         % listener for this event is only enabled with Target_Active_State
         % is true so I don't need to make sure of that here.
            % turn off the target acquiring timer
            stop( obj.targetAcquiringTimer_h )
            NextState( obj, 1 );           
         end % obj = ClickedEvtCallback(obj, eventSrc, eventData )
        
        function acquiringTimerFcn( T_A_S_Obj, timerObj, event )
        % Called when acquringTimer goes off during dwell select mode.
        % When this timer goes off, target has been successfully acquired 
        % and we should go to nextStateChoices{1}, which should have been 
        % set to the relevant target_acquired_st.
            NextState( T_A_S_Obj, 1 );   
        end
        
        function timeoutTimerFcn( T_A_S_Obj, timerObj, event )
            % Called when targetTimeoutTimer_h goes off if obj.timeoutTime is nonzero. 
            % When this timer goes off, target has failed to be acquired
            % and we should go to nextStateChoices{2} should have been set 
            % to the relevant target_timedout_st.
            NextState( T_A_S_Obj, 2 );
        end
            
        
    end %methods (Access = public)        
    
    % --------------------------------------------------
    %                Set/Get Methods
    % --------------------------------------------------
    methods
        function set.dwellTimeRequired( obj, value )
        % Changing this property needs to go in and change the Period
        % property of the timer object (if it exists)
            obj.dwellTimeRequired = value;
            if isobject( obj.targetAcquiringTimer_h )
                obj.targetAcquiringTimer_h.StartDelay = value;
            end
            % LOGGING
            Log( obj.logger_h, obj, 'STATE', 'dwellTimeRequired', obj.dwellTimeRequired );
            
        end   
        
        function set.useDwell( obj, value )
            % Changing this property needs to go in and change the Period
            % property of the timer object (if it exists)
            obj.useDwell = value;
            % LOGGING
            Log( obj.logger_h, obj, 'STATE', 'useDwell', obj.useDwell );
        end
        
    end %set/get methods    
    
end %classdef
