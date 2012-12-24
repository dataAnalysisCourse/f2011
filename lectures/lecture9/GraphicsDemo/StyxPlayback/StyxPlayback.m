
% CONSTRUCTOR INPUTS:
%     filename    filename (optionally with path) of the .styxlog file
%                 which is to be played back.
%     styxPath    path of the Styx directory. This should point to the version
%                 of Styx that was used to run the game (so typically located in
%                 the Software directory of a session, e.g.
%                 'C:\BrainGate\BrainGateMatlab\BG2Development\My Dropbox\Styx'
% METHODS:
%     StyxPlayback (constructor) adds to path the styxPath for the software
%                                of same version as the styxlog. Also loads
%                                and parses the styxlog, readies a list of every
%                                logged event and the time interval between them,
%                                creates the game start state, identifies
%                                all the graphical objects and keeps a
%                                handle to them so as to re-enact their
%                                property change events during the
%                                playback.
%     DoPlayback   This is the main playback loop method. Once called it
%                  will run in a while loop as long as the continuePlayback
%                  property is true.
% HELPER METHODS;
%    dName2Handle( dName )


classdef StyxPlayback < handle
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        % INITIALIZATION-RELATED PROPERTIES
        startSt        % game start state; creating this creates all game
        % objects, and manipulating them allows me to replay
        % the game events
        gameObjects    % array of handles to each of the game objects in the
        % styx game which have graphical representatiions
        % and thus which should be manipulated to replay the
        % game.
        gamePath       % path to the loaded styx path, derived from styxPath constructor
        % argument and the specific game UID specified in
        % the loaded styxlog.
        styxLog  % the read styxLog; a Nx5 cell array.
        timestamps % cell vector of the timestamps of each event in styxLog
        waitTime; % (N-1)x1 vector of the waitTime between the i-th styxLog event and
        % the subsequent event.
        elapsedTimeLookup %Nx1 vector of the total elapsed game time at the event whose 
                          % index corresponds to the index of the element in this vector. 
                          % Basically a cumsum of obj.waitTime
        
        % PLAYBACK-RELATED PROPERTIES
        PLAYSPEED = 1  % ratio between how fast the styxlog is replayed and how fast
        % things really happened. 1 means playback is in realtime.
        % Values greater than 1 means fast-forward, values less than
        % one means slow-motion. Don't change the default from 1 as the GUI
        % assumes this to start.
        continuePlayback = true; % the playback loop keeps running as long as this is
        % true. The GUI can make it false to pause the playback.
        justJumpedEvent = false; % flag used to interrupt the long segmented pause by
                                 % the GUI. 
        currentEvent_i = 1;      % which styxLog event (specified as an index)
		currentTime = 0;         % elapsed game time (in seconds)
        % is the current one being played.
		guiHandles % passed in by StyxPlaybackGUI; lets the StyxPlayback object update
		           % things like the current replay time in the main loop.
    end % properties (Access = public)
    properties (GetAccess = public, SetAccess = protected)
        blockInfo        % This structure is populated when the styxlog is read 
                         % and the game is loaded. It is used by
                         % StyxPlaybackGUI to provide information to the
                         % user about the block.
    end % properties (GetAccess = public, SetAccess = protected)
    properties (Access = protected)
        
    end % properties (Access = public)
    
    
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        % CONSTRUCTOR
        function obj = StyxPlayback( filename, styxPath )
            % *******************************************************************
            %               Setup -- Add paths and load styxLog
            % *******************************************************************
            
            % Add accessory functions in the same directory to path
            addpath( fileparts( which( mfilename ) ) );
            
            % Input cleanup
            if styxPath(end) == filesep
                styxPath = styxPath(1:end-1); % so I don't have to worry about whether or not to add a / at end
            end
            
            % Load the styxlog file specified by filename.
            fprintf('Loading file %s...', filename)
            obj.styxLog = StyxLog_Reader( filename );
            fprintf(' OK\n')
            
            % Find the game version
            gameVersionLine = SearchStyxLog( obj.styxLog, 2, 'LOGGER', 4, 'gameVersion' );
            gameVersion = gameVersionLine{5};
            gameUID = gameVersion(1:4); % string, e.g. 8004
            % Now bring to top of path the Styx CommonResources and also the specific game.
            % I assume that the Styx folder structure Styx -> {StyxGames,
            % StyxCommonResources} has remained unchanged.
            addpath( genpath( [styxPath filesep 'StyxCommonResources'] ) ); %add StyxCommonResources
            obj.gamePath = [styxPath filesep 'StyxGames' filesep 'G_' gameUID]; % first 4 chars of gameVersion are the 4-digit Game Unique ID
            addpath( genpath( obj.gamePath ) )
            
            % *******************************************************************
            %            Load the game to generate table of game objects
            % *******************************************************************
            % The trick that I use to make all of this possible is to create the
            % G_XXXX_Start state. Since Styx games create all of the game objects in
            % this state, this gives me access to every object. I'm only interested in
            % graphical objects, so I can go into the world_h, get its childObjects,
            % and create a lookup table of all of their descriptiveNames so that when I
            % go through the log I can use the logged descriptveNames to call
            % operations on the appropriate game objects.
            
            % Load the game Start state
            command = ['obj.startSt = G_' gameUID '_Start(''descriptiveName'',''NO_LOG'');']; % I give the game descriptiveName NO_LOG to trigger the special flag in StyxLogger to not actually create a log during replay run of the game
            eval( command );
            
            % Version check: make sure that the version of the game software loaded matches the
            % version of the game specified in the styxlog.
            loadedVersionStr = sprintf( '%i %i %i %i', obj.startSt.version(1), obj.startSt.version(2), ...
                obj.startSt.version(3), obj.startSt.version(4) );
            if ~strcmp( gameVersion, loadedVersionStr )
                warndlg(['Warning: styxlog specifies version ' gameVersion ' but game software loaded is version ' loadedVersionStr '. Replay fidelity not guaranteed.'], 'StyxPlayback Warning')
            end
            
            % Generate lookup table of the descriptiveNames of all the game objects
            % with graphical components and their handles. The first of these is the
            % world objects, the rest are the children of the world object.
            % NOTE: If more outlandish games are created with, say, multiple worlds (or
            % no worlds), then this method of generating the gameObjects might need to
            % be changed.
            obj.gameObjects = struct;
            obj.gameObjects.dNames{1}  = obj.startSt.world.descriptiveName; % first, the World object...
            obj.gameObjects.handles{1} = obj.startSt.world;
            % and then the other graphics-containing game objects that are registered
            % as existing in that World.
            for i = 1 : length( obj.startSt.world.childObjects )
                obj.gameObjects.dNames{end+1,1}  = obj.startSt.world.childObjects{i}.descriptiveName;
                obj.gameObjects.handles{end+1,1} = obj.startSt.world.childObjects{i};
            end %for i = 1 : length( startSt.world.childObjects )
            
            % Prepare the arrays of timestamps and waitTimes that will
            % determine the times between when various events are generated
            % during the playback loop.
            % First I convert all of the timestamps into Matlab-friendly datenums
            obj.timestamps = cell( length( obj.styxLog(:,1) ), 1); % clock format
            for i = 1 : length( obj.timestamps )
                obj.timestamps{i} =  str2num( obj.styxLog{i,1} );
            end
            % now calculate the waitTimes between each timestep. It's more efficient to
            % do it here than inside the main loop.
            obj.waitTime = zeros( length( obj.timestamps ),1); % last one is left zero, but the final wait is
            % not important anyway
            tic
            for i = 1 : length( obj.timestamps) - 1
                obj.waitTime(i) =  etime( obj.timestamps{i+1}, obj.timestamps{i} );
            end
            obj.elapsedTimeLookup = cumsum( obj.waitTime );

            % *******************************************************************
            %       Prepare basic information about block
            % *******************************************************************
            % These are used by the StyxPlaybackGUI
            obj.blockInfo.gameVersion = gameVersion;
            obj.blockInfo.totalDuration = etime(obj.timestamps{end},obj.timestamps{1});
            obj.blockInfo.startDatestr = datestr( obj.timestamps{1}, 21);
            
            
            % Start the playback loop
%             DoPlayback( obj )
            
        end  % constructor
        
        function delete( obj ) % Destructor
            % delete the game startSt. This in turn will delete all of the
            % other objects.
            delete( obj.startSt )
            % remove gamePath from MATLAB path so as to leave things the
            % way I found it.
            rmpath( genpath( obj.gamePath ) )
        end %function delete( obj )
        
        function DoPlayback( obj )
            % Here's the main loop. I pause at the end of it
            while obj.continuePlayback == true && obj.currentEvent_i <= length( obj.timestamps)
                % *******************************************************
                %                    Play the current event
                % *******************************************************
                obj.justJumpedEvent = false; % if it was set to true and I get here then I'm not in a long
                                     % pause so set it back to false.
                ReplayEvent( obj, obj.currentEvent_i, 1 ) % second argument is so sounds are played
                
                
                % ---------------------------------------------------------------------
                %                   End of event  -- wait for next event
                % ---------------------------------------------------------------------
                if obj.waitTime(obj.currentEvent_i) > 0.01 % don't do very short-time pauses.
					% I do one trick here which is that if the length of
					% time i'm supposed to pause exceeds one second, I will
					% divide it into <=1sec chunks and consecutively go
					% through them, while updating the currentTime in
					% between. What this does is allows an outside observer
					% (i.e. the GUI) to see that time is still "moving"
					% even if there is a long pause in the game.
					pauseTime = obj.waitTime(obj.currentEvent_i)/obj.PLAYSPEED;
					if pauseTime > 1
						miniPauseTime = repmat( pauseTime/ceil(pauseTime), ceil(pauseTime),1);
						for miniPause = miniPauseTime'
                            % keep checking if continuePlayback is true
                            % because during this long pause the user
                            % might've given some other command (e.g. moved
                            % slider to jump to a different part of the
                            % replay).
                            if obj.continuePlayback == true && obj.justJumpedEvent == false % doesn't work since I set this to true right after JumpToEvent
                                pause( miniPause )
                            else
                                obj.justJumpedEvent = false;
                                break
                            end
							% note: When I updated obj.currentTime I multiply pause time by PLAYSPEED
                            % so currentTime is always in "real" game time
                            % irrespective of the playback speed.
                            obj.currentTime = obj.currentTime + miniPause*obj.PLAYSPEED; 
						end
					else 
						pause( obj.waitTime(obj.currentEvent_i)/obj.PLAYSPEED );
						obj.currentTime = obj.elapsedTimeLookup( obj.currentEvent_i );
					end %if pauseTime > 1
                    
				else % no pause at all; just increment currentTime
					% increment time
                    obj.currentTime = obj.elapsedTimeLookup( obj.currentEvent_i );
				end %if obj.waitTime(obj.currentEvent_i) > 0.01 % don't do very short-time pauses.
				% ---------------------------------------------------------------------
				%                   End of event  -- increment stuff
				% ---------------------------------------------------------------------
                % Check to see if this was the last event. If so, do some
                % end of playback housekeeping
                if obj.currentEvent_i >= size( obj.timestamps, 1 )
          
                    % Do a final update of the GUI text and slider and
                    % enable the Play button while disabling the Pause
                    % button. 
                    set( obj.guiHandles.text_currentTime, 'String', sprintf('%2i:%02.0f', floor( obj.currentTime/60 ), mod( obj.currentTime, 60 ) ) )
                    set( obj.guiHandles.slider1, 'Value', min( obj.currentTime/obj.guiHandles.pb.blockDuration, get(obj.guiHandles.slider1,'Max')) ) % do the min so I cant overshoot
                    set( obj.guiHandles.pushbutton_Pause, 'Enable', 'off')
                    set( obj.guiHandles.pushbutton_Play, 'Enable', 'on')

                    stop( obj.guiHandles.pb.EverySecondTimer_h )
                    obj.continuePlayback = false;
                    
                    % beep twice to alert the user of finish.
                    beep
                    pause(0.100)
                    beep
                end
				% increment currentEvent_i
				obj.currentEvent_i = obj.currentEvent_i + 1;

            end %while obj.continuePlayback == true


        end %function DoPlayback( obj )
        
        function ReplayEvent( obj, event_i, playSounds_b )
            % When given the index of an event (corresponding to a row of
            % obj.styxLog ) this method goes ahead and replays this event.
            % Note that for some types of events (e.g. STATE and SYNC)
            % nothing happens.
            % INPUTS:
            %       event_i        index of the event (in obj.styxLog) that is to
            %                      be replayed.
            %       playsSounds_b  true/false of whether to play sounds. If
            %                      I call ReplayEvent from the JumpToEvent
            %                      method then I do not play sounds.
            thisEvent = obj.styxLog(event_i,:);
            
                % If it's a PROP_SET event, and the object is one of gameObjects, then
                % try to recreate this event.
                if strcmp( thisEvent{2}, 'PROP_SET' )
                    % get the name of the object. Log column 3 identifies the game object
                    % with format 'Class descriptiveName' so I find just the latter
                    thisObjDname = thisEvent{3}(find( thisEvent{3}==' ')+1:length(thisEvent{3}));
                    % See if this object is one of the visible gameObjects whose handles
                    % we now have.
                    thisHandle = dName2Handle( obj, thisObjDname );
                    % if a handle was found, this means we can reproduce the property
                    % change that this event logged. Let's do it...
                    if ~isempty( thisHandle )
                        % construct the property set command from the log. Unfortunately
                        % I don't know if the value cell thisEvent{5} contains a matrix
                        % or string, since styxLog records everthing as a string. To get
                        % around this, I try to convert it to a num. If it works I assume
                        % it's a matrix, otherwise treat it as a string.
                        trystr2num = str2num( thisEvent{5} );
                        if ~isempty( trystr2num ) % it's supposed to be a matrix (which could be scalar or vector)
                            propVal = trystr2num;
                        else % it's supposed to be a string
                            propVal = thisEvent{5};
                        end
                        command = ['thisHandle.' thisEvent{4} ' = ' mat2str(propVal) ';'];
                        eval( command )
                    end % if ~isempty( thisHandle )
                % If it's a SOUND event, and the object is one of gameObjects, then
                % try to recreate this sound event by calling the method of the
                % gameObject. Note that for this to work it is necessary that the game
                % creator stuck to the rule that the styxlog fourth column for this event
                % is the exact string as the name of the method that actually plays the
                % sound.
                elseif strcmp( thisEvent{2}, 'SOUND') && playSounds_b == true
                    % Almost same code as for PROP_SET events
                    thisObjDname = thisEvent{3}(find( thisEvent{3}==' ')+1:length(thisEvent{3}));
                    thisHandle = dName2Handle( obj, thisObjDname );
                    if ~isempty( thisHandle )
                        objMethod = thisEvent{4};
                        command = [ objMethod '( thisHandle );']; % play the actual method
                        eval(command);
                    end
                end %if .. elseif ..                  
        end %function ReplayEvent( obj, event_i )
        
        function JumpToEvent( obj, targetEvent_i )
        % Will immediately move the replay to a specified event. To do
        % this, I need to get the entire state of the game to what it was
        % at the specified time point. Instead of somehow elegantly finding
        % the state of every game object at this point, what I do is just
        % fast-forward through all of the events leading up to this until I
        % reach the desired event. Thus, if the desired event is in the
        % future of the current event, I move forward to this point, and if
        % it is in the past I start at the beginning of the styxlog and
        % move forward until the desired point. Note that doing it this way
        % is much slower than computing the exact game conditions at a
        % given point, but that'd be considerably more complicated (I'd
        % need to find every type of game object property, and then find all of their
        % most recent values.
        %    INPUTS:
        %            targetEvent_i   index of the event to which I want to
        %                            jump replay to.
        if targetEvent_i > obj.currentEvent_i
            for event_i = obj.currentEvent_i : targetEvent_i
                ReplayEvent( obj, event_i, 0 )
            end
            obj.currentEvent_i = targetEvent_i;
            obj.currentTime = obj.elapsedTimeLookup( obj.currentEvent_i );
            
        elseif targetEvent_i < obj.currentEvent_i
            for event_i = 1 : targetEvent_i
                ReplayEvent( obj, event_i, 0 )
            end
            obj.currentEvent_i = targetEvent_i;
            obj.currentTime = obj.elapsedTimeLookup( obj.currentEvent_i );
            
        end % if targetEvent_i > obj.currentEvent_i .. elseif targetEvent_i < obj.currentEvent_i
        
            
        end % function JumpToEvent( obj, event_i )
        
        function GenerateMovie( obj, startTime, endTime, fps, quality, movName, CompressionType )
        % Will create a movie of the game replay from startTime (in seconds)
         % to endTime (in seconds).
        % INPUTS:
        %        startTime     game time (in seconds) of movie clip start
        %        endTime       game time (in seconds) of movie clip end
        %        fps           frames per second of resulting movie
        %        quality       what compression level to use for the avi
        %        movName       what to name the resulting avi. Can include a
        %                      path.
		%       CompressionType which compression codec to use.
		
        fprintf('[StyxPlayback] Creating movie from t=%.0fs to t=%.0fs at %.0ffps using compression ''%s''...\n', startTime, endTime, fps, CompressionType)
		fprintf('               Progress:     ')

            % Note: I want to lock the user out of Matlab during the main
            % loop.
            % -------------------------------------------------------------
            %             Loop to generate each frame of the movie 
            % --------------------------------------------------------------
            % Get handle of Styx game figure. I take advantage of
            % behavior of the constructor where the world (
            styxFigh = obj.gameObjects.handles{1}.h; 
            aviobj = avifile(movName, 'fps', fps, 'compression', CompressionType, 'quality', quality);
            for t = startTime : 1/fps : endTime
                % I find what the nearest PAST event is.
                frameEvent_i = length( obj.elapsedTimeLookup(obj.elapsedTimeLookup <= t));
                % Then I use JumpToEvent method to create this state
                JumpToEvent( obj, frameEvent_i )
                set(styxFigh, 'Renderer', 'OpenGL') % seems to be needed or getframe captures 
                                               % just a black screen.

                % add current frame to the avi
                aviobj = addframe( aviobj,styxFigh );
                
                % Keep the user updated as to the progress               
                fprintf('\b\b\b\b%3.0f%%', 100*( (t-startTime)/(endTime-startTime)))
            end
            % Close the AVI
            aviobj = close(aviobj);
         
            
            fprintf('\n[StyxPlayback] Completed making movie ''%s''\n\n', movName)   
            
        end % function GenerateMovie( obj, startTime, endTime )
        
        % *******************************************************************
        %                          Helper Functions
        % *******************************************************************
        
        function handle = dName2Handle( obj, dName )
            % Short helper function for returning the handle corresponding to a
            % Game Object identified by its descriptiveName.
            % Given a string descriptiveName (read from a line in the styxlog for
            % example) and the gameObjects structure constructed in StyxPlayback, will
            % go through gameObjects and return the handle corresponding to that
            % descriptiveName. If there is more than one match then the game coder
            % messed up and gave the same descriptiveName to two objects; an error will
            % ensue.
            matches = cellfun( @strcmp, obj.gameObjects.dNames, ...
                repmat( {dName}, length( obj.gameObjects.dNames),1) );
            if nnz( matches ) > 1
                error(['[dName2Handle] Error: Multiple GameObjects match name ' dName '! Check that the game assigns unique names to objects.'])
            elseif nnz( matches ) == 0 % if no match found, return empty vector
                handle = [];
            else
                handle = obj.gameObjects.handles{matches};
            end
        end %function handle = dName2Handle( dName )
        
        
    end % methods (Access = public)
    
    % --------------------------------------------------
    %                Set/Get Methods
    % --------------------------------------------------
    methods
        
    end % set/get methods
    
    
    
    
    
end %classdef