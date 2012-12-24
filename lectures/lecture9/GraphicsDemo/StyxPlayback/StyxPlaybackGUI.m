function varargout = StyxPlaybackGUI(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StyxPlaybackGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @StyxPlaybackGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before StyxPlaybackGUI is made visible.
function StyxPlaybackGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to StyxPlaybackGUI (see VARARGIN)

% Choose default command line output for StyxPlaybackGUI
handles.output = hObject;


% -----------------------------------------------------------------------
% Establish a custom structure for sharing variables between various callbacks.
% handles.pb (pb stands for "playback") will be this superstructure. Note
% that whenever anything in it is changed, 'guidata(hObject, handles);'
% must be run to save this.
% -----------------------------------------------------------------------
handles.pb = struct;
handles.pb.SP = []; %will hold StyxPlayback class object.
% Initialize a default styxpath. It can be changed (to reflect the software
% run on a given session, for example) using the Load StyxSoftware GUI button.
% To make a defaultStyxPath I use assumption that that this m-file is in 
% Styx\StyxPlayback. So, I find my current path and go back by two
% fileseps.
iam = which( mfilename );
fileseps = find(iam == filesep);
defaultStyxPath = iam(1: fileseps(end-1) );
handles.pb.styxPath = defaultStyxPath;
% now update the styxPath display to reflect this
set(handles.text_styxSoftware, 'String', handles.pb.styxPath )

% -----------------------------------------------------------------------
%            Set position so as to hide the ReplayMovie pane
% -----------------------------------------------------------------------
% I record the total width/height before closing so I can open it to this
% size later in OpenMoviePane function
pos = get(handles.StyxPlaybackGUI, 'Position');
handles.pb.totalGUIwidth = pos(3);
handles.pb.totalGUIheight = pos(4);
handles.pb.mainPaneWidth = 111;
handles.pb.mainPaneHeight = 16;
CloseMoviePane( handles )


% -----------------------------------------------------------------------
% Create the EverySecondTimer timer object. When playback is going then
% this timer will be started, and each second it will execute the callback
% which is used to update the current time text and progress slider.
% -----------------------------------------------------------------------
handles.pb.EverySecondTimer_h = timer(...
	'TimerFcn',  {@EverySecondTimer, handles},  ...
	'ExecutionMode', 'fixedRate',  ...
	'Name', 'EverySecondTimer', ...
	'StartDelay', 1, ...
	'Period', 1);

% -----------------------------------------------------------------------
%               Plot the BrainGate2 logo 
% -----------------------------------------------------------------------
logo = imread('BrainGate2 Logo.png'); % note its size is 187x724 so the axes should
                                      % have this ratio
% I want to replace the white space in the image with the same light gray
% as the GUI background.
backgroundC = get( handles.StyxPlaybackGUI, 'Color');
whiteThresh = 200; % any pixel with all values above this will be replaced.
whiteSpace = (logo(:,:,1) >= whiteThresh).*(logo(:,:,2) >= whiteThresh).*(logo(:,:,3) >= whiteThresh);
whiteSpace3d = cat(3, whiteSpace,whiteSpace,whiteSpace);
logo(find(whiteSpace3d)) = backgroundC(1)*255; % assume the gray is even RGB
image( logo, 'Parent', handles.axes_logo)
set( handles.axes_logo, 'Visible', 'off')

% -----------------------------------------------------------------------
% Update handles structure
% -----------------------------------------------------------------------
guidata(hObject, handles);

% UIWAIT makes StyxPlaybackGUI wait for user response (see UIRESUME)
% uiwait(handles.StyxPlaybackGUI);


% --- Outputs from this function are returned to the command line.
function varargout = StyxPlaybackGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function LoadStyxLog_Callback(hObject, eventdata, handles)
% Used to select the StyxLog that is to be opened and the Styx software
% path that will be used to replay the styxlog.

% hObject    handle to LoadStyxLog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[logFilename, logPathname] = uigetfile( '*.styxlog', 'Select the styx log');
if logFilename ~= 0
    % create a StyxPlayback object using the styxlog filename and styxPath
    % set using this GUI. I save the handle of this StyxPlayback
    % object to handles.pb.SP; this object does the actual work of
    % playback, and the GUI will send it commands.    
     handles.pb.SP = StyxPlayback( [logPathname logFilename], handles.pb.styxPath );
	 % provide StyxPlayback object with the GUI handles so it can update
	 % the current time (for example).
     handles.pb.block = logFilename;
     handles.pb.blockDuration = handles.pb.SP.blockInfo.totalDuration;
     handles.pb.gameVersion = handles.pb.SP.blockInfo.gameVersion;
     handles.pb.startDatestr = handles.pb.SP.blockInfo.startDatestr;
     handles.pb.SP.guiHandles = handles;
     % update the Block Information panel in the GUI.
     set( handles.text_block, 'String', handles.pb.block )    
     % convert blockDuration to min:sec. Floor to nearest second
     mins = floor( handles.pb.blockDuration/60 );
     secs = mod( handles.pb.blockDuration, 60 );
	
     set( handles.text_blockDuration, 'String',  sprintf('%2i:%02.0f', mins, secs ) )
     set( handles.text_gameVersion, 'String', handles.pb.gameVersion )
     set( handles.text_startDatestr, 'String', handles.pb.startDatestr )
     % Set the total time above slider
     set( handles.text_totTime, 'String', sprintf('/%2i:%02.0f', mins, secs ));
	 % update the handles that is provided to EverySecondTimer since it
	 % uses anonymous function creation which freezes handles at time of
	 % creation; I want EverySecondTimer to have access to latests
	 % handles.pb.SP
	 set(handles.pb.EverySecondTimer_h, 'TimerFcn',  {@EverySecondTimer, handles} );
     
     % Enable "Play" button and Slider
     set( handles.pushbutton_Play, 'Enable', 'on')
     set( handles.slider1, 'Enable', 'on')
     
     % Enable ReplayMovie toolbar
     set( handles.ReplayMovie, 'Enable', 'on' )
end %if logFilename ~= 0

guidata(hObject, handles) %commits handles


% --------------------------------------------------------------------
function LoadStyx_Callback(hObject, eventdata, handles)
% Used to select the Styx software that is to be opened and the Styx software
% path that will be used to replay the styxlog.
%
% hObject    handle to LoadStyx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
styxPath = uigetdir( 'C:\BrainGate\BrainGateMatlab\BG2Development\My Dropbox\Styx', 'Select top-level Styx software directory:');
if styxPath ~= 0
    handles.pb.styxPath = styxPath;
    guidata(hObject, handles)
    % now update the styxPath display to reflect this
    set(handles.text_styxSoftware, 'String', handles.pb.styxPath )    
end
    
function EverySecondTimer( timerObj, event, handles )
% A timer that executes each second and updates the GUI to show the current
% simulation time. handles it using the same handles used throughout the GUI.
% fprintf(' timer running at current time = %f \n', handles.pb.SP.currentTime  ) % DEV DEBUG
if ~isempty( handles.pb.SP )
    % Update currentTime text based on current time
	set( handles.text_currentTime, 'String', sprintf('%2i:%02.0f', floor( handles.pb.SP.currentTime/60 ), mod( handles.pb.SP.currentTime, 60 ) ) )

    % Update slider position based on current time
    set( handles.slider1, 'Value', min( handles.pb.SP.currentTime/handles.pb.blockDuration, get(handles.slider1,'Max')) ) % do the min so I cant overshoot
end



% --- Executes on slider movement. Used to jump playback to a different
% time.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% Compute what fraction of the total time the slider is at, and then
% convert that to an event_i
playbackFrac = (get(hObject,'Value')-get(hObject,'Min')) / (get(hObject,'Max')-get(hObject,'Min'));
desiredTime = playbackFrac * handles.pb.blockDuration;
% now find nearest event to this time
[discard desiredEvent_i] = min( abs( handles.pb.SP.elapsedTimeLookup - desiredTime ) );

% For smoother UI, immediately "lock" the slider on the position
% corresponding to this event
set( handles.slider1, 'Value', min( handles.pb.SP.elapsedTimeLookup(desiredEvent_i)/handles.pb.blockDuration, get(handles.slider1,'Max')) ) % do the min so I cant overshoot


% Now call the StyxPlayback method to jump to this event. I start and then
% restart the EverySecondTimer so it doesn't try to go off while this is
% happening.
stop( handles.pb.EverySecondTimer_h )
handles.pb.SP.justJumpedEvent = true; % I set this to true so that the long pause in StyxPlayback
                                      % DoPlayback method interrupts.
JumpToEvent( handles.pb.SP, desiredEvent_i )
start( handles.pb.EverySecondTimer_h )
% and update the currentTime text
set( handles.text_currentTime, 'String', sprintf('%2i:%02.0f', floor( handles.pb.SP.currentTime/60 ), mod( handles.pb.SP.currentTime, 60 ) ) )


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton_Play.
function pushbutton_Play_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Play (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


set( handles.pushbutton_Pause, 'Enable', 'on')
set( handles.pushbutton_Play, 'Enable', 'off')
handles.pb.SP.continuePlayback = true;
% start the every second timer which will update GUI to current simulation
% time, if it isn't already started

% nice GUI behavior - if it's at end of playback, start from beginning
if handles.pb.SP.currentEvent_i >= length( handles.pb.SP.timestamps )
    JumpToEvent( handles.pb.SP, 1 );
    set( handles.text_currentTime, 'String', '0:00' );
    set( handles.slider1, 'Value', get(handles.slider1,'Min') );% do the min so I cant overshoot
end

if strcmp( get(handles.pb.EverySecondTimer_h, 'Running'), 'off')
    start( handles.pb.EverySecondTimer_h )
end

DoPlayback( handles.pb.SP )


% --- Executes on button press in pushbutton_Pause.
function pushbutton_Pause_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Pause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set( handles.pushbutton_Play, 'Enable', 'on')
set( handles.pushbutton_Pause, 'Enable', 'off')
%stop the every second timer
stop( handles.pb.EverySecondTimer_h )

handles.pb.SP.continuePlayback = false;


function edit_PLAYSPEED_Callback(hObject, eventdata, handles)
% hObject    handle to edit_PLAYSPEED (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_PLAYSPEED as text
%        str2double(get(hObject,'String')) returns contents of
%        edit_PLAYSPEED as a double
handles.pb.playspeed = str2double( get(handles.edit_PLAYSPEED, 'String') );
% make sure its not negative. If it is, force it to be positive. 
if handles.pb.playspeed < 0
    handles.pb.playspeed = - handles.pb.playspeed;
elseif handles.pb.playspeed == 0 % if user enters zero, force it to be 1
    handles.pb.playspeed = 1;
end
set( handles.edit_PLAYSPEED, 'String', handles.pb.playspeed );
if isobject( handles.pb.SP ) % in case user edits it before game loaded
    handles.pb.SP.PLAYSPEED = handles.pb.playspeed;
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_PLAYSPEED_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_PLAYSPEED (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close StyxPlaybackGUI.
function StyxPlaybackGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to StyxPlaybackGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);



% --- Executes during object deletion, before destroying properties.
function StyxPlaybackGUI_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to StyxPlaybackGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% delete the StyxPlayer object

% delete timer
stop( handles.pb.EverySecondTimer_h );
delete( handles.pb.EverySecondTimer_h );

if ~isempty( handles.pb.SP )
    % first pause the game. Prevents anything in StyxPlayback from trying to
    % access a handle while it's being deleted.
    handles.pb.SP.continuePlayback = false;
	% Don't need to delete StyxPlayback object because when StyxPlaybackGUI
	% is deleted, all its handles are deleted, which includes
	% handles.pb.SP.
end
% Hint: delete(hObject) closes the figure
delete(hObject);






function edit_FPS_Callback(hObject, eventdata, handles)
% hObject    handle to edit_FPS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Do error-checking to make sure that the FPS entered is valid
    fps = str2double( get(hObject,'String') );
    if isempty( fps ) || fps <= 0 || isnan( fps )
        fps = 30;
    end
    set( hObject, 'String', mat2str( fps ) )
    
    


% --------------------------------------------------------------------
function ReplayMovie_Callback(hObject, eventdata, handles)
% hObject    handle to ReplayMovie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA

% Initialize the string of edit_endMovTime to the total block duration.
% convert blockDuration to min:sec.
mins = floor( handles.pb.blockDuration/60 );
secs = mod( handles.pb.blockDuration, 60 );
set( handles.edit_movEndTime, 'String',  sprintf('%2i:%02.0f', mins, secs ) )

% Initialize string of edit_movSavDir with the current working directory
set( handles.edit_movSavDir, 'String', pwd )

% Expand the GUI to show the ReplayMovie pane
OpenMoviePane( handles )


function pushbutton_hideMoviePane_Callback(hObject, eventdata, handles)
% Closes the ReplayMovie pane

% hObject    handle to pushbutton_hideMoviePane (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
CloseMoviePane( handles )


% --- Executes on button press in pushbutton_CreateMovie.
function pushbutton_CreateMovie_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_CreateMovie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Collect all of the parameters



% Process startTime and endTime. Note that I support the 'mm:ss' format or
% the 'ss' format so I convert to seconds using the  CheckForValidTime fcn.
startTraw = get( handles.edit_movStartTime, 'String' );
startTime = CheckForValidTime( handles, startTraw );
endTraw = get( handles.edit_movEndTime, 'String' );
endTime   = CheckForValidTime( handles, endTraw);
if endTime < startTime
	beep
	fprintf('[StyxPlaybackGUI] Replay movie end time must be greater than movie start time.\n')
	return
end

% name the movie based on the block name and time used. 
bname = handles.pb.block;
% I remove the '.styxlog' from the block name. 
if strfind(bname, '.styxlog')
	bname = bname( 1: strfind(bname, '.styxlog')-1);
end
movName = ['Replay of ' bname sprintf(' [%.0fs-%.0fs]', startTime, endTime)];
% replace '.' with '_' so it's a valid filename
movName(movName == '.') = '_';
% Now add the desired movie path into the name so it is written there.
movName = [ get( handles.edit_movSavDir, 'String' ) filesep movName];


% Get frames per second parameter
fps = str2num( get( handles.edit_FPS, 'String' ) );
quality = 100; % I've hardcoded it to 100 since for some reason it doesn't affect file size.
             % so I might as well go for broke. 
			 
% Get compression type parameter
listboxVal = get( handles.popupmenu_compression, 'Value');
string_list = get( handles.popupmenu_compression, 'String');
compression = string_list{ listboxVal };
			 
			 
			 
% Now actually call the GenerateMovie method of StyxPlayback using these
% parameters
GenerateMovie( handles.pb.SP, startTime, endTime, fps, quality, movName, compression )

function edit_movStartTime_Callback(hObject, eventdata, handles)
% hObject    handle to edit_movStartTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% use CheckForValidTime helper function to ensure the time entered is legit
newT = get( hObject, 'String' );
checkedT = CheckForValidTime( handles, newT );
mins = floor( checkedT/60 );
secs = mod( checkedT, 60 );
set( hObject, 'String',  sprintf('%2i:%02.0f', mins, secs ) )

function edit_movEndTime_Callback(hObject, eventdata, handles)
% hObject    handle to edit_movEndTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% use CheckForValidTime helper function to ensure the time entered is legit
newT = get( hObject, 'String' );
checkedT = CheckForValidTime( handles, newT );
mins = floor( checkedT/60 );
secs = mod( checkedT, 60 );
set( hObject, 'String',  sprintf('%2i:%02.0f', mins, secs ) )



% *************************************************************************
% *************************************************************************
%                   HELPER FUNCTIONS (not GUI functions)
% *************************************************************************
% *************************************************************************
function CloseMoviePane( handles)
% Helper function which closes the movie pane by restoring the GUI
% height/width to the size of just the main portion.
pos = get(handles.StyxPlaybackGUI, 'Position');
pos(3:4) = [handles.pb.mainPaneWidth handles.pb.mainPaneHeight];
set( handles.StyxPlaybackGUI, 'Position', pos)

%
function OpenMoviePane( handles )
% Helper function which opens the movie pane by enlarging the height of the
% window to the total height of the GUI (which includes the movie pane).

pos = get(handles.StyxPlaybackGUI, 'Position');
pos(3:4) = [handles.pb.totalGUIwidth handles.pb.totalGUIheight];
set( handles.StyxPlaybackGUI, 'Position', pos)

function t = CheckForValidTime( handles, timeString )
% given an argument in either 'mm:ss' or 'ss' string format returns this
% time in seconds or 0 if it is an invalid time. Error condition includes
% being before the start of the block or after the end of the block (in 
% the latter case it returns this max time).
% INPUTS:
%          handles       GUI handles structure
%          timeString    string containing the time (mm:ss or ss format)
% OUTPUTS:
%          t             time in seconds, or 0 if the time was invalid


if any( timeString == ':' )
    colon = find( timeString == ':' );
    mins = str2num( timeString(1:colon-1) );
    secs = str2num( timeString(colon+1:end) );
    t = mins*60 + secs;
else
    t = str2num( timeString );
end

% bad string case
if isempty( t ) || isnan( t )
    t = 0;
end

% check if t is less than block start time
minT = 0;
t = max( t, minT );

% check if t is greater than block duration
maxT = handles.pb.blockDuration;
t = min( t, maxT );

% --- Executes on button press in pushbutton_changeMovSaveDir.
function pushbutton_changeMovSaveDir_Callback(hObject, eventdata, handles)
% This '...' button next to the text box for Save directory calls uigetdir
% to set the text of edit_movSavDir.

existingDirStr = get( handles.edit_movSavDir, 'String' );
newDir = uigetdir( existingDirStr, 'Select directory for Styx replay movie:');
if isstr( newDir ) % ensures a valid directory was selected.
	set( handles.edit_movSavDir, 'String', newDir )
end

function edit_movSavDir_Callback(hObject, eventdata, handles)
% Check that the directory entered is valid directory. If it isn't just
% revert to the current working directory.
if ~isdir( get( hObject, 'String' ) )
	set( hObject, 'String', pwd )
end

% *************************************************************************
% *************************************************************************
%                 NON-USEFUL BUT NECESSSARY GUI CALLBACKS
% *************************************************************************
% *************************************************************************
% --- Executes on button press in pushbutton_hideMoviePane.






% --- Executes during object creation, after setting all properties.
function edit_movStartTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_movStartTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end






% --- Executes during object creation, after setting all properties.
function edit_movEndTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_movEndTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_totTime_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to text_totTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% for some strange reason the gui needs this object to have a 
% defined DeleteFcn. If this function doesn't exist (even though it is
% empty) then an error is thrown.


% --- Executes during object creation, after setting all properties.
function axes_logo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes_logo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes_logo




% --- Executes during object creation, after setting all properties.
function edit_FPS_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_FPS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end







% --- Executes during object creation, after setting all properties.
function edit_movSavDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_movSavDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_compression.
function popupmenu_compression_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_compression (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu_compression contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_compression


% --- Executes during object creation, after setting all properties.
function popupmenu_compression_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_compression (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
