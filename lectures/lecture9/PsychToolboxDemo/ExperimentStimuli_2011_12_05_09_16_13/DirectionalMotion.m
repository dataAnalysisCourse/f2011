% DirectionalMotion.m
%
% Presents a full field that changes between random colors every two
% frames. The value of the R,G,B component of the color are drawn from
% independent gaussian distributions with mean and variances taken as
% arguments.
%      The photodiode area flips light/dark on each frame. The contrast is
% used to encode direction.
%
% Total Time = length(<directions>)*<cycles>*<linewidth>*2*(1/speed)*ifi
%
% USAGE:
%       [] = DirectionalMotion( cycles, speed, directions, lineWidth, highDensity (,screen_s) )
%
% INPUTS:
%        cycles     how many complete cycles (i.e. object returns to its
%                   starting appearance) to do in each direction.
%        speed      how many pixels to move per frame
%        directions cell array such as {'up', 'down', 'left', 'right'}
%                   specifying the order in which the four cardinal
%                   directions will be tested.
%        lineWidth  how many pixels wide each moving bar is. Note that the
%                   object is always half duty cycle
%        highDensity   boolean; if true then switch to layout
%                      designed for use with the split high-density 
%                      array.
%        (,screen_s)   structure created externally (for batch stims)
%                      which contains the variables that
%                      StimConstants() normally creates. If this
%                      optional structure is provided then use the
%                      its window and constants.
% OUTPUTS:
%       (none)
%
%
% Created by Sergey Stavisky on October 21, 2010
% Last modified by Sergey Stavisky on October 29, 2010
function [] = DirectionalMotion( cycles, speed, directions, lineWidth, highDensity, screen_s )
AssertOpenGL
%--------------------------------------------------------------
%                     Argument Processing
%--------------------------------------------------------------
if nargin == 0
    error('[DirectionalMotion] You did not provide necessary arguments')
elseif nargin == 1
    speed = 2;
    directions  = {'up', 'right', 'down', 'left'};
    lineWidth = 16;
    highDensity = false;
    fprintf('[DirectionalMotion] Warning! Using default values for speed, directions, lineWidth, and highDensity.\n');
elseif nargin == 2
    directions  = {'up', 'right', 'down', 'left'};
    lineWidth = 16;
    highDensity = false;
    fprintf('[DirectionalMotion] Warning! Using default values for directions, lineWidth, and highDensity.\n');
elseif nargin == 3
    lineWidth = 16;
    highDensity = false;
    fprintf('[DirectionalMotion] Warning! Using default values for lineWidth and highDensity.\n');
elseif nargin == 4
    highDensity = false;
    fprintf('[DirectionalMotion] Warning! Using default values for highDensity.\n');
end

%--------------------------------------------------------------
%    Set up user constants and evaluate dependent constants
%--------------------------------------------------------------
if exist( 'screen_s', 'var' ) % screen is already created; get constants from this structure
    mywindow = screen_s.mywindow; 
    photodiode = screen_s.photodiode;
    screenDim = screen_s.screenDim;
    ifi = screen_s.ifi;
    black = screen_s.black;
    white = screen_s.white;
    meanIntensity = screen_s.meanIntensity;
else
    [mywindow photodiode screenDim ifi black white meanIntensity] = StimConstants();
end

frameTime= ifi; % time between each frame update in this stimulus
switch highDensity
    case false
        fieldSize = [384 384]; % will use a box of this many pixels in height and width
    case true
        fieldSize = [480 384];
end
numFrames = cycles*lineWidth*2/speed; %how many frames to do in each direction

%--------------------------------------------------------------
%                 Prep before starting the stimulus
%--------------------------------------------------------------
% get coordinates of my field box; the stimuli will appear here
screenCenter = floor(screenDim/2);
left = floor( screenCenter(2) - fieldSize(2)/2 + 1 ); % left of field
top = floor( screenCenter(1) - fieldSize(1)/2 - 1); % top of field
field = [left top (left+fieldSize(2)-1) (top+fieldSize(1)-1)];

