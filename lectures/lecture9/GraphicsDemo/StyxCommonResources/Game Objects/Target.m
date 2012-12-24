classdef Target < Sphere
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    
    properties (Access = public)
        cursorWithin = false;
        active = false;
        cursorWithinColorChange = [0 0 0];   % added to color if cursor inside
        activeColorChange = [0 -.8 .2];        % added to color if it is made active
        cursorWithinTransparencyChange = 0;  % becomes this much MORE transparent when cursor inside
        activeTargetTransparencyChange = 0.2;  % becomes this much LESS transparent when active target
    end %properties (Access = public)
    
    properties (Access = protected)
        TARGET_TRANSPARENCY = .35;             % normal transparency
        lh                                    % listener handle 
		defaultColor = [1 1 0];      % if no color is specified when a Target is created, then the Target constructor
	                                  % sets the superclass Sphere's color property to this value.
		defaultRadius = 0.04;         % if no radius is specified during creation, then this default radius will be used
									  % instead of superclass Sphere's default.
		justBecameActive = false;     % set to true when Target becomes active. This is used in the CursorMoveEvtCallback
		                              % to broadcast cursorWithin even if
		                              % cursor was already within the
		                              % target when it became active (which
		                              % otherwise wouldn't notify, since
		                              % the notifcation would have happened
		                              % earlier when the TargetActiveState
		                              % wasn't listening since it was
		                              % false.
    end %properties (Access = protected)
    
    
    % *****************************************************
    %                       EVENTS
    % *****************************************************
    events
        CursorWithinEvt % event that the target now does or doesn't have the cursor in it
        ClickedEvt      % event that this Target has been clicked on.
    end % events
    
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        % CONSTRUCTOR
        function obj = Target( worldObj, varargin ) % takes a ThreeDworld object
            % and property-value pairs. Calls the superclass Sphere
            % Constructor first and then modifies whatever properties may
            % need to be changed.
            
            obj = obj@Sphere(worldObj);
            for i = 1: 2 : length(varargin)
                obj.(varargin{i}) = varargin{i+1};
			end
			
			% if no color was specified, use the default Target color
            if ~any( strcmp(varargin, 'color') )
               obj.color =  obj.defaultColor;
            end
			% if no radius was specified, use the default radius
            if ~any( strcmp(varargin, 'radius') )
               obj.radius =  obj.defaultRadius;
			end
			
            obj.transparency = obj.TARGET_TRANSPARENCY;       
        end % constructor
        
        function obj = LinkToCursor( obj, cursorObj, eventName )
            % this method will create a listener for this target to the
            % cursor object whose handle is cursorObj for the event of the
            % name specified by string eventName. Note that the name of the
            % callback is contained inside and links to a private method
            obj.lh = addlistener( cursorObj, eventName, @obj.CursorMoveEvtCallback );
            obj.lh.Enabled = true; % listener should be enabled because a target can be highlighted even if not active
        end
        
        function obj = MakeActive(obj)
            % Assumes state is inactive; will set the object's .active
            % property to true and change its color by adding
            % its activeColorChange value.
            if obj.active ~= false
                fprintf('MakeActive: Assumption that Target is false is erroneous. Check your logic.\n')
                error('MakeActive: Assumption that Target is false is erroneous. Check your logic.')
			else
				% Make the target active and change graphics accordingly
				obj.active = true;
                obj.color = obj.color + obj.activeColorChange;
                obj.transparency = obj.transparency + obj.activeTargetTransparencyChange;
				
				% Used for broadcasting targetWithinEvt even when the
				% cursor was already within target when the Target becomes
				% active.
				obj.justBecameActive = true;	
				
            end
        end
        
        function obj = MakeInactive(obj)
            % Assumes state is active; will set the object's .active
            % property to false and change its color by subtracting
            % its activeColorChange value.
            if obj.active ~= true
                fprintf('MakeInactive: Assumption that Target is true is erroneous. Check your logic.\n')
                error('MakeInactive: Assumption that Target is true is erroneous. Check your logic.')
            else
                obj.active = false;
                obj.color = obj.color - obj.activeColorChange;
                obj.transparency = obj.transparency - obj.activeTargetTransparencyChange;
            end
        end
        
        function obj = Clicked( obj, clickerObj )
             % The target has been clicked, presumably by a cursor (the
             % handle of the click-causing object is passed in clickerObj.)
             % If this is an active target, then it sends an AmClicked event    
             if obj.active                 
                 logstring = [clickerObj.descriptiveName ' while_active'];
             else                
                 logstring = [clickerObj.descriptiveName ' while_inactive'];
             end
             % LOGGING
             Log( obj.logger_h, obj, 'ACTION', 'Clicked', logstring );
             %broadcast that this Target has been clicked.
             notify( obj, 'ClickedEvt' );
        end
        
    end % methods (Access = public)
   
    % --------------------------------------------------
   %            Set/Get Methods - used for logging
   % --------------------------------------------------
   methods
       function set.active( obj, value )
          obj.active = value;
          % LOGGING
          Log( obj.logger_h, obj, 'PROP_SET', 'active', obj.active );
       end
       
       function set.cursorWithin( obj, value )
           obj.cursorWithin = value;
           % LOGGING
           Log( obj.logger_h, obj, 'PROP_SET', 'cursorWithin', obj.cursorWithin);
       end
       
   end % set/get methods
    
    
   methods (Access = protected)
        function obj = CursorMoveEvtCallback( obj, eventSrc, eventData )
            % check to see if the cursor is now within this target
            diff = obj.xyz - eventSrc.xyz;
            if diff*diff' < (obj.radius + eventSrc.radius) ^2 % cursor edge is within target edge
                if ~obj.cursorWithin % cursor has just entered target
                    % Inform the cursor object that it is within this target
                    eventSrc.withinTarget = obj;   
                    obj.cursorWithin = true; % now cursor is in target
                    obj.color = obj.color + obj.cursorWithinColorChange; % brighten the target                    
                    notify( obj, 'CursorWithinEvt' ) % listened to in Target_Active_State
                    % make more transparent
                    obj.transparency = obj.transparency - obj.cursorWithinTransparencyChange;
                    % get rid of true justBecameActive (if it's true) so I
                    % don't double-notify
                    if obj.justBecameActive == true
                        obj.justBecameActive = false;
                    end
				elseif obj.justBecameActive % cursor continues to be inside taget but target used to be inactive and so original notify was probably not listened to
                    % broadcast the notification but don't do any graphics
                    % changes since they would have already happened when
                    % the cursor first entered the Target.
					obj.justBecameActive = false;
					notify( obj, 'CursorWithinEvt' ) % listened to in Target_Active_State				
                end
            else % cursor is outside target
                if obj.cursorWithin % cursor has just left target
                    % Inform the cursor object that it is no longer in a
                    % target. This assumes there cannot be two overlapping
                    % targets.
                    eventSrc.withinTarget = [];    
					
                    obj.cursorWithin = false; % now cursor is now outside this Target
                    obj.color = obj.color - obj.cursorWithinColorChange; % return to original color                    
                    notify( obj, 'CursorWithinEvt' ) % listened to in Target_Active_State
                    % make less transparent
                    obj.transparency = obj.transparency + obj.cursorWithinTransparencyChange;
                else
                    
                end
            end
        end
        
        
        
    end % methods (Access = public)
    
end %classdef