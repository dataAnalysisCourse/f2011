classdef ThreeDwindow < handle
% Creates a MATLAB figure containing a three-D axis. Most game objects will
% have underlying graphics objects within this ThreeDwindow. I keep track
% of which GameObjects are such children in the childObjects cell array
% property. Note that this linkage isn't mandatory - it is not enforced
% that a GameO bject be linked to ThreeDwindow. But, if they are, then the
% object's delete method ought to remove the Game Object from the
% ThreeDwindow childObjects list. 
% Changes to graphics properties are logged using logger_h. 
% TODO: Add proper Set/Get methods for the camera view stuff.


    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        color = 0.*[1 1 1]; % color of the figure and axes;
        displayName = 'Game Engine Demo';
		xlim = [-.625 .625]
		ylim = [-.5 .5]
		zlim = [-.5 .5]
		childObjects; % cell array of handles to Game Objects who exist in this world (i.e. their graphical object is an actual child
				% of the axes). Must be public so someone accessing it can
				% actually make changes to these underlying objects
				% (example: make every object in the world invisible). 
	    descriptiveName = 'ThreeDwindow';
        
        position           % figure position
        % Camera-related properties
        view = [0    90]             % Camera view
        cameraViewAngle = 6.0655    
		cameraPosition = [0         0    9.4373]      
		cameraUpVector = [0 1 0]
		cameraTarget   = [0 0 0]
    end % properties (Access = public)
    
    properties (GetAccess = public, SetAccess = private)
        h;                 % handle of the figure
        axes;              % handle of the 3D axis


		logger_h           % handle of the StyxLogger to which it will send all
		                   % log-worthy events
                           
         
    end %(GetAccess = public, SetAccess = private)
    
   
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        
        % CONSTRUCTOR
        function obj = ThreeDwindow( varargin )			
			% property-value pairs used during construction object!            
            for i = 1: 2 : length(varargin)
                obj.(varargin{i}) = varargin{i+1};                
            end
			
            % figure starts full-screen, so initially size it close to that
            
			screenSize = get(0,'ScreenSize');
            % Create the figure
            obj.h = figure('Name', obj.displayName, ...
                'ToolBar', 'none', 'DockControls', 'Off', 'MenuBar', 'none', ...
                'NumberTitle', 'off', 'Color', obj.color, 'Position', screenSize);
           
			% now fullscreen it
% 			maximize( obj.h )   % I'm trying to set position instead of
% 			maximize. 
            obj.position = [1 1 1280 1024]; 
            
            % Create the axes
            obj.axes = axes;
             set(obj.axes, 'DataAspectRatioMode', 'manual', ...
                 'PlotBoxAspectRatioMode', 'manual', 'Position', [0 0 1 1], ...
                 'TickLength', [0 0], 'XTick', [], 'YTick', [], 'ZTick', [],...
                 'Color', obj.color, 'XColor', obj.color, 'YColor', obj.color, 'ZColor', obj.color, ...
				 'CameraViewAngle', obj.cameraViewAngle, 'CameraPosition', obj.cameraPosition, ...
				 'CameraUpVector', obj.cameraUpVector, 'CameraTarget', obj.cameraTarget )
             
            % Make axis limits in all 3 dimensions
            set(obj.axes, 'XLim', obj.xlim, 'YLim', obj.ylim, 'ZLim', obj.zlim)
            set(gca,'CameraViewAngleMode','manual')
            camproj('perspective')
            % set hold on on this axis
            hold(obj.axes, 'on')
            
            % -----------------------------------------------------
            %                 3D Graphics Settings
            % -----------------------------------------------------
            camlight left 
            
        end % CONSTRUCTOR
                
        
		function obj = RegisterObjectWithWorld( obj, childObj )
		% adds the handle of childObj to the cell array childObjects. Makes
		% sure that no GameObject is double-counted by testing if the new
		% object already is in the list. Returns handle to this object so
		% that the GameObject can call this method when setting its world_h
		% property. 
			for i = 1 : length( obj.childObjects)
				if childObj == obj.childObjects{i}
					fprintf('Warning: RegisterObjectWithWorld from ThreeDwindow found that an object being added is already in the childObjects list.')
					return
				end
			end
			obj.childObjects{end+1} = childObj;
		end
		
		function DeregisterObjectWithWorld( obj, childObj )
	    % goes through the childObj cell array, finds the childObj that is
	    % being removed, excises it from the list, and shortens the list so
	    % there are no empty entries. 
			for i = 1 : length( obj.childObjects )
				if childObj == obj.childObjects{i}
					obj.childObjects = [ obj.childObjects(1:i-1) obj.childObjects(i+1:end)]; 
					return
				end
			end
			% if I've gone this far, I couldn't find the childObj to
			% unlink. 
			fprintf('Warning: DeregisterObjectWithWorld from ThreeDWindow could not find this childObj in the existing childObjects. No unlinking was done.\n')	
		end %UnlinkWorldWithObject( obj, childObj )
			
        % DESTRUCTOR
        function delete(obj)
%             % find the axis children graphics objects
%             children_handles = get(obj.axes, 'Children');
%             for i = 1 : length( children_handles )
%                 delete( children_handles(i) )
%             end
            % Delete all the childObjects
			for i = 1 : length( obj.childObjects )
				delete( obj.childObjects{i} )
			end
            delete(obj.h);            
        end % destructor
        
    end %methods
    
    % --------------------------------------------------
   %                Set/Get Methods
   % --------------------------------------------------
   methods
	   
       function set.position( obj, value )
		   if ~isempty( obj.h ) % there is graphics object to update
			   obj.position = value;
			   set(obj.h, 'Position', value)
           end
           % LOGGING
           Log( obj.logger_h, obj, 'PROP_SET', 'position', value );
	   end %functionobj = set.color( obj, value )
       
	   function set.color( obj, value )
		   if ~isempty( obj.h ) % there is graphics object to update
			   obj.color = value;
			   % need to change color of both figure and axes
			   set(obj.h, 'Color', value)
			   set(obj.axes, 'Color', obj.color,'XColor', obj.color, 'YColor', obj.color, 'ZColor', obj.color)
           end
           % LOGGING
           Log( obj.logger_h, obj, 'PROP_SET', 'color', value );
	   end %functionobj = set.color( obj, value )
	   
	   function set.xlim( obj, value )
		   obj.xlim = value;
		   if ~isempty( obj.axes ) % there is graphics object to update
			  set(obj.axes, 'XLim', obj.xlim )
           end
           % LOGGING
           Log( obj.logger_h, obj, 'PROP_SET', 'xlim', value );
	   end %functionobj = set.xlim( obj, value )
	   
	   function set.ylim( obj, value )
		   obj.ylim = value;
		   if ~isempty( obj.axes ) % there is graphics object to update
			   set(obj.axes, 'YLim', obj.ylim )
           end
           % LOGGING
           Log( obj.logger_h, obj, 'PROP_SET', 'ylim', value );
	   end %functionobj = set.ylim( obj, value )
	   
	   function set.zlim( obj, value )
		   obj.zlim = value;
		   if ~isempty( obj.axes ) % there is graphics object to update
			   set(obj.axes, 'ZLim', obj.ylim )
           end
           % LOGGING
           Log( obj.logger_h, obj, 'PROP_SET', 'zlim', value );
	   end %functionobj = set.zlim( obj, value )
       
       function set.view( obj, value )
           obj.view = value;
           if ~isempty( obj.axes )
               set( obj.axes, 'View', value )
           end
           % LOGGING
           Log( obj.logger_h, obj, 'PROP_SET', 'view', value );
       end %function set.view( obj, value )
       
       function set.cameraViewAngle( obj, value )
           obj.cameraViewAngle = value;
           if ~isempty( obj.axes )
               set( obj.axes, 'CameraViewAngle', value )
           end
                      % LOGGING
           Log( obj.logger_h, obj, 'PROP_SET', 'cameraViewAngle', value );
	   end %function set.cameraViewAngle( obj, value )
	   
	   function set.cameraPosition( obj, value )
		   obj.cameraPosition = value;
		   if ~isempty( obj.axes )
			   set( obj.axes, 'CameraPosition', value )
		   end
		   % LOGGING
		   Log( obj.logger_h, obj, 'PROP_SET', 'cameraPosition', value );
	   end %function set.cameraPosition( obj, value )
	   
	   function set.cameraUpVector( obj, value )
		   obj.cameraUpVector = value;
		   if ~isempty( obj.axes )
			   set( obj.axes, 'CameraUpVector', value )
		   end
		   % LOGGING
		   Log( obj.logger_h, obj, 'PROP_SET', 'cameraUpVector', value );
	   end %function set.cameraUpVector( obj, value )
	   
	   function set.cameraTarget( obj, value )
		   obj.cameraTarget = value;
		   if ~isempty( obj.axes )
			   set( obj.axes, 'CameraTarget', value )
		   end
		   % LOGGING
		   Log( obj.logger_h, obj, 'PROP_SET', 'cameraTarget', value );
	   end %function set.cameraTarget( obj, value )
       
   end % set/get methods
    
    
    
    
end % classdef