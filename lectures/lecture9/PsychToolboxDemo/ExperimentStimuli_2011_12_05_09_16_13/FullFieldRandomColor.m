% FullFieldRandomColor.m
% 
% Presents a full field that changes between random colors every two
% frames. The value of the R,G,B component of the color are drawn from
% independent gaussian distributions with mean and contrast taken as
% arguments. 
%      The photodiode area matches color to the center field and
% flips at the same time as the center field.
% 
% Total Duration = <time>
%
% USAGE:
%       [] = FullFieldRandomColor( time, GaussianRGBmean, GaussianRGBcontrast, highDensity, (,screen_s))
%
% INPUTS:
%       time                  how long to run the stimulus for
%       GaussianRGBmean       3x1 vector containing the mean value for the
%                             [R;G;B] intensity distributions.
%       GaussianRGBcontrast   3x1 vector containing the contrast for the
%                             [R;G;B] intensity distributions.
%       seed                  random seed
%       highDensity           boolean; if true then switch to layout
%                             designed for use with the split high-density 
%                             array.
%       (,screen_s)           structure created externally (for batch stims)
%                             which contains the variables that
%                             StimConstants() normally creates. If this
%                             optional structure is provided then use the
%                             its window and constants.
% OUTPUTS: 
%       (none)
%
%
% Created by Sergey Stavisky on October 20, 2010
% Last modified by Sergey Stavisky on October 29, 2010
function [] = FullFieldRandomColor( time, GaussianRGBmean, GaussianRGBcontrast, seed, highDensity, screen_s )
AssertOpenGL
%--------------------------------------------------------------
%                     Argument Processing
%--------------------------------------------------------------
if nargin == 0
    error('[FullFieldRandomColor] You did not provide necessary arguments')
elseif nargin == 1
    GaussianRGBmean = [.5 .5 .5]';
    GaussianRGBcontrast  = [.1 .1 .1]';
    seed = 0;
    highDensity = false;
    fprintf('[FullFieldRandomColor] Warning! Using default values for GaussianRGBmean, GaussianRGBcontrast, seed, and highDensity.\n');
elseif nargin == 2
    GaussianRGBcontrast  = [.10 .10 .10]';
    seed = 0;
    highDensity = false;
    fprintf('[FullFieldRandomColor] Warning! Using default values for GaussianRGBcontrast, seed, and highDensity.\n');
elseif nargin == 3
    seed = 0;
    highDensity = false;
    fprintf('[FullFieldRandomColor] Warning! Using default value for seed and highDensity.\n');
elseif nargin == 4
    highDensity = false;
    fprintf('[FullFieldRandomColor] Warning! Using default value for highDensity.\n');
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
%--------------------------------------------------------------
%                 Prep before starting the stimulus
%--------------------------------------------------------------
% reset random stream with seed
rands = RandStream('mt19937ar', 'Seed', seed); % recreatable rand stream; call rands as first argument to all random functions

% get coordinates of my field box; the stimuli will appear here
screenCenter = floor(screenDim/2);
left = floor( screenCenter(2) - fieldSize(2)/2 + 1 ); % left of field
top = floor( screenCenter(1) - fieldSize(1)/2 - 1);
% left and top of my field
field = [left top (left+fieldSize(2)) (top+fieldSize(1))];

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
    % randomize R,G,B value
    % RGB values; each is contrast*mean*fullrange*randn + mean*fullrange where
    % fullrange = black-white
    RGB = GaussianRGBcontrast.*GaussianRGBmean.*repmat(white-black,3,1).*randn( rands,3,1 ) ...
        + GaussianRGBmean.*repmat(white-black,3,1);
    RGB = min(RGB, [white; white; white]); % cut off impossible color values. 
    RGB = max(RGB, [black; black; black]); 
    RGB = floor(RGB'); % ensure integer value and transpose since PTB wants row

    % draw this color into the field and the photodiode ovalclear Screen
    
    Screen('FillOval', mywindow, RGB, photodiode);
    Screen('FillRect', mywindow, RGB, field);
   
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