classdef JumpCursor_State < StyxState
    % This state when it becomes true repositions the cursor whose handle
    % is stored in cursor_h.
	%
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        cursorDestination = [0 0 0]; % destination of cursor
        jumpCursor_dur = -1 ;       % how many secs after cursor jumps before next 
                                    % state begins (if no delay desired, set to <= 0) 
    end %properties (Access = public)
    properties (Access = private)
        cursor_h                    % handle of cursor object
        jumpCursorTimer_h           % timer object used to count until
                                    % this state ends
        director_h = 0;
    end %properties (Access = private)

    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)        
        function obj = JumpCursor_State( varargin )
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
            
            if obj.jumpCursor_dur > 0
                % Create a timer object that will be used to time the duration
                % of the jump state (i.e. add a delay before next target appears).
                obj.jumpCursorTimer_h = timer(...
                    'TimerFcn',  {@obj.JumpCursorTimerFcn} ,  ...
                    'ExecutionMode', 'singleShot',  ...
                    'Name', 'jumpCursorTimer', ...
                    'StartDelay', obj.jumpCursor_dur);  
            end

        end %function obj = InitializeState()
		
        function obj = FalseToTrueImplement( obj )
			SetXYZ( obj.cursor_h, obj.cursorDestination );
            if obj.jumpCursor_dur > 0,               
                start( obj.jumpCursorTimer_h );       
            else
			% immediately go to next states
                NextState( obj, 1 : length( obj.nextStateChoices ) );                
        end
        end
        
        function obj = TrueToFalseImplement( obj )
            if obj.jumpCursor_dur > 0
                stop( obj.jumpCursorTimer_h );
        end
        end
        
        % DESTRUCTOR
        function delete( obj )
            if obj.jumpCursor_dur > 0
                delete( obj.jumpCursorTimer_h );           
        end
        end
        
    end %methods (Access = public) 
    
    methods (Access = private)
        
        function JumpCursorTimerFcn( J_C_Obj, timerObj, event )
        % When the timer goes off, it's time to move to the next state            
            if J_C_Obj.director_h == 0
                NextState( J_C_Obj, 1:length(J_C_Obj.nextStateChoices ) );
            else               
                NextState( J_C_Obj, J_C_Obj.director_h.GetNextStateIndex(  J_C_Obj ) );
            end
        end
        
                       
    end %methods (Access = private)      
    
end %classdef
