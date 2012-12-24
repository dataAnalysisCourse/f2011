classdef Cursor < Sphere
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        withinTarget = []; % if cursor is within a target, that targets handle goes here
        clickWorks = true; % true or false; determines whether this cursor's clicks are passed to any target it might be on.
	end
    properties (Access = protected)
        clickWav           % used to load the click sound .wav file into memory. The Cursor object creates click.
		defaultColor = [1 1 1];       % if no color is specified when a Cursor is created, then the Cursor constructor
		                              % sets the superclass Sphere's color property to this value.
		defaultRadius = 0.025;        % if no radius is specified during creation, then this default radius will be used
                                      % instead of superclass Sphere's
                                      % default. 
		notifyMoveEveryNsteps = 3     % For computational efficiency, the Cursor can be set to send out notifications to listeners 
		                              % to its movement event (i.e.	Targets) every N (integer >=1 )
		                              % steps instead of every step. As long as N is small and movements frequent, this should be
		                              % imperceptible in terms of how quickly being inside the target is detected.
		                     
		moveNotifyCounter = 0         % counter for above
	end
    
    % *****************************************************
    %                       EVENTS
    % *****************************************************
    events
        MoveEvt
    end
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        % CONSTRUCTOR
        function obj = Cursor( worldObj, varargin ) % takes a ThreeDworld object
            % and property-value pairs. Calls the superclass Sphere
            % Constructor first and then modifies whatever properties may
            % need to be changed.
            obj = obj@Sphere(worldObj);            
            for i = 1: 2 : length(varargin)
                obj.(varargin{i}) = varargin{i+1};
            end
            
            % if no color was specified, use the default cursor color
            if ~any( strcmp(varargin, 'color') )
               obj.color =  obj.defaultColor;
			end
			% if no radius was specified, use the default radius
            if ~any( strcmp(varargin, 'radius') )
               obj.radius =  obj.defaultRadius;
			end
			
			
            % load the click sound wav file
            obj.clickWav = wavread('click.wav');
        end % constructor
        
        
        function obj = SetXYZ( obj, newXYZ )
            oldXYZ = obj.xyz;
            if any( newXYZ ~= oldXYZ )
				obj.moveNotifyCounter = obj.moveNotifyCounter + 1;
                SetXYZ@Sphere( obj, newXYZ )
				if obj.moveNotifyCounter >= obj.notifyMoveEveryNsteps % time to update listeners that cursor has moved.
					notify( obj, 'MoveEvt' )
					obj.moveNotifyCounter = 0; % reset counter to zero
				end
            end

        end % function obj = SetXYZ( obj, newXYZ )
        
        function Click( obj )
        % Peforms a click. If the cursor is within any target, it calls
        % that target's 'AmClicked' method.
             %logging
             Log( obj.logger_h, obj, 'ACTION', 'Click', obj.xyz );     
             % See if the cursor is within a target, and if so call this
             % target's Clicked method.
             if obj.clickWorks && ~isempty( obj.withinTarget )
                 Clicked( obj.withinTarget, obj );
			 end        
             SoundClick( obj ); % play the 'click' sound from its own method.
		end %function Click( obj )
        
		function SoundClick( obj )
	    % plays the click sound and logs it. All sound-playing should have
	    % its own function of this sort -- this makes it much easier to
	    % find all audio events in the log and also allows StyxPlayer to
	    % properly replay them. There should be no arguments (aside from
	    % obj of course) to Sound______ functions.
		     % play the sound
             wavplay( obj.clickWav, 22050, 'async' );
			 Log( obj.logger_h, obj, 'SOUND', 'SoundClick', '' );
		
		end % function SoundClick( obj )
        
        
    end % methods (Access = public)
    % --------------------------------------------------
    %                Set/Get Methods
    % --------------------------------------------------
    methods
        function set.withinTarget( obj, value )
            % used to change the xyz property.
            obj.withinTarget = value;
            
            % LOGGING
            if isobject( obj.withinTarget )
                logString = obj.withinTarget.descriptiveName;
            else
                logString = '0';
            end
            Log( obj.logger_h, obj, 'PROP_SET', 'withinTarget', logString );                
        end
        
        function set.clickWorks( obj, value )
            obj.clickWorks = value;
            % LOGGING
            Log( obj.logger_h, obj, 'PROP_SET', 'clickWorks', obj.clickWorks);       
        end
            
    end % set/get methods
    
end %classdef

