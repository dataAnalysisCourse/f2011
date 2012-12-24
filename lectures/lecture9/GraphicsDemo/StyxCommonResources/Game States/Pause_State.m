classdef Pause_State < StyxState
    % This state when it becomes true starts a timer which, when it executes,
    % calls the next state and makes this state false.
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        pause_sec; % how long this state will be on after being true.
    end %properties (Access = public)
    properties (Access = private)
        timer_h
    end %properties (Access = private)
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)        
        function obj = Pause_State( varargin )
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
                'TimerFcn',  {@obj.P_S_TimerFcn} ,  ...
                'ExecutionMode', 'singleShot',  ...
                'Name', 'pauseStateTimer', ...
                'StartDelay', obj.pause_sec);
            
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
        
        function P_S_TimerFcn( P_S_Obj, timerObj, event )
        % When the timer goes off, it's time to move to the next state
            NextState( P_S_Obj, 1:length(P_S_Obj.nextStateChoices ) ); % transition to all the next state choices
        end
        
                       
    end %methods (Access = private)        
    
    
end %classdef
