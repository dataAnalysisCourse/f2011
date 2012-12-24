% LinesRFmap.m
% 
% Presents a number of horizontal bars of <barSize> pixels spanning the
% field which change their grayscale intensity randomly according to a
% normal distribution whose std is mean_intensity*<contrast>. The
% intensities of the bars are changed every two frames.
%      The photodiode area matches color to the top bar and
% flips at the same time as the bars do.
%
% Total Duration = <time>;
%
% USAGE:
%       [] = LinesRFmap( time, contrast, barSize, seed, highDensity (,screen_s) )
%
% INPUTS:
%       time                  how long to run the stimulus for (in seconds)
%       contrast              the contrast used to determine the std of the
%                             gaussian from which intensities are drawn.
%       barSize               how many pixels tall each bar is. 
%       seed                  random seed
%       highDensity           boolean; if true then switch to layout
%                             designed for use with the split high-density 
%                             array.
%       (,screen_s)           structure created externally (for batch stims)
%                             which contains the variables that
%                             StimConstants() normally creates. If this
%                             optional structure is provided then use the
%                             its window and constants.
%
% OUTPUTS: 
%       (none)
%
%
% Created by Sergey Stavisky on October 22, 2010
% Last modified by Sergey Stavisky on October 29, 2010
function [] = LinesRFmap( time, contrast, barSize, seed, highDensity, screen_s )
AssertOpenGL
%--------------------------------------------------------------
%                     Argument Processing
%--------------------------------------------------------------
if nargin == 0
    error('[LinesRFmap] You did not provide necessary arguments')
elseif nargin == 1
    contrast = 0.35;
    barSize  = 16;
    seed = 0;
    highDensity = false;
    fprintf('[LinesRFmap] Warning! Using default values for contrast, barSize, seed, and highDensity.\n');
elseif nargin == 2
    barSize  = 16;
    seed = 0;
    highDensity = false;
    fprintf('[LinesRFmap] Warning! Using default values for barSize, seed, and highDensity.\n');
elseif nargin == 3
    seed = 0;
    highDensity = false;
    fprintf('[LinesRFmap] Warning! Using default value for seed and highDensity.\n');
elseif nargin == 4
    highDensity = false;
    fprintf('[LinesRFmap] Warning! Using default value highDensity.\n');
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
frameTime= 2*ifi; % time between each frame update in this stimulus
numFrames=2*ceil(time/frameTime/2); % ensures even number of frames.

switch highDensity
    case false
        fieldSize = [384 384]; % will use a box of this many pixels in height and width
    case true
        fieldSize = [480 384];
end
% Warn user if not all the field will be used by squares (In which case I 
% don't cut them off, instead opting to just not build the last square).
if mod(fieldSize(1), barSize) ~= 0
    fprintf('[LinesRFmap] Warning! fieldSize height %i is not a multiple of barSize %i\n', fieldSize(1), barSize)
end

%--------------------------------------------------------------
%                 Prep before starting the stimulus
%--------------------------------------------------------------
% reset random stream with seed
rands = RandStream('mt19937ar', 'Seed', seed); % recreatable rand stream; call rands as first argument to all random functions

% get coordinates of my field; the stimuli will appear here
screenCenter = floor(screenDim/2);
left = floor( screenCenter(2) - fieldSize(2)/2 + 1 ); % left of field
top = floor( screenCenter(1) - fieldSize(1)/2 - 1);
% left and top of my field
field = [left top (left+fieldSize(2)-1) (top+fieldSize(1)-1)];

% build the horizontal-bars object. 
linetops = field(2):barSize:field(4);
linebottoms = linetops+barSize;
linelefts = repmat( field(1), 1, length(linetops) );
linerights = repmat( field(3), 1, length(linetops) );
object = [linelefts; linetops; linerights; linebottoms];
 
% Set up the mean intensity background screen and black the photodiode
Screen('FillRect', mywindow, meanIntensity);
Screen('FillOval', mywindow, black, photodiode);
Screen('Flip',mywindow);
HideCursor 
Priority(MaxPriority(mywindow));
vbl = WaitSecs(0.100); % makes finding the start of the stimulus easy
%--------------------------------------------------------------
%                            Stimulus runs
%--------------------------------------------------------------
for frame_i = 1 : numFrames
    % generate the luminance intensities for each of the bars. Intensities
    % must be integers.
    intensities = floor( contrast*meanIntensity*randn( rands,1, size(object,2) ) + meanIntensity );
    % intensities must be integers and cannot exceed white or blac
    intensities(intensities>white) = white;
    intensities(intensities<black) = black;
    colors = repmat(intensities,3,1);

    % draw this color into the field and the photodiode ovalclear Screen
    Screen('FillRect', mywindow, colors, object);
    Screen('FillOval', mywindow, colors(:,1), photodiode); % photodiode is same color as top bar of object
    
    if KbCheck % Allow user to exit out by pressing any key
        ShowCursor
        Screen('CloseAll');
        return;
    end

    vbl=Screen('Flip', mywindow, vbl + frameTime-0.01);     
end %for frame_i = 1 : numFrames

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