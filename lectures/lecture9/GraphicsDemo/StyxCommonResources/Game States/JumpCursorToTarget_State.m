classdef JumpCursorToTarget_State < StyxState
    % This state when it becomes true repositions the cursor whose handle
    % is stored in cursor_h to the coordinates of the target whose hande is
    % given in target_h
	%
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        target_h % handle of target to which the cursor should be jumped.
    end %properties (Access = public)
    properties (Access = private)
        cursor_h; % handle of cursor object
    end %properties (Access = private)

    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)        
        function obj = JumpCursorToTarget_State( varargin )
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
        end %function obj = InitializeState()
		
        function obj = FalseToTrueImplement( obj )
			SetXYZ( obj.cursor_h, obj.target_h.xyz );
			% immediately go to next states
			NextState( obj, 1 : length( obj.nextStateChoices ) );
        end
        
        function obj = TrueToFalseImplement( obj )
            % currently undefined
        end
        
        % DESTRUCTOR
        function delete( obj )
            
        end
        
    end %methods (Access = public) 
    
end %classdef
