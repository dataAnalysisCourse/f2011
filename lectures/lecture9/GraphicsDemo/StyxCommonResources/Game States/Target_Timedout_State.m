classdef Target_Timedout_State < StyxState
    % Occurs when a target_active state times out. This is the state that
    % it goes to instead of target_acquired, and the nextState should be
    % whatever the next target is. A graphical representation of timedout is
    % done by this state, which changes the target color for a brief
    % period.
    % 
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        target_h
        timedout_period_duration = .33 ;    % how many secs this state lasts
        timedout_target_color = [.8 .5 .5];% target will be changed to this color [default is gray]
        prev_target_color                % used so the Target can revert to what it was
    end %properties (Access = public)
    properties (Access = private)
        targetTimedoutTimer_h             % timer object used to count until
                                          % this state ends
        director_h = 0                    % handle of the Director object to request 
                                          % which nextStateChoices to go to
                                          % next. If it's the default of 0
                                          % for an instance of
                                          % Target_Timedout_State, then no
                                          % call to a Director is made and
                                          % instead the first
                                          % nextStateChoices is used ( for example, in center-out task the noncenter targets always just lead back to center ). 
    end %properties (Access = private)
    
    % *****************************************************
    %                       EVENTS
    % *****************************************************
    events
		TimedOutStartEvt  % notifies listeners as soon as timedout_period starts. 
        TimedOutFinishEvt % notifies listeners upon completion of the timedout_period. Used in some games to recenter cursor after timeout.
    end
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)        
        function obj = Target_Timedout_State( varargin )
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
                     
            % Create a timer object that will be used to time the duration
            % of the acquisition. 
            obj.targetTimedoutTimer_h = timer(...
                'TimerFcn',  {@obj.EndTimedoutTimerFcn} ,  ...
                'ExecutionMode', 'singleShot',  ...
                'Name', 'targetTimedoutTimer', ...
                'StartDelay', obj.timedout_period_duration);            
        end %function obj = InitializeState()
        
        function obj = FalseToTrueImplement( obj )
			% notify anyone who may be listening that the timedout timer
			% has just started
			notify( obj, 'TimedOutStartEvt' );
            start( obj.targetTimedoutTimer_h ) % start timer until end of Acquired period
            obj.prev_target_color =  obj.target_h.color;
            obj.target_h.color = obj.timedout_target_color;       

        end
        
        function obj = TrueToFalseImplement( obj )
            stop( obj.targetTimedoutTimer_h ); % in case it was still going if this state was externally set to false
            obj.target_h.color = obj.prev_target_color;
        end
        
        % DESTRUCTOR
        function delete( obj )
            % delete the timer
            delete( obj.targetTimedoutTimer_h )
        end
        
    end %methods (Access = public)
    
    methods (Access = private)
               
        function EndTimedoutTimerFcn( T_T_S_Obj, timerObj, event )
            % When this timer goes off, target acquisition period is over
            % and it's time to move on to the next state, which will of
            % course call the TrueToFalseImplement method.
			
			% notify anyone who may be listening that the timedout timer is
			% done.
			notify( T_T_S_Obj, 'TimedOutFinishEvt' );
			
            if T_T_S_Obj.director_h == 0 % no director; just go to the first next state choice
                NextState( T_T_S_Obj, 1 );
            else % this instance of the object is under Director control; ask it where to go next                           
                NextState( T_T_S_Obj, T_T_S_Obj.director_h.GetNextStateIndex(  T_T_S_Obj ) );
            end
           
        end           
    end %methods (Access = private)        
    
    % --------------------------------------------------
    %                Set/Get Methods
    % --------------------------------------------------
    methods
        function set.timedout_period_duration( obj, value )
        % Changing this property needs to go in and change the Period
        % property of the timer object (if it exists)
            obj.timedout_period_duration = value;
            if isobject( obj.targetTimedoutTimer_h )
                obj.targetTimedoutTimer_h.StartDelay = value;
            end
        end        
    end %set/get methods
    
    
end %classdef
