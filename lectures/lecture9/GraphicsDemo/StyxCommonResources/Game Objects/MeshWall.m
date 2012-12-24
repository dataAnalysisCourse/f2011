% The MeshWall object is a wire-frame 'wall' that can be added to a world.
% The four vertex locations of the wall are specified as well as the number
% of horizontal and vertical lines comprise the face (the more lines, the
% denser the mesh appears). Note that the four vertices must be entered
% clockwise (or counterclockwise) and numLinesD1 refers to lines parallel
% to line vert1->vert2 and numLinesD2 refers to lines parallel to line
% vert2->vert3. 

classdef MeshWall < handle

    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        descriptiveName = '';  % should be named when created.
        world_h            % the ThreeDWindow object where this Sphere lives.
        color              % color of the mesh wall lines
                           % note that trying to set any of the RGB values to
                           % outside the [0 1] range will result in that
                           % displayed value being capped and the intended value
                           % stored in the protected intendedColor, so that
                           % future changes modify the intendedColor. 

						 

    end % properties (Access = public)
    properties (GetAccess = public, SetAccess = protected)
        % These can't be set externally for now because I haven't made set
        % methods for each property that would affect the underlying
        % graphics objects. I don't anticipate mesh walls changing after
        % their initial creation, but if so then I'll need to add the set
        % methods which manipulate
		
		numLinesD1 = 2; % must be >= 2
		numLinesD2 = 2; % must be >= 2
        linewidth = 1.5;       % thickness off the mesh wall lines

		vert1 = [-.4 .4 0]; % row vector
		vert2 = [.4 .4 0];
		vert3 = [.4 -.4 0];
		vert4 = [-.4 -.4 0];
		
        logger_h          % handle of the StyxLogger to which it will send all log-worthy events
    end % properties (GetAccess = public, SetAccess = protected)
    properties (Access = protected)   
        intendedColor  % must be initialized to zero or else default color value is meaningless
        h_vec_D1  % handles of the lines that go in the D1 direction
        h_vec_D2  % handles of the lines that go in the D2 direction
    end % properties (Access = public)
    
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        % CONSTRUCTOR
        function obj = MeshWall( worldObj, varargin ) % takes a ThreeDworld object
            % and property-value pairs; note that these must be property
            % pairs of the class, not of the (hidden) underlying graphics 
            % object!            
            for i = 1: 2 : length(varargin)
                obj.(varargin{i}) = varargin{i+1};                
            end
            
            % add the world that it's in to object property
            obj.world_h = worldObj;
            
            % ----------------------------------------------------
            %      Compute the lines making up the wall
            % ----------------------------------------------------
			% Make sure that at least 2 lines make up each direction
			% (otherwise the "wall" won't even be a square)
			% NOTE: I might want to relax this restriction to allow not a
			% mesh but just lines in a given direction!
			
            % preallocate their handles
            obj.h_vec_D1 = zeros( obj.numLinesD1, 1);
            obj.h_vec_D2 = zeros( obj.numLinesD2, 1);
            
            % -----------------------------------------------------
            %        Create the direction 1 (D1) lines
            % -----------------------------------------------------
			% I accomodate two special cases; if numLines is 1 then I put
			% the single line at the midpoints of the appropriate vertices,
			% and if numLines is 0 then there will be no lines in this
			% direction.
			
			
            % Compute their start and end vertices
			[startVertices endVertices] = obj.ComputeOneDofLines( obj.numLinesD1, ...
                [obj.vert1; obj.vert2; obj.vert3; obj.vert4], 1, 2);
			% Now create these lines TODO: Continue here!
			for i = 1 : length( obj.h_vec_D1 )
				obj.h_vec_D1(i) = line( [startVertices(i,1) endVertices(i,1)], [startVertices(i,2) endVertices(i,2)], ...
                    [startVertices(i,3) endVertices(i,3)], 'Parent', obj.world_h.axes, ...
                    'Color', obj.color, 'LineWidth', obj.linewidth, 'Clipping', 'off', 'LineSmoothing', 'on' );
			end
			
            % -----------------------------------------------------
            %        Create the direction 2 (D2) lines
            % -----------------------------------------------------
            % Compute their start and end vertices
			[startVertices endVertices] = obj.ComputeOneDofLines( obj.numLinesD2, ...
                [obj.vert1; obj.vert2; obj.vert3; obj.vert4], 2, 3);
			% Now create these lines TODO: Continue here!
			for i = 1 : length( obj.h_vec_D2 )
				obj.h_vec_D2(i) = line( [startVertices(i,1) endVertices(i,1)], [startVertices(i,2) endVertices(i,2)], ...
                    [startVertices(i,3) endVertices(i,3)], 'Parent', obj.world_h.axes, ...
                    'Color', obj.color, 'LineWidth', obj.linewidth, 'Clipping', 'off', 'LineSmoothing', 'on' );
			end

               
        end  % constructor
        
        function delete( obj ) % Destructor
			% don't need to delete the sublines because they are deleted in
			% the recursive ThreeDWorld destructor
        end % delete( obj )
        
     
        
        
   end % methods (Access = public)
    
   % --------------------------------------------------
   %                Set/Get Methods
   % --------------------------------------------------
   methods
       
      function set.color( obj, value )
           obj.intendedColor = value;
           realColor = min( value, 1 );
           realColor = max( realColor, 0 );
           if ~isempty( obj.h_vec_D1 ) || ~isempty( obj.h_vec_D2 )% there is at least one graphics object to update
               for i = 1 : length( obj.h_vec_D1 )
                   set(obj.h_vec_D1(i), 'Color', realColor);
               end
               for i = 1 : length( obj.h_vec_D2 )
                   set(obj.h_vec_D2(i), 'Color', realColor);
               end               
               % LOGGING
               Log( obj.logger_h, obj, 'PROP_SET', 'color', realColor );
           end           
       end %function obj = set.color( obj, value )
       
      function value = get.color( obj )
       % returns the intended value, not the actual color value of the
       % object, which might be capped at 0 or 1 for some of the values.
            value = obj.intendedColor;
	  end %function value = get.color( obj )
       
   end % set/get methods
    
    methods (Static)
        function [startVertices endVertices] = ComputeOneDofLines( numLines, vertices, startVertexInd, endVertexInd)
            % computes the start and end vertices for the <numLines>  evenly spaced
			% lines that are pseudoparallel (i.e. parallel if vertices make a parallelogram) for the four
            % vertices (one per row) in vertices. The lines run in the same
            % pseudo-direction as the line from vertices specified by
            % startVertexInd and endVertexInd. The endpoints of these set of lines
            % are found by finding the two bounding lines(edges) that the
            % ~parallel line set has endpoints on and the subdividing these to
            % find the desired lines' endpoints. NOTE: startVertexInd
			% and endVertexInd must refer to adjascent vertices.
			
			% I will define the two (non-returned) lines that touch all of
			% the desired lines' endpoints as edgeL1 and edgeL2.
			% startVertices will be along edgeL1 and endVertices will be
			% along edgeL2
			
			
			
			% based on start- and endVertexInd figure out which vertices
			% define the ends of edgeL1 and edgeL2
			edgeL1StartInd = mod(startVertexInd+3,4);
			if edgeL1StartInd == 0
				edgeL1StartInd = 4;
			end
			edgeL1EndInd = startVertexInd;
			
			edgeL2StartInd = mod(startVertexInd+2,4);
			if edgeL2StartInd == 0
				edgeL2StartInd = 4;
			end
			edgeL2EndInd = endVertexInd;
			
			% preallocate the return values
			startVertices = zeros( numLines, 3); % each row is a returned line start vertex
			endVertices   = zeros( numLines, 3); % " " " " "  end vertex
			
			% ----------------------------------------------
			%          special case: numLines = 1
			% ----------------------------------------------
			if numLines == 1
				% start- and endVertices are just midpoints along edgeL1
				% and edgeL2 respectively
				startVertices = vertices(edgeL1StartInd,:)+ (vertices(edgeL1EndInd,:) - vertices(edgeL1StartInd,:))/2;
				endVertices   = vertices(edgeL2StartInd,:)+ (vertices(edgeL2EndInd,:) - vertices(edgeL2StartInd,:))/2;
				
		    % ----------------------------------------------
			%            numLines >= 2
			% ----------------------------------------------
			else
				% compute edge1 and its unit vector and spacing along it
				edgeL1Start = vertices(edgeL1StartInd,:);
				edgeL1End   = vertices(edgeL1EndInd,:);
				edge1 = edgeL1End- edgeL1Start;
				unitEdge1 = edge1 ./ (edge1*edge1');
				% compute spacing along edgeL2 between individual mesh lines. This
				% equals the length of this Edge divided by the number of lines
				% that terminate on it.
				edge1Spacing = (edge1*edge1')/ (numLines-1); % subtract 1 because spaces is 1 less than points.
				
				% compute edge2 and its unit vector and spacing along it
				% the vertices i'm using now are the other two vertices;
				edgeL2Start = vertices(edgeL2StartInd,:);
				edgeL2End   = vertices(edgeL2EndInd,:);
				edge2 = edgeL2End - edgeL2Start;
				unitEdge2 = edge2 ./ (edge2*edge2');
				% compute spacing along edgeL2 between individual mesh lines. This
				% equals the length of this Edge divided by the number of lines
				% that terminate on it.
				edge2Spacing = (edge2*edge2')/ (numLines-1); % subtract 1 because spaces is 1 less than points.
				
				% now find the start and end vertices of the lines of interest
				% by dropping vertices along edge1 and edge2 every edgeSpacing
				% distance along the unitEdge
				for i = 1 : numLines
					startVertices(i,:) = edgeL1Start + (i-1)*edge1Spacing*unitEdge1;
					endVertices(i,:) = edgeL2Start + (i-1)*edge2Spacing*unitEdge2;
				end %for i = 1 : numLines
			end %if numLines == 1
		end % function [startVertices endVertices] = ComputeOneDofLines( numLines, vertices, startVertexInd, endVertexInd)
		
	end
    
    
    
end %classdef