classdef Target_Acquired_State < StyxState
    % Occurs after a target is acquired, flashes the target a certain color
    % for a period of time before transitioning to the next state
    % (presumably the next target).
    % 
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        target_h
        acquired_period_duration = 1 ;    % how many secs this state lasts
        acquired_color_change = [-.7 .7 .0];% target color will be changed by this amount 
    end %properties (Access = public)
    properties (Access = private)
        targetAcquiredTimer_h             % timer object used to count until
                                          % this state ends.
        director_h = 0                   % handle of the Director object to request 
                                          % which nextStateChoices to go to
                                          % next. If it's the default of 0
                                          % for an instance of
                                          % Target_Acquired_State, then no
                                          % call to a Director is made and
                                          % instead the first
                                          % nextStateChoices is used ( for example, in center-out task the noncenter targets always just lead back to center ). 
    end %properties (Access = private)
    
    % *****************************************************
    %                       EVENTS
    % *****************************************************

    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)        
        function obj = Target_Acquired_State( varargin )
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
            obj.targetAcquiredTimer_h = timer(...
                'TimerFcn',  {@obj.EndAcquiredTimerFcn} ,  ...
                'ExecutionMode', 'singleShot',  ...
                'Name', 'targetAcquiredTimer', ...
                'StartDelay', obj.acquired_period_duration);            
        end %function obj = InitializeState()
        
        function obj = FalseToTrueImplement( obj )
            start( obj.targetAcquiredTimer_h ) % start timer until end of Acquired period
            obj.target_h.color = obj.target_h.color + obj.acquired_color_change;
        end
        
        function obj = TrueToFalseImplement( obj )
            stop( obj.targetAcquiredTimer_h ); % in case it was still going if this state was externally set to false
            obj.target_h.color = obj.target_h.color - obj.acquired_color_change;      
        end
        
        % DESTRUCTOR
        function delete( obj )
            % delete the timer
            delete( obj.targetAcquiredTimer_h )
        end
        
    end %methods (Access = public)
    
    methods (Access = private)
               
        function EndAcquiredTimerFcn( T_A_S_Obj, timerObj, event )
            % When this timer goes off, target acquisition period is over
            % and it's time to move on to the next state, which will of
            % course call the TrueToFalseImplement method.
            if T_A_S_Obj.director_h == 0 % no director; just go to the first next state choice
                NextState( T_A_S_Obj, 1 );
            else % this instance of the object is under Director control; ask it where to go next
                NextState( T_A_S_Obj, T_A_S_Obj.director_h.GetNextStateIndex(  T_A_S_Obj ) );
            end
           
        end           
    end %methods (Access = public)        
    
    % --------------------------------------------------
    %                Set/Get Methods
    % --------------------------------------------------
    methods
        function set.acquired_period_duration( obj, value )
        % Changing this property needs to go in and change the Period
        % property of the timer object (if it exists)
            obj.acquired_period_duration = value;
            if isobject( obj.targetAcquiredTimer_h )
                obj.targetAcquiredTimer_h.StartDelay = value;
            end
        end        
    end %set/get methods
    
    
end %classdef
