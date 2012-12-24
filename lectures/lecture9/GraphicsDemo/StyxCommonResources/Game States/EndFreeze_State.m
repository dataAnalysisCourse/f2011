classdef EndFreeze_State < StyxState
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        
                                  
    end %properties (Access = public)
    
    
  
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        % CONSTRUCTOR
        function obj = EndFreeze_State (varargin )
            % Note that StyxState immediately calls InitializeState method
            % after the constructor.
            obj = obj@StyxState(varargin);
        end %function obj =  G_0001_Start ( )
        
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
            % beep to announce game finish
            beep;
            pause(0.1)
            beep;
            disp('Game Finished')
        end
        
        function obj = TrueToFalseImplement( obj )
            % currently undefined
        end
        
        % DESTRUCTOR
        function delete( obj )
                
        end
        
        
    end %methods (Access = public)
    
    methods (Access = private)

    end %methods (Access = private)
end %classdef