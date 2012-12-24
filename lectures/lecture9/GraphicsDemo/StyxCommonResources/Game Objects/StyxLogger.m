classdef StyxLogger < handle
% Does logging during a Styx game. Although objects that call StyxLogger
% should have a descriptiveName property, StyxLogger can run in vigilant mode
% to make sure that no objects are unnamed or have repeated names.

%  * Constructor creates the file
%  * Log method takes as arguments details of the event being logged, and
%    writes to the file an event line in the appropriate format.
%  * Destructor closes out the file.
%  * Special Usage:
%        If the gameDescriptiveName given during construction is 'NO_LOG',
%        then _________________
%        This is used by StyxPlayback to run a game without actually
%        creating a log file.
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        vigilant = false % if true, will throw a console warning if calling object descriptiveNames repeated.
                         % WARNING: This is SLOW and should only be set to
                         % true during development to make sure each object
                         % has a unique name (otherwise there will be
                         % ambiguity in reconstructing the game vents) 
        objects = {}              % this and descriptiveNames are paired by index
        descriptiveNames = {}     % and store the objects and their names for checking if vigilant (see above).
        
        gameDescriptiveName = []; % should be set during object creation with a more specific name
		version = [0 0 0 0]; % game version; set during contructor by the game.
        saveDir = '/Users/sstavisk/Dropbox/NENS230_private/Lecture 09/GraphicsDemo/log'; % directory where StyxLog should be saved.
        filename

    end %properties (Access = public)
    properties (Access = private)
        fid; % file identifier of open to write file
        STYX_LOGGER_VERSION = '1.02'; % version of StyxLogger
    end
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        % CONSTRUCTOR
        function obj = StyxLogger (varargin )
            for i = 1: 2 : length(varargin) % property-value pair constructor
                obj.(varargin{i}) = varargin{i+1};
            end     
            
            % If this is the special case where gameDescriptiveName is
            % 'NO_LOG' then I set obj.fid to 0 and return. Later I check
            % that obj.fid is nonzero before trying to write.
            if strcmp( obj.gameDescriptiveName, 'NO_LOG' )
                obj.fid = 0;
                return
			end
            
			%--------------------------------------------------
            %           Open the file and name it
			%--------------------------------------------------
			% If the game instance wasn't given a meaningful name, then I
			% automatically append the styx machine timestamp to the
			% default 'NoNameSet' name. If the game WAS given a meaningful
			% name then I just use this for the filename.
			tstamp = clock;
			if strcmp( obj.gameDescriptiveName, 'NoNameSet' )				
				obj.filename = [ obj.gameDescriptiveName '_' ...
					sprintf('%i.%02i.%02i.%i.%i.%02.0f', tstamp(1), tstamp(2), tstamp(3), tstamp(4), tstamp(5), tstamp(6)) ...
					'.styxlog'];
			else 
				obj.filename = [obj.gameDescriptiveName '.styxlog'];
			end %if ...else... strcmp( obj.gameDescriptiveName, 'NoNameSet' )
			

			if ~isdir ( obj.saveDir )
				mkdir( obj.saveDir )
			end
            obj.fid = fopen( [obj.saveDir filesep obj.filename], 'wt' );
            if obj.fid == -1
                error('StyxLogger could not create file %s', [obj.saveDir filesep obj.filename])
			end
            
			%--------------------------------------------------
            % Write header information to the top of the file 
			%--------------------------------------------------
			% First line: block descriptive name (i.e. gameDescriptiveName
			% property of the game.
			logline = ['[' sprintf('%i %02i %02i %i %i %06.3f', tstamp(1), tstamp(2), tstamp(3), tstamp(4), tstamp(5), tstamp(6))  ...
                '] [LOGGER] [' obj.filename '] [START] [' obj.gameDescriptiveName ']\n'];
            fprintf(obj.fid, logline);
			
			% Second line: Game version
			logline = ['[' sprintf('%i %02i %02i %i %i %06.3f', tstamp(1), tstamp(2), tstamp(3), tstamp(4), tstamp(5), tstamp(6))  ...
				'] [LOGGER] [' obj.filename '] [gameVersion] [' sprintf('%i %i %i %i',obj.version(1), obj.version(2), obj.version(3), obj.version(4) )  ']\n'];
			fprintf(obj.fid, logline);
			
			% Third Line: Styx Logger Version
            logline = ['[' sprintf('%i %02i %02i %i %i %06.3f', tstamp(1), tstamp(2), tstamp(3), tstamp(4), tstamp(5), tstamp(6))  ...
                '] [LOGGER] [' obj.filename '] [StyxLoggerVersion] [' obj.STYX_LOGGER_VERSION ']\n'];
            fprintf(obj.fid, logline);
        end %function obj =  StyxLogger ( ) CONSTRUCTOR
        
        
        
        
        function obj = Log(obj, callerObj, eventType, event, parameter )
        % The big enchilada, this method checks the event type and formats
        % the string line that will be written to the file appropriately.
        % INPUTS: 
        %  callerObj handle of the object calling StyxLogger Log methods
        %  eventType string describing what type of event it is. Must be
        %  one of the below types:
        %        PROP_SET                  callerObj property is being set
        %  event     string describing the specific event
        %  parameter value of relevant parameter, e.g. new property value.
        tstamp = clock;
        if obj.fid ~= 0
            % ----------------------------------------------------------
            %              DEV MODE UNIQUE NAME CHECKING
            % ----------------------------------------------------------
            % make sure this callerObj handle doesn't have the same
            % descriptiveName property as any other different handle. Output
            % a warning if it does.
            if obj.vigilant % only do this time-consuming check if vigilant == true
                if isempty(obj.objects)
                    obj.objects{1} = callerObj;
                    obj.descriptiveNames{1} = callerObj.descriptiveName;
                else
                    % check if
                    matches_obj = cellfun( @eq, obj.objects, repmat( {callerObj}, length( obj.objects), 1 ) ); % find if this object already in list
                    if ~any( matches_obj ) % I only care if this is a novel object, since I check for conflicts when a new caller obj appears
                        matches_name = cellfun( @strcmp, obj.descriptiveNames, repmat( {callerObj.descriptiveName}, length( obj.descriptiveNames), 1 ) ); % find if this object already in list
                        if any( matches_name ) % uh oh..
                            firstMatch = find( matches_name, 1);
                            warnMsg = sprintf('\nWARNING: StyxLogger has detected that both object %s and %s have the \ndescriptiveName ''%s''. This will lead to log ambiguity and should be fixed!\n\n', class(callerObj), class(obj.objects{firstMatch}), obj.descriptiveNames{firstMatch} );
                            disp(warnMsg)
                        end
                        obj.objects{end+1,1} = callerObj; % add to the list
                        obj.descriptiveNames{end+1,1} = callerObj.descriptiveName;
                    end
                end
                
            end
            
            
            % ----------------------------------------------------------
            %                        LOG STYX EVENT
            % ----------------------------------------------------------
            switch eventType
                case 'PROP_SET'  % used when game object properties change
                    logline = ['[' sprintf('%i %02i %02i %i %i %06.3f', tstamp(1), tstamp(2), tstamp(3), tstamp(4), tstamp(5), tstamp(6))  ...
                        '] [PROP_SET] [' class(callerObj) ' ' callerObj.descriptiveName '] [' event '] [' num2str(parameter) ']\n'];
                    
                case 'STATE' % used when a property of a styxState change
                    logline = ['[' sprintf('%i %02i %02i %i %i %06.3f', tstamp(1), tstamp(2), tstamp(3), tstamp(4), tstamp(5), tstamp(6))  ...
                        '] [STATE] [' class(callerObj) ' ' callerObj.descriptiveName '] [' event '] [' num2str(parameter) ']\n'];
                    
                case 'ACTION' % used when game object does something that isn't a property change (i.e. is a point event)
                    logline = ['[' sprintf('%i %02i %02i %i %i %06.3f', tstamp(1), tstamp(2), tstamp(3), tstamp(4), tstamp(5), tstamp(6))  ...
                        '] [ACTION] [' class(callerObj) ' ' callerObj.descriptiveName '] [' event '] [' num2str(parameter) ']\n'];
                case 'SYNC' % used to note that a game object is logging a sync code it has received from somewhere else (for instance from the BG2 Core)
                    logline = ['[' sprintf('%i %02i %02i %i %i %06.3f', tstamp(1), tstamp(2), tstamp(3), tstamp(4), tstamp(5), tstamp(6))  ...
						'] [SYNC] [' class(callerObj) ' ' callerObj.descriptiveName '] [' event '] [' num2str(parameter) ']\n'];
				case 'SOUND' % used when game object plays a sound from a Sound____ method.
					logline = ['[' sprintf('%i %02i %02i %i %i %06.3f', tstamp(1), tstamp(2), tstamp(3), tstamp(4), tstamp(5), tstamp(6))  ...
						'] [SOUND] [' class(callerObj) ' ' callerObj.descriptiveName '] [' event '] [' num2str(parameter) ']\n'];
                otherwise
                    error(['Unknown eventType ' eventType]')
            end % switch eventType
            
            % actually writ eto the .styxlog file
            fprintf(obj.fid, logline);
        end %if obj.fid ~= 0
        end
        

        function delete( obj )
           % closing lines written to log
           tstamp = clock;
           logline = ['[' sprintf('%i %02i %02i %i %i %06.3f', tstamp(1), tstamp(2), tstamp(3), tstamp(4), tstamp(5), tstamp(6))  ...
               '] [LOGGER] [' obj.filename '] [FINISH] [ ]\n'];
		   if obj.fid > 0 % in replay mode this is zero and so the fprintf wouldn't work. If logger not created it is negative.
			   fprintf(obj.fid, logline);
			   % close the file			   
			   status = fclose( obj.fid );
			   if status == -1
				   error('StyxLogger could not properly close out styxlog!')
			   end
		   end		
        end
               
    end %methods (Access = public)
    
    % --------------------------------------------------
   %                Set/Get Methods
   % --------------------------------------------------
   methods
       function set.gameDescriptiveName(obj, value)
       % replaces any spaces with _
             value(value == ' ') = '_';
             obj.gameDescriptiveName = value;           
       end
       
   end % set/get methods
    
end %classdef