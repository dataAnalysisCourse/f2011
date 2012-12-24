% Creates a floor object which consists of a 2d plane in the z axis between
% the specified XLim and YLim. Has two underlying graphics options:
% If given the name of a textureFile then
% it'll create a surf object and map this texture onto it. 
% If textureFile is empty then it will create a simple patch object which
% will be monochrome and use the color specified in vector simpleColor.

classdef Floor < handle
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        % Game Object general properties
        descriptiveName = '';  % should be named when created.
        logger_h           % handle of the StyxLogger to which it will send all  log-worthy events

        % Floor-specific properties
        altitude;
        XLim = [ -.625 .625 ]
        YLim = [ -.625 .625 ]
        simpleColor = [.55 .5 .5]; 

    end % properties (Access = public)
    properties (GetAccess = public, SetAccess = protected)
        x % vectors; the x,y vectors are all 4x1 and together with 4x4 z vector define a rectangle
        y 
        z        
        numTiles = 1; % how many times to tile the texture
        textureFile = 'parquetFloor'
        h        % should protected; here for now for ease of debugging
    end % properties (GetAccess = public, SetAccess = protected)
    properties (Access = protected)   
        world_h % handle of the world the Floor object exists in

    end % properties (Access = public)
    
    
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        % CONSTRUCTOR
        function obj = Floor( worldObj, varargin ) % takes a ThreeDworld object
            % and property-value pairs; note that these must be property
            % pairs of the class, not of the (hidden) underlying graphics 
            % object!            
            for i = 1: 2 : length(varargin)
                obj.(varargin{i}) = varargin{i+1};                
            end
            
            % create the vertices of a rectangle in XY plane at altitude
            % spciefied.
            obj.x = [obj.XLim(2) obj.XLim(2) obj.XLim(1) obj.XLim(1)]';
            obj.y = [obj.YLim(2) obj.YLim(1) obj.YLim(1) obj.YLim(2)]';
            

            if ~isempty( obj.textureFile)
                % Create a surf with a texture
                % load the texture and tile it
                load( obj.textureFile )
                textureMap = repmat( floorTexture, obj.numTiles );
                obj.z = repmat( obj.altitude, 4 );
                
                % create the surface plot graphics object that is the actual
                % floor. Flat lighting since having the cursor light it up
                % doesn't work with the camera angle anyway
                
%                 obj.h = surf(obj.x, obj.y, obj.z, 'CData', textureMap, 'FaceColor', 'texturemap', ...
%                     'Parent', worldObj.axes, 'FaceLighting', 'flat', 'EdgeColor', 'none', ...
%                     'DiffuseStrength', 0.3, 'AmbientStrength', 0.3, ...
%                     'SpecularExponent', 50, 'SpecularStrength', 1, 'BackFaceLighting', 'reverselit', ...
%                     'Clipping', 'off');
                obj.h = surf(obj.x, obj.y, obj.z, 'CData', textureMap, 'FaceColor', 'texturemap', ...
                    'Parent', worldObj.axes, 'FaceLighting', 'flat', 'EdgeColor', 'none', ...
                    'DiffuseStrength', 0.3, 'AmbientStrength', 0.3, ...
                    'SpecularExponent', 0, 'SpecularStrength', 1, 'BackFaceLighting', 'reverselit', ...
                    'Clipping', 'off');
            else
                % Create a simple patch                
                obj.z = repmat( obj.altitude, 4,1 );      
                
                obj.h = patch(obj.x, obj.y, obj.z, obj.simpleColor,  ...
                    'Parent', worldObj.axes, 'FaceLighting', 'flat', 'EdgeColor', 'none', ...
                    'DiffuseStrength', 0.0, 'AmbientStrength', 0.5, ...
                    'SpecularExponent', 600, 'SpecularStrength', 0, 'BackFaceLighting', 'unlit', ...
                    'SpecularColorReflectance', 0, 'Clipping', 'off');
            end %if ~isempty( obj.textureFile)

            
            
            % add the world that it's in to object property and register
            % itself with the world
            obj.world_h = RegisterObjectWithWorld( worldObj, obj );
            
            
            
            
            
        end  % constructor
        
        function delete( obj ) % Destructor
            if ishandle( obj.h ) % because it might've already been deleted when the world it was part of was deleted
                delete( obj.h )
            end
        end % delete( obj )
        


   end % methods (Access = public)
    
   % --------------------------------------------------
   %                Set/Get Methods
   % --------------------------------------------------
   methods
       function set.altitude( obj, value)
           % used to change the altitude property and the corresponding z
           % coordinates of the graphics surf object          
           obj.altitude = value;        
           if ~isempty( obj.h ) % there is graphics object to update
               obj.z = repmat( obj.altitude, 4 );
               textureMap = get(obj.h, 'CData');
               set(obj.h, 'ZData', obj.z, 'CData', textureMap);
           end
           
           % LOGGING
           Log( obj.logger_h, obj, 'PROP_SET', 'altitude', value );
	   end
   end % set/get methods
      

end %classdef