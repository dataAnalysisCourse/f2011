% SensitizationLines.m
% 
% Similar to LinesRFmap but uses a block design which cycles between 
% conditions with two different contrast distributions. The time spend in
% the two conditions during one of the <numBlocks> blocks is set by vector
% c1TimeC2Time. 
%    Within a condition, this stimulus presents a number of horizontal bars
% of <barSize> pixels spanning the field which change their grayscale
% intensity  randomly according to a normal distribution whose std is
% mean_intensity*<contrastN> where N  specifies whether this is the first
% or second condition. The intensities of the bars are changed every two 
% frames.
%      The photodiode area matches color to the top bar and
% flips at the same time as the bars do.
% 
% Total Duration = (<c1TimeC2Time>(1) + <c1TimeC2Time>(2)) * <numBlocks>
%
% USAGE:
%       [] = SensitizationLines( c1TimeC2Time, numBlocks, contrast1, contrast2, barSize, seed, highDensity (,screen_s) )
%
% INPUTS:
%       c1TimeC2Time          (1x2) how many seconds to run the stimulus
%                             during contrast 1 and contrast 2, respectively
%       numBlocks             how many blocks to run. One block includes
%                             both contrast conditions.
%       contrast1             the contrast used to determine the std of the
%                             gaussian from which condition 1intensities are
%                             drawn.
%       contrast2             contrast for second condition
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
% OUTPUTS: 
%       (none)%
%
% Created by Sergey Stavisky on October 25, 2010
% Last modified by Sergey Stavisky on November 3, 2010
function [] = SensitizationLines( c1TimeC2Time, numBlocks, contrast1, contrast2, barSize, seed, highDensity, screen_s )
AssertOpenGL
%--------------------------------------------------------------
%                     Argument Processing
%--------------------------------------------------------------
if nargin == 0
    error('[SensitizationLines] You did not provide necessary arguments')
elseif nargin == 1
    numBlocks = 1;
    contrast1 = 0.35;
    contrast2 = 0.10;
    barSize  = 16;
    seed = 0;
    highDensity = false;
    fprintf('[SensitizationLines] Warning! Using default values for numBlocks, contrast1, contrast2, barSize, seed and highDensity.\n');
elseif nargin == 2 
    contrast1 = 0.35;
    contrast2 = 0.10;
    barSize  = 16;
    seed = 0;
    highDensity = false;
    fprintf('[SensitizationLines] Warning! Using default values for contrast1, contrast2, barSize, seed, and highDensity.\n');
elseif nargin == 3 
    contrast2 = 0.10;
    barSize  = 16;
    seed = 0;
    highDensity = false;
    fprintf('[SensitizationLines] Warning! Using default values for contrast2, barSize, seed and highDensity.\n');
elseif nargin == 4 
    barSize  = 16;
    seed = 0;
    highDensity = false;
    fprintf('[SensitizationLines] Warning! Using default values for barSize, seed and highDensity.\n');
elseif nargin == 5
    seed = 0;
    highDensity = false;
    fprintf('[SensitizationLines] Warning! Using default value for seed and highDensity.\n');
elseif nargin == 6
    highDensity = false;
    fprintf('[SensitizationLines] Warning! Using default value for highDensity.\n');
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

switch highDensity
    case false
        fieldSize = [384 384]; % will use a box of this many pixels in height and width
    case true
        fieldSize = [480 384];
end

% Warn user if barsize exceeds field or isn't an even multiple
if barSize > fieldSize(1)
    barSize = fieldSize(1);
    fprintf('[SensitizationLines] Warning: barSize %i is larger than vertical field size %i and will be clipped.\n', barSize, fieldSize(1) );
elseif mod( fieldSize(1), barSize ) ~= 0
    fprintf('[SensitizationLines] Warning: barSize %i is not a factor of vertical field size %i. Uneven bars will result.\n', barSize, fieldSize(1) );
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
% clear mex % DEV
% keyboard % DEV

linetops = field(2):barSize:field(4);
linebottoms = linetops+barSize;
 % ensure that linebottoms don't go outside the field
linebottoms(linebottoms > field(4)) = field(4);
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
for block_i = 1 : numBlocks
    for condition = 1 : 2 % corresponds to the two different contrast conditions
        switch condition
            case 1
                contrast = contrast1;
            case 2
                contrast = contrast2;
        end
        % numFrames is a function of specified time this condition.
        numFrames=2*ceil(c1TimeC2Time(condition)/frameTime/2); % ensures even number of frames.
        for frame_i = 1 : numFrames
            % generate the luminance intensities for each of the bars. Intensities
            % must be integers.
            intensities = floor( contrast*meanIntensity*randn( rands,1, size(object,2) ) + meanIntensity );
            % intensities must be integers and cannot exceed white or blac
            intensities(intensities>white) = white;
            intensities(intensities<black) = black;
            colors = repmat(intensities,3,1);
            
            % draw this color into the field and the photodiode oval
            Screen('FillRect', mywindow, colors, object);
            Screen('FillOval', mywindow, colors(:,1), photodiode); % photodiode is same color as top bar of object
            if KbCheck % Allow user to exit out by pressing any key
                ShowCursor
                Screen('CloseAll');
                return;
            end
            vbl=Screen('Flip', mywindow, vbl + frameTime-0.01);
            
        end %for frame_i = 1 : Frames
    end %for condition = 1 : 2
end %for block_i = 1 : numBlocks

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