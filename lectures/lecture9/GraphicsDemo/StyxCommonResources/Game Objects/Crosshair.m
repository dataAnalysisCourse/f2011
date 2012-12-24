classdef Crosshair < handle
    % The crosshair is a single line that has a free vertex which can be
    % attached and then moved by other objects (for example, the Sphere
    % game object) and another vertex which is affixed to a plane. For now,
    % for simplicity sake, I've made it so that the walls can only be on
    % the main cartesian axes such that two of x y z vary and one is fixed.
    % Eventually this should be expanded to allow the user to specify an
    % arbitrary plane that the crosshair is projected onto.
    
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        descriptiveName = '';  % should be named when created.
        color = [1 1 1];                 % note that trying to set any of the RGB values to
        linewidth = 2;
        visible = true;        % controls whether Sphere is made visible or invisible
        
        freeVertex             % free-moving vertex's [x y z] coordinates
        planeVertex            % vertex attached to a specified plane.
        lockedPlaneDim = 1     % which dimension (1st, 2nd, or third) is locked 
                               % to enforce that the plane Vertex does
                               % indeed move along a plane. 
    end % properties (Access = public)
    
    properties (GetAccess = public, SetAccess = protected)      
		world_h                % the ThreeDWindow object where this game object lives.
        
        logger_h           % handle of the StyxLogger to which it will send all
        % log-worthy events
    end % properties (GetAccess = public, SetAccess = protected)
    
    properties (Access = protected)   

    end % properties (Access = public)
    
    properties (Access = private)
        h                     % graphics line object handle
        xdata = [0 0]         % graphics object properties saved to speed up access
        ydata = [0 0]         % graphics object properties saved to speed up access
        zdata = [0 0]         % graphics object properties saved to speed up access
    end
    
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        % CONSTRUCTOR
        function obj = Crosshair( worldObj, varargin ) % takes a ThreeDworld object
            % and property-value pairs; note that these must be property
            % pairs of the class, not of the (hidden) underlying graphics 
            % object!            
            for i = 1: 2 : length(varargin)
                obj.(varargin{i}) = varargin{i+1};                
            end
            
            % add the world that it's in to object property and register
            % itself with the world
            obj.world_h = RegisterObjectWithWorld( worldObj, obj );
            
            % create the line
            obj.h = line( [obj.freeVertex(1) obj.planeVertex(1)], [obj.freeVertex(2) obj.planeVertex(2)], ...
                [obj.freeVertex(3) obj.planeVertex(3)], 'Parent', obj.world_h.axes, ...
                'Color', obj.color, 'LineWidth', obj.linewidth, 'Clipping', 'off', 'LineSmoothing', 'on');
            obj.xdata = get( obj.h, 'XData');
            obj.ydata = get( obj.h, 'YData');
            obj.zdata = get( obj.h, 'ZData');
                    
        end  % constructor
        
        function delete( obj ) % Destructor
			% if I'm registered with a world object, I should deregister myself.
			if ishandle ( obj.world_h )
				DeregisterObjectWithWorld( obj.world_h, obj )
			end
            if ishandle( obj.h ) % because it might've already been deleted when the world it was part of was deleted
                delete( obj.h )
            end
        end % delete( obj )
        
        
        
        
   end % methods (Access = public)
    
   % --------------------------------------------------
   %                Set/Get Methods
   % --------------------------------------------------
   methods
       function set.freeVertex( obj, newXYZ)          
           obj.freeVertex = newXYZ;
           
           % incorporate new coordinates for freeVertex into private
           % dimdata
           obj.xdata(1) = newXYZ(1);
           obj.ydata(1) = newXYZ(2);
           obj.zdata(1) = newXYZ(3);
           
           % calculate new coordinates for planeVertex and incorporate into
           % private dimdata.
           switch obj.lockedPlaneDim
               case 1
                   obj.ydata(2) = newXYZ(2);
                   obj.zdata(2) = newXYZ(3);
               case 2
                   obj.xdata(2) = newXYZ(1);
                   obj.zdata(2) = newXYZ(3);
               case 3
                   obj.xdata(2) = newXYZ(1);
                   obj.ydata(2) = newXYZ(2);
           end
           obj.planeVertex = [obj.xdata(2) obj.ydata(2) obj.zdata(2)];
           
           if ishandle( obj.h )
               set( obj.h, 'XData', obj.xdata, 'YData', obj.ydata, 'ZData', obj.zdata )
           end

           % LOGGING
           Log( obj.logger_h, obj, 'PROP_SET', 'freeVertex', newXYZ );
       end
       
       function set.color( obj, value )     
           if ~isempty( obj.h ) % there is graphics object to update
               set(obj.h, 'Color', value)
               % LOGGING
               Log( obj.logger_h, obj, 'PROP_SET', 'color', value );
           end           
       end %functionobj = set.color( obj, value )
             
       function set.linewidth( obj, value )
           if ~isempty( obj.h ) % there is graphics object to update
               set(obj.h, 'LineWidth', value)
               % LOGGING
               Log( obj.logger_h, obj, 'PROP_SET', 'linewidth', value );
           end           
       end %functionobj = set.linewidth( obj, value )
	   
	   function set.visible( obj, value )
	   % can make the underlying graphics object visible or invisible
			if obj.visible ~= value % only do stuff if I'm making a change
				obj.visible = value;
				if ~isempty( obj.h ) % there is graphics object to update
					if obj.visible
						set(obj.h, 'Visible', 'on')
					else
						set(obj.h, 'Visible', 'off')
					end
					% LOGGING
					Log( obj.logger_h, obj, 'PROP_SET', 'visible', obj.visible );
				end %if ~isempty( obj.h )
			end
	   end %functionobj = set.color( obj, value )
	   
       
       
   end % set/get methods
    
    
    
    
    
end %classdef