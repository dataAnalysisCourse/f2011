% ObjectMotion.m
%
% Divides the field into a object and underlying surround region consisting
% of horizontal bars.The stimulus is presented in one of two conditions:
% coherent and anti-phase.
%     In the coherent motion, the object and surround periodically move up
% or down at the same time, such that you cannot perceive a discrete
% object.
%     In the anti-phase mode, the object and surround move out of phase to
% one another (so first object moves, then surround moves. Thus during
% movement the object is distinct from the surround.
%      ObjectMotion differs from many other stimuli in the way it reacts 
% when the high-density array argument is true. Since there is a distinct
% object and surround region and the object needs to be over the neurons of
% interest, to deal with the split array I center the square object/field
% first on the top subarray and then on the bottom subarray. This doubles
% the length of the stimulus but presents the same object/surround stimulus
% to both populations. The offsets are manually set in this m-function.
%      The photodiode area flips light/dark on each frame. The contrast is
% used to encode coherent versus anti-phase movement.
%
% Total Duration = <blocks>*<cycles>*(1/<rate>)*4  (Double if using <highDensity> is true)
%
% USAGE:
%       [] = ObjectMotion( cycles, blocks, speed, rate, lineWidth, highDensity (,screen_s) )
%
% INPUTS:
%        cycles     how many complete cycles (i.e. object returns to its
%                   starting appearance) to do in each condition.
%        blocks     how many blocks per condition
%        speed      how many pixels to move per frame when there is
%                   movement.
%        rate       how often (in Hz) the object/surround moves. Note that
%                   a full cycle takes 2*(1/rate) seconds because both move
%                   once down and then once back up.
%        lineWidth  how many pixels wide each bar is.
%        highDensity     boolean; if true then switch to mode designed
%                        for use with the split high-density array.                   
%        (,screen_s)     structure created externally (for batch stims)
%                        which contains the variables that
%                        StimConstants() normally creates. If this
%                        optional structure is provided then use the
%                        its window and constants.
% OUTPUTS:
%       (none)
%
%
% Created by Sergey Stavisky on October 21, 2010
% Last modified by Sergey Stavisky on November 1, 2010
function [] = ObjectMotion( cycles, blocks, speed, rate, lineWidth, highDensity, screen_s )
AssertOpenGL
% *************************************************************
%                     Argument Processing
% *************************************************************
if nargin == 0
    error('[ObjectMotion] You did not provide necessary arguments')
elseif nargin == 1
    blocks = 2;
    speed = 1;
    rate = 1;
    lineWidth = 8;
    highDensity = false;
    fprintf('[ObjectMotion] Warning! Using default values for blocks, speed, rate, lineWidth, and highDensity.\n');
elseif nargin == 2
    speed = 1;
    rate = 1;
    lineWidth = 8;
    highDensity = false;
    fprintf('[ObjectMotion] Warning! Using default values for speed, rate, lineWidth.\n');
elseif nargin == 3
    rate = 1;
    lineWidth = 8;
    highDensity = false;
    fprintf('[ObjectMotion] Warning! Using default values for rate, lineWidth, and highDensity.\n');
elseif nargin == 4
    lineWidth = 8;
    highDensity = false;
    fprintf('[ObjectMotion] Warning! Using default values for lineWidth and highDensity.\n');
elseif nargin == 5
    highDensity = false;
    fprintf('[ObjectMotion] Warning! Using default values for highDensity.\n');
end

% *************************************************************
%    Set up user constants and evaluate dependent constants
% *************************************************************
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
surroundSize = [672 672]; % will use a box of this many pixels in height and width
objectSize   = [128 128]; % will use a box of this many pixels in height and width
moveFrames = 4; % how many consecutive frames to move during when there is movement.
% *************************************************************
%                 Prep before starting the stimulus
% *************************************************************
% -------------------------------------------------------------
%                   Photodiode reporting table
% -------------------------------------------------------------
% row specifies whether the direction of movement is +1 or -1
% column specifies whether the condition is 1 (coherent) or 2 (anti-phase)
hiDiode = [.9 .8;
           .7 .6];
loDiode = [.4 .3;
           .2 .1];
diodeColor = [black;black;black]; % preallocated; will be changed accordingly
       
% -------------------------------------------------------------
%                     Build the object
% -------------------------------------------------------------
% get coordinates of my object
screenCenter = floor(screenDim/2);
objectLeft = floor( screenCenter(2) - objectSize(2)/2 + 1 );
objectTop = floor( screenCenter(1) - objectSize(1)/2 - 1);
objectEdges = [objectLeft objectTop (objectLeft+objectSize(2)-1) (objectTop+objectSize(1)-1)];
% build the horizontal-lines object. Each subpart of the object will be
% a line. Bunches of adjascent lines will have the same color to create
% appearance thicker bars. It turns out this method makes the movement
% logic easier since the number of lines never changes (wheras the number
% of bars grows/shrinks by one as a bar wraps across both edges of a field.
linetops = objectEdges(2):1:objectEdges(4);
linebottoms = linetops+1;
linelefts = repmat( objectEdges(1), 1, length(linetops) );
linerights = repmat( objectEdges(3), 1, length(linetops) );
object = [linelefts; linetops; linerights; linebottoms];
% build the colors for each line to create impression of contiguous bars
color1 = [black black black]'; 
color2 = [white white white]'; 
objectColors = repmat( color1, 1, length(linebottoms) ); % starts all as color1
for barStart = 1 : 2*lineWidth : length(linetops)-1
    objectColors(:,barStart:barStart+lineWidth-1) = repmat(color2, 1, lineWidth); %fill lineWidth chunks with color2
end

% -------------------------------------------------------------
%                     Build the surround
% -------------------------------------------------------------
% get coordinates of my surround
surroundLeft = floor( screenCenter(2) - surroundSize(2)/2 + 1 );
surroundTop = floor( screenCenter(1) - surroundSize(1)/2 - 1);
surroundEdges = [surroundLeft surroundTop (surroundLeft+surroundSize(2)-1) (surroundTop+surroundSize(1))-1];
linetops = surroundEdges(2):1:surroundEdges(4);
linebottoms = linetops+1;
linelefts = repmat( surroundEdges(1), 1, length(linetops) );
linerights = repmat( surroundEdges(3), 1, length(linetops) );
surround = [linelefts; linetops; linerights; linebottoms];
% build the colors for each line to create impression of contiguous bars
color1 = [black black black]';
color2 = [white white white]';
surroundColors = repmat( color1, 1, length(linebottoms) ); % starts all as color1
for barStart = 1 : 2*lineWidth : length(linetops)-1
    surroundColors(:,barStart:barStart+lineWidth-1) = repmat(color2, 1, lineWidth); %fill lineWidth chunks with color2
end

% -------------------------------------------------------------
%      Compute offset object/surrounds for highDensity mode
% -------------------------------------------------------------
switch highDensity
    case true
        % I will create objectHD and surroundHD which will have a third dimension
        % such that objectHD(:,:,1) and surroundHD(:,:,1) are the object and
        % surround objects centered on the subarray at the TOP of the screen.
        % objectHD(:,:,2) and surroundHD(:,:,2) are for the BOTTOM subarray.
        topArrayYOffsetFromCenter = 337 - screenCenter(1);
        bottomArrayYOffsetFromCenter = 431 - screenCenter(1);
        % build shifted object, which will be called objectHD (high density)
        objectHD(1:size( object,1 ), 1:size( object,2 ), 1) = object;
        objectHD([2 4],:,1) = objectHD([2 4],:,1) + topArrayYOffsetFromCenter;
        objectHD(1:size( object,1 ), 1:size( object,2 ), 2) = object;
        objectHD([2 4],:,2) = objectHD([2 4],:,2) + bottomArrayYOffsetFromCenter;
        % build shifted surround, which will be called surroundHD
        surroundHD(1:size( surround,1 ), 1:size( surround,2 ), 1) = surround;
        surroundHD([2 4],:,1) = surroundHD([2 4],:,1) + topArrayYOffsetFromCenter;
        surroundHD(1:size( surround,1 ), 1:size( surround,2 ), 2) = surround;
        surroundHD([2 4],:,2) = surroundHD([2 4],:,2) + bottomArrayYOffsetFromCenter;
    
        subarrayRepeats = 2; % used by a nested for loop to cycle between 
                 % the two objectHDs and surroundHDs
    case false
        subarrayRepeats = 1; % no switching between different object/surrounds
end % switch switch highDensity

% -------------------------------------------------------------
% Set up the mean intensity background screen and black the photodiode
% -------------------------------------------------------------
Screen('FillRect', mywindow, meanIntensity);
Screen('FillOval', mywindow, black, photodiode);
Screen('Flip',mywindow);
HideCursor
Priority(MaxPriority(mywindow));
vbl = WaitSecs(0.100); % makes finding the start of the stimulus easy

% *************************************************************
%                            Stimulus runs
% *************************************************************
for block_i = 1 : blocks % number of blocks specified by function arguments
  for subarray_i = 1 : subarrayRepeats
      if highDensity % have object and surround take on the appropriate value of
          % objectHD and surroundHD
          object = objectHD(:,:,subarray_i);
          surround = surroundHD(:,:,subarray_i);
      end
      
      for condition = 1 : 2 % alternates between coherent and anti-phase
          % condition 1 is coherent
          % condition 2 is anti-phase
          surroundMovesAt = round(1/(rate*ifi)) - moveFrames; % move starting when counter
          % is as close to rate as allowed be ifi, minus the number of frames it
          % takes to move.
          objectMovesAt = surroundMovesAt; % movement period is same for both. Phase offset
          % can be achieved by changing the start counter.
          switch condition
              case 1
                  surroundFrameCounter = 1; % counts up each frame until it is reset; used to time the different behaviors of the surround
                  objectFrameCounter = 1;   % same as above, but for the object.
              case 2
                  surroundFrameCounter = round( 0.5*(surroundMovesAt+moveFrames) );
                  objectFrameCounter =  1;
          end %switch condition
          
          
          surroundDir = 1; % keeps track of whether the surround moves up or down. After each movement this is flipped
          objectDir = 1;  % same as above, but for the object
          numFrames = cycles * (2*(surroundMovesAt+moveFrames)); % 2*(surroundMovesAt+moveFrames) frames returns surround to its original location
          for frame_i = 1 : numFrames
              % surround movement logic
              if surroundFrameCounter > surroundMovesAt + moveFrames
                  surroundFrameCounter = 1;
                  surroundDir = -surroundDir;
              elseif surroundFrameCounter > surroundMovesAt
                  surroundColors = circshift(surroundColors,[0 speed*surroundDir]);
                  % draw photodiode; pick color based on condition
                  if mod(frame_i,2) == 1 % odd frame
                      if surroundDir > 0
                          diodeColor = hiDiode(1, condition) .* [white white white]';
                      else
                          diodeColor = hiDiode(2, condition) .* [white white white]';
                      end
                  else % even frame
                      if surroundDir > 0
                          diodeColor = loDiode(1, condition) .* [white white white]';
                      else
                          diodeColor = loDiode(2, condition) .* [white white white]';
                      end
                  end %if... else... mod(frame_i,2) == 1
                  Screen('FillOval', mywindow, diodeColor, photodiode);
              end
              
              % object movement logic
              if objectFrameCounter > objectMovesAt + moveFrames
                  objectFrameCounter = 1;
                  objectDir = -objectDir;
              elseif objectFrameCounter > objectMovesAt
                  objectColors = circshift(objectColors,[0 speed*objectDir]);
                  % draw photodiode; pick color based on condition
                  if mod(frame_i,2) == 1 % odd frame
                      if surroundDir > 0
                          diodeColor = hiDiode(1, condition) .* [white white white]';
                      else
                          diodeColor = hiDiode(2, condition) .* [white white white]';
                      end
                  else % even frame
                      if objectDir > 0
                          diodeColor = loDiode(1, condition) .* [white white white]';
                      else
                          diodeColor = loDiode(2, condition) .* [white white white]';
                      end
                  end %if... else... mod(frame_i,2) == 1
                  Screen('FillOval', mywindow, diodeColor, photodiode);
              end
              
              % Increment the counters and then actually do the graphics
              surroundFrameCounter = surroundFrameCounter + 1;
              objectFrameCounter = objectFrameCounter + 1;
              
              Screen('FillRect', mywindow, surroundColors, surround) % draw the surround
              Screen('FillRect', mywindow, objectColors, object) % draw the object
             
              if KbCheck % Allow user to exit out by pressing any key
                  ShowCursor
                  Screen('CloseAll');
                  return;
              end
              vbl=Screen('Flip', mywindow, vbl + frameTime-0.01); %flip the screen
          end %for frame_i = 1 : Frames
      end % for condition = 1 : 2
  end % for subarray_i = 1 : subarrayRepeats
end % for block_i = 1 : blocks % number of blocks specified by function arguments
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