classdef Sphere < handle
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        descriptiveName = '';  % should be named when created.
        radius = 0.03;
        color;   % note that trying to set any of the RGB values to
                           % outside the [0 1] range will result in that
                           % displayed value being capped and the intended value
                           % stored in the protected intendedColor, so that
                           % future changes modify the intendedColor. 
        emitsLight = 0;    % if set to 1 then the sphere emits a light of its color
        light_h            % handle to a light; allows sphere to emit light.
        visible = true;    % controls whether Sphere is made visible or invisible
        xyz = [0 0 0];
        transparency = 0;
    end % properties (Access = public)
    
    properties (GetAccess = public, SetAccess = protected)      
        facesN = 20; % spheres will be NxN faces.
		logger_h           % handle of the StyxLogger to which it will send all
		                  % log-worthy events
		world_h            % the ThreeDWindow object where this Sphere lives.
        crosshair_handles = cell(0) % stores handles to crosshairs attached to this
                          % sphere. Any crosshairs attached will move with
                          % the sphere.
    end % properties (GetAccess = public, SetAccess = protected)
    
    properties (Access = protected)   
        sphereX  % these store unit sphere and might be useful later
        sphereY 
        sphereZ
        intendedColor = [0 0 0] % must be initialized to zero or else default color value is meaningless
    end % properties (Access = public)
    
    properties (Access = private)
        h                      % graphics surf object handle
    end
    
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        % CONSTRUCTOR
        function obj = Sphere( worldObj, varargin ) % takes a ThreeDworld object
            % and property-value pairs; note that these must be property
            % pairs of the class, not of the (hidden) underlying graphics 
            % object!            
            for i = 1: 2 : length(varargin)
                obj.(varargin{i}) = varargin{i+1};                
            end
            
            % Get coordinates for the faces of the sphere, and scale and 
            % translate them appropriately
            [obj.sphereX obj.sphereY obj.sphereZ] = sphere( obj.facesN );
            graphics_X = obj.radius .* obj.sphereX + obj.xyz(1); % matrices used for the graphics object
            graphics_Y = obj.radius .* obj.sphereY + obj.xyz(2);
            graphics_Z = obj.radius .* obj.sphereZ + obj.xyz(3);
            
            % add the world that it's in to object property and register
            % itself with the world
            obj.world_h = RegisterObjectWithWorld( worldObj, obj );
			
            
            %Create the sphere graphics object
            % DEV NOTE:  use gouraud instead of phong for faster performance
            % if needed because for these spheres it looks almost as good
            obj.h = surf( graphics_X, graphics_Y, graphics_Z, 'Parent', obj.world_h.axes, 'CData', [], ...
                'FaceColor', obj.color, 'EdgeColor', 'none', 'FaceLighting', 'phong', ...
                'SpecularStrength', 0.9, 'AmbientStrength', 0.5, 'DiffuseStrength', 0.7, ...
                'BackFaceLighting', 'lit', 'SpecularExponent', 10, 'SpecularColorReflectance', 1);          
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
        
        function SetXYZ( obj, newXYZ)
            % used to change the xyz property. I encourage all games to move
            % spheres using the SetXYZ wrapper instead of just obj.xyz = ...
            % so that that subclasses can write their own (shadowing)
            % SetXYZ methods and add appropriate events to them.
            %
            % Note: (2010.01.27) SDS: I've relaxed this restriction and
            % made xyz a public function. This will allow StyxPlayback, for
            % example, do directly move a Sphere without knowing that the
            % logged property change to 'xyz' really requires using a
            % SetXYZ method. GAME WRITERS SHOULD STILL USE SetXYZ methods
            % to move Spheres.
            obj.xyz = newXYZ;
        end % function SetXYZ( obj, newXYZ )
        
        function AttachCrosshair( obj, crossh_h )
            % Attaches a Crosshair object with handle crossh_h to this
            % sphere. The crosshair's .freeVertex will be moved whenever
            % the Sphere moves.
            obj.crosshair_handles{end+1} = crossh_h;
        end % function AttachCrosshair( obj, crossh_h )
        
        
        
   end % methods (Access = public)
    
   % --------------------------------------------------
   %                Set/Get Methods
   % --------------------------------------------------
   methods
       function set.xyz( obj, newXYZ)
           % used to change the xyz property.           
           oldxyz = obj.xyz;
           obj.xyz = newXYZ;
           if ~isempty( obj.h ) % there is graphics object to update
               % Move the actual sphere grahics object
               set(obj.h, ...
                   'XData', get(obj.h, 'XData') + (obj.xyz(1) - oldxyz(1)), ...
                   'YData', get(obj.h, 'YData') + (obj.xyz(2) - oldxyz(2)), ...
                   'ZData', get(obj.h, 'ZData') + (obj.xyz(3) - oldxyz(3)) );
               if obj.emitsLight % if it has a light source
                   set( obj.light_h, 'Position', newXYZ )
                   
               end %
               
               % LOGGING
               Log( obj.logger_h, obj, 'PROP_SET', 'xyz', obj.xyz) ;
               
               % Move any crosshairs if they are attached to this sphere.
              for crossh_i = 1 : length( obj.crosshair_handles )
                  obj.crosshair_handles{ crossh_i }.freeVertex = newXYZ;
              end
               
           end
       end
       
       function set.color( obj, value )
           obj.intendedColor = value;
           realColor = min( value, 1 );
           realColor = max( realColor, 0 );
           if ~isempty( obj.h ) % there is graphics object to update
               set(obj.h, 'FaceColor', realColor)
               % LOGGING
               Log( obj.logger_h, obj, 'PROP_SET', 'color', realColor );
           end           
       end %functionobj = set.color( obj, value )
             
	   function value = get.color( obj )
       % returns the intended value, not the actual color value of the
       % object, which might be capped at 0 or 1 for some of the values.
            value = obj.intendedColor;
	   end
	   
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
	   
       function set.facesN( obj, value )
           obj.facesN = value;
           if ~isempty( obj.h ) % there is graphics object to update
               % changing this is a bit tricky, since several underlying
               % graphics data fields must be changed.
               [obj.sphereX obj.sphereY obj.sphereZ] = sphere( obj.facesN );
               graphics_X = obj.radius .* obj.sphereX + obj.xyz(1); % matrices used for the graphics object
               graphics_Y = obj.radius .* obj.sphereY + obj.xyz(2);
               graphics_Z = obj.radius .* obj.sphereZ + obj.xyz(3);
               set(obj.h, ...
                   'XData', graphics_X , 'YData', graphics_Y, 'ZData', graphics_Z);
           end
           % LOGGING
           Log( obj.logger_h, obj, 'PROP_SET', 'facesN', obj.facesN);
       end %functionobj = set.color( obj, value )
       
              
       function set.radius( obj, value )
           obj.radius = value;
           if ~isempty( obj.h ) % there is graphics object to update
               graphics_X = obj.radius .* obj.sphereX + obj.xyz(1); % matrices used for the graphics object
               graphics_Y = obj.radius .* obj.sphereY + obj.xyz(2);
               graphics_Z = obj.radius .* obj.sphereZ + obj.xyz(3);
               set(obj.h, ...
                   'XData', graphics_X , 'YData', graphics_Y, 'ZData', graphics_Z);
               % LOGGING
               Log( obj.logger_h, obj, 'PROP_SET', 'radius', obj.radius);
           end
       end %functionobj = set.radius( obj, value )
       
       function set.emitsLight( obj, value )           
           % If instructed to, the object can emit light
           if value == 1
               if isempty( ishandle( obj.light_h ) ) % light doesn't already exist
                    obj.light_h = light( 'Position', obj.xyz, 'Color', 1.*obj.color, ...
                        'Style', 'local', 'Parent', obj.world_h.axes );                 
               else 
                  set (obj.light_h, 'Visible', 'on' );                   
               end % if ~isobject( obj.light_h )
               obj.emitsLight = value;
               
           elseif value == 0 % Turn off light
               if ishandle( obj.light_h )
                   set (obj.light_h, 'Visible', 'off' ); 
               end
               obj.emitsLight = value;
           end %if value ==
           % LOGGING
           Log( obj.logger_h, obj, 'PROP_SET', 'emitsLight', obj.emitsLight );           
       end %function set.emitsLight( obj, value )
       
       function set.transparency( obj, value )
           obj.transparency = value;
           if ~isempty( obj.h ) % there is graphics object to update
               set(obj.h, 'FaceAlpha', obj.transparency) 
               % LOGGING
               Log( obj.logger_h, obj, 'PROP_SET', 'transparency', obj.transparency );               
           end
       end %functionobj = set.transparency( obj, value )
       
   end % set/get methods
    
    
    
    
    
end %classdef