% build the horizontal-lines object. Each subpart of the object will be
% a line. bunches of adjascent lines will have the same color to create
% appearance of moving bars. It turns out this method makes the movement
% logic easier since the number of lines never changes (wheras the number
% of bars grows/shrinks by one as a bar wraps across both edges of a field.
linetops = field(2):1:field(4);
linebottoms = linetops+1;
linelefts = repmat( field(1), 1, length(linetops) );
linerights = repmat( field(3), 1, length(linetops) );
object_horizontal = [linelefts; linetops; linerights; linebottoms];
% build the vertical-lines object
linelefts = field(1):1:field(3);
linerights = linelefts+1;
linetops = repmat( field(2), 1, length(linelefts) );
linebottoms = repmat( field(4), 1, length(linelefts) );
object_vertical = [linelefts; linetops; linerights; linebottoms];

% build the colors for each line to create impression of contiguous bars
color1 = [black black black]';
color2 = [white white white]';
% Build colors for object_vertical
colorsHorizontal = repmat( color1, 1, size(object_horizontal,2) ); % starts all as color1
for barStart = 1 : 2*lineWidth : size(object_horizontal,2)-1
    colorsHorizontal(:,barStart:barStart+lineWidth-1) = repmat(color2, 1, lineWidth); %fill lineWidth chunks with color2
end
% Build colors of object_vertical
colorsVertical = repmat( color1, 1, size(object_vertical,2) ); % starts all as color1
for barStart = 1 : 2*lineWidth : size(object_vertical,2)-1
    colorsVertical(:,barStart:barStart+lineWidth-1) = repmat(color2, 1, lineWidth); %fill lineWidth chunks with color2
end

% Set up the mean intensity background screen and black the photodiode
Screen('FillRect', mywindow, meanIntensity);
Screen('FillOval', mywindow, black, photodiode);
Screen('Flip',mywindow);
HideCursor
Priority(MaxPriority(mywindow));
vbl = WaitSecs(0.100); % to get an easy-to-see black to nonblack photodiode signal
%--------------------------------------------------------------
%                            Stimulus runs
%-------------------------------------------------------------
for dir_i = 1 : length( directions )
    % Based on the current direction of movement, load the appropriate
    % object and set the hi_diode and lo-diode values.
    myDirection = directions{dir_i};
    switch myDirection
        case 'up'
            myObject = object_horizontal;
            colors =  colorsHorizontal;
            hi_diode = repmat(.95 * white,3 , 1);
            lo_diode = repmat(.05* white, 3, 1);
        case 'down'
            myObject = object_horizontal;
            colors =  colorsHorizontal;
            hi_diode = repmat(.85 * white,3 , 1);
            lo_diode = repmat(.15* white, 3, 1);
        case 'left'
            myObject = object_vertical;
            colors =  colorsVertical;
            hi_diode = repmat(.75 * white,3 , 1);
            lo_diode = repmat(.25* white, 3, 1);
        case 'right'
            myObject = object_vertical;
            colors =  colorsVertical;
            hi_diode = repmat(.65 * white,3 , 1);
            lo_diode = repmat(.35* white, 3, 1);
        otherwise
            ShowCursor
            Screen('CloseAll');
            error('[DirectionalMotion] Unrecognized direction %s', myDirection)
    end %switch myDirection
    
    for frame_i = 1 : numFrames
        % implement the rules of moving the objects. Basically the relevant
        % dimension coordinates of each line are incremented by speed, and whenever(
        % they exceed a boundary of the field they are set back to the other side
        % (wrap-around).
        switch myDirection
            case 'down'
                colors = circshift(colors,[0 speed]);
            case 'up'
                colors = circshift(colors,[0 -speed]);
            case 'left'
                colors = circshift(colors,[0 -speed]);
            case 'right'
                colors = circshift(colors,[0 speed]);
        end %switch myDirection
        
        % each frame flips the photodiode between hi_diode and lo_diode
        if mod(frame_i,2) == 0
            Screen('FillOval', mywindow, hi_diode, photodiode);
        else
            Screen('FillOval', mywindow, lo_diode, photodiode);
        end %if... else... mod(frame_i,2) == 0
            
        Screen('FillRect', mywindow, colors, myObject) % draw the object
        
        if KbCheck % Allow user to exit out by pressing any key
            ShowCursor
            Screen('CloseAll');
            return;
        end
        
        vbl=Screen('Flip', mywindow, vbl + frameTime-0.01); %flip the screen
    end %for frame_i = 1 : Frames
end %for dir_i = 1 : length( directions )

% CLEAN UP
if ~exist( 'screen_s', 'var' ) % don't close the screen if it's being controlled
    % by a higher function.
    ShowCursor
    Screen('CloseAll');
else %just return screen to mean gray
    Screen('FillRect', mywindow, meanIntensity);
    Screen('Flip', mywindow );
end

end % function