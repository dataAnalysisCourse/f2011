% SquaresRFmap.m
% 
% Presents a number of equally sized squares of side length <sideLength> 
% pixels spanning the field which change their grayscale intensity randomly 
% between a high and low intensity specified by <contrast> every two monitor
% refreshes.
%      The photodiode area matches intensity to the top-left square and
% flips at the same time as the square intensities do.
%
% Total Duration = <time> 
%
% USAGE:
%       [] = SquaresRFmap( time, contrast, sideLength, seed, highDensity (,screen_s) )
%
% INPUTS:
%       time                  how long to run the stimulus for (in seconds)
%       contrast              Michelson contrast between the high and low
%                             intensity squares.
%       sideLength            how many pixels tall and wide each square is. 
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
% Created by Sergey Stavisky on October 25, 2010
% Last modified by Sergey Stavisky on October 29, 2010
function [] = SquaresRFmap( time, contrast, sideLength, seed, highDensity, screen_s )
AssertOpenGL
%--------------------------------------------------------------
%                     Argument Processing
%--------------------------------------------------------------
if nargin == 0
    error('[SquaresRFmap] You did not provide necessary arguments')
elseif nargin == 1
    contrast = 1;
    sideLength  = 16;
    seed = 0;
    highDensity = false;
    fprintf('[SquaresRFmap] Warning! Using default values for contrast, sideLength, seed, and highDensity.\n');
elseif nargin == 2
    sideLength  = 16;
    seed = 0;
    highDensity = false;
    fprintf('[SquaresRFmap] Warning! Using default values for sideLength, seed, and highDensity.\n');
elseif nargin == 3
    seed = 0;
    highDensity = false;
    fprintf('[SquaresRFmap] Warning! Using default value for seed and highDensity.\n');
elseif nargin == 4
    highDensity = false;
    fprintf('[SquaresRFmap] Warning! Using default value for highDensity.\n');
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
if mod(fieldSize(1), sideLength) ~= 0
    fprintf('[SquaresRFmap] Warning! fieldSize height %i is not a multiple of sideLength %i\n', fieldSize(1), sideLength)
end
if mod(fieldSize(2), sideLength) ~= 0
    fprintf('[SquaresRFmap] Warning! fieldSize width %i is not a multiple of sideLength %i\n', fieldSize(2), sideLength)
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

% build the squares object. I create the squares in raster-wise, column-major 
% order.
numSquaresVertical = length( field(2):sideLength:field(4) );
numSquaresHorizontal = length( field(1):sideLength:field(3) );
linetops = repmat(field(2):sideLength:field(4), 1, numSquaresHorizontal);
linebottoms = linetops + sideLength;
linelefts = reshape( repmat( field(1):sideLength:field(3), numSquaresVertical, 1), 1, []);
linerights = linelefts + sideLength;
object = [linelefts; linetops; linerights; linebottoms];

% compute the high and low intensity colors based on the specified contrast
hiRGB = repmat( 2*meanIntensity*contrast + (1-contrast)*meanIntensity, 3, 1);
loRGB = repmat( (1-contrast)*meanIntensity, 3, 1);
% RGB values should be integers
hiRGB = floor( hiRGB );
loRGB = floor( loRGB );
 
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
    % generate the luminance intensities for each of the squares. Intensities
    % are equally likely to be the high or low intensity value.
    randbinary = round( rand( rands, 1, numSquaresVertical*numSquaresHorizontal) );
    % colors must be integers 
    colors = floor( repmat((hiRGB-loRGB), 1, length(randbinary)).*repmat(randbinary,3,1) + repmat( loRGB, 1, length(randbinary) ) );
    
    % draw this color into the field and the photodiode ovalclear Screen
    Screen('FillRect', mywindow, colors, object);
    Screen('FillOval', mywindow, colors(:,1), photodiode); % photodiode is same color as top bar of object
    
    if KbCheck % Allow user to exit out by pressing any key
        ShowCursor
        Screen('CloseAll');
        return;
    end
    
    vbl=Screen('Flip', mywindow, vbl + frameTime-0.01);
end %for frame_i = 1 : Frames

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