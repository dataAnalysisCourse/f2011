% SpatialFrequencyVsContrast.m
% 
% Presents light/dark horizontal bars which reverse at 2*<rate> Hz while 
% sweeping across the 2D feature space of stimulus spatial frequency and 
% contrst, The values of spacing (width) of the bars is specified in
% <barSizeVec>, while the Michelson contrasts smapled is specified by
% <contrastVec>. All pairs of <barSizeVec> and <contrastVec> are sampled,
% with <contrastVec> being the outer loop. Furthermore, for each condition
% specified by <barSizeVec> there is also the option to sample a number of
% different spatial offsets of the bars by setting the corresponding entry
% of <locationMovesVec> to be the number of evenly-spaced spatial locations
% to run through for that index's bar size.
%      The photodiode area matches the exact color of the topmost line of
% the object. Thus it encodes both the time of flips and the current
% contrast, and the order of dark/light.
%
% Total Duration = cycles*(1/<rate>)*sum(<locationMovesVec>)*length(<contrastVec>)
%
% USAGE:
%       [] = SpatialFrequencyVsContrast( cycles, contrastVec, barSizeVec, ...
%                                           locationMovesVec, rate, highDensity (,screen_s) )
%
% INPUTS:
%       cycles                For each condition (contrast-barsize-position triplet),
%                             will be repeated this many cycles. A cycle
%                             includes both phases of the 180deg phase
%                             shift stimulus.
%       contrastVec           vector containing the Michelson contrast
%                             values used when varying the contrast parameter
%       barSizeVec            vector contraining the barSizes (in pixels) 
%                             used when varying the spatial frequency
%                             parameter
%       locationMovesVec      same length as barSizeVec; specifies how many
%                             spatially-shifted variants to do for each
%                             barSize condition. For example, if barSizeVec
%                             was set to 8 and the corresponding entry of
%                             locationMovesVec was 4, then the 8-pixel-bar
%                             grating stimulus (which reverses intensity
%                             every half-cycle) would be repeated four
%                             times, with each repeat presenting the bars 2
%                             pixels lower than the previous repeat. Values
%                             of locationMovesVec must be integer of at
%                             least one). 
%       rate                  specifies the temporal frequency (in Hz)
%                             between repeats of each cycle of the
%                             180-degree phase reversal stimulus. So if
%                             rate is 1Hz, the screen would flip every half
%                             second and each of the two reversed phases 
%                             would be displayed once per second..
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
% Created by Sergey Stavisky on October 27, 2010
% Last modified by Sergey Stavisky on October 29, 2010
function [] = SpatialFrequencyVsContrast( cycles, contrastVec, barSizeVec, locationMovesVec, rate, highDensity, screen_s )
AssertOpenGL
%--------------------------------------------------------------
%                     Argument Processing
%--------------------------------------------------------------
if nargin == 0
    error('[SpatialFrequencyVsContrast] You did not provide necessary arguments')
elseif nargin == 1
    contrastVec = [0.05 0.1 0.2 0.4 0.8];
    barSizeVec  = [8 384];
    locationMovesVec = [4 1];
    rate = 1;
    highDensity = false;
    fprintf('[SpatialFrequencyVsContrast] Warning! Using default values for contrastVec, barSizeVec, locationMovesVec, rate, and highDensity.\n');
elseif nargin == 2
    barSizeVec  = [8 384];
    locationMovesVec = [4 1];
    rate = 1;
    highDensity = false;
    fprintf('[SpatialFrequencyVsContrast] Warning! Using default values for barSizeVec, locationMovesVec, rate, and highDensity.\n');
elseif nargin == 4 % having defaults for locationMovesVec and barSizeVec makes no sense so I skip this
    rate = 1;
    highDensity = false;
    fprintf('[SpatialFrequencyVsContrast] Warning! Using default values for rate and highDensity.\n');
elseif nargin == 5 % having defaults for locationMovesVec and barSizeVec makes no sense so I skip this
    highDensity = false;
    fprintf('[SpatialFrequencyVsContrast] Warning! Using default values for highDensity.\n');
end
% check that barSizeVec and locationMovesVec are the same length
if length( barSizeVec ) ~= length( locationMovesVec)
   error('barSizeVec (length %i) mus be same length as locationMovesVec (length %i)', length( barSizeVec ), length( locationMovesVec ));
end
% Check that all locationMovesVec are at least one
if any( locationMovesVec<1 )
    error('locationMovesVec %s entries must be integers greater than or equal to 1', mat2str( locationMovesVec ) );
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
frameTime= round( 1/(2*rate*ifi) )*ifi; % as close as we can get to the desired rate with
                               % the available monitor refresh rate. Note
                               % that frametime is half what is specified
                               % by rate since there are two phases/cycle
                               
switch highDensity
    case false
        fieldSize = [384 384]; % will use a box of this many pixels in height and width
    case true
        fieldSize = [480 384];
end
% Warn user if not all the field will be used by squares (In which case I 
% don't cut them off, instead opting to just not build the last square).
for i = 1 : length(barSizeVec)
    if mod(fieldSize(1), barSizeVec(i) ) ~= 0
        fprintf('[LinesRFmap] Warning! fieldSize height %i is not a multiple of barSize(%i)=%i\n', fieldSize(1), i, barSizeVec(i))
    end
end

%--------------------------------------------------------------
%                 Prep before starting the stimulus
%--------------------------------------------------------------
% get coordinates of my field; the stimuli will appear here
screenCenter = floor(screenDim/2);
left = floor( screenCenter(2) - fieldSize(2)/2 + 1 ); % left of field
top = floor( screenCenter(1) - fieldSize(1)/2 - 1);
% left and top of my field
field = [left top (left+fieldSize(2)-1) (top+fieldSize(1)-1)];

% build the horizontal-lines object.
% Each subpart of the object will be
% a line. Bunches of adjascent lines will have the same color to create
% appearance thicker bars. It turns out this method makes the movement
% logic easier since the number of lines never changes (wheras the number
% of bars grows/shrinks by one as a bar wraps across both edges of a field.
linetops = field(2):1:field(4);
linebottoms = linetops+1;
linelefts = repmat( field(1), 1, length(linetops) );
linerights = repmat( field(3), 1, length(linetops) );
object = [linelefts; linetops; linerights; linebottoms];

% define the two psuedo-colors of the horizontal bars (which consist of one or
% more vertically stacked horizontal lines). These aren't real colors; they
% will be multiplied by contrast and meanColor to get contrast-specified
% values later
color1 = [1 1 1]'; 
color2 = [0 0 0]'; 
meanColor = [meanIntensity meanIntensity meanIntensity]';

% build the pseudo-colors for each line to create impression of contiguous bars.
% Since the different barSizes need different color patterns, and since
% this operation is not vectorized, I pre-create them all here and use the
% third dimension of objectColors to store mulitiple objectColors. so
% objectColors(:,:,2) is the objectColors matrix for the
% barSizeVec(2)-sized bars. 
objectColors = repmat( color1, [1, length(linebottoms), length(barSizeVec)] ); % starts all as color1
for barSize_i = 1 : length( barSizeVec )
    lineWidth = barSizeVec(barSize_i);
    for barStart = 1 : 2*lineWidth : length(linetops)-1
        objectColors(:,barStart:barStart+lineWidth-1,barSize_i) = repmat(color2, 1, lineWidth); %fill lineWidth chunks with color2
    end
end %for barSize_i = 1 : length( barSizeVec )

% Pre-allocate some matrices we will be using
myObjectBinaryColor =  false( size(objectColors(:,:,1)) ) ; % logical
myObjectColor = double( myObjectBinaryColor ); % matrix
 
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
for contrast_i = 1 : length( contrastVec )
    for barsize_i = 1 : length( barSizeVec )
        myObjectBinaryColor = objectColors(:,:,barsize_i); %(just 1's and 0's in right place)
        for position_i = 1 : locationMovesVec(barsize_i)
            % now shift the colormap to match appropriate position by
            % circularshifting it by barSize/locationMoves pixels.
            if position_i > 1 % since objectColors contains the default positions 
                % (i.e. position1 or phase=0 positions) for each barsize.
                myObjectBinaryColor = circshift( myObjectBinaryColor ,[0 barSizeVec(barsize_i)/locationMovesVec(barsize_i)]);
            end           
            
            % Grating reversal loop; Screen('Flip') happens here
            for frame_i = 1 : cycles * 2 % because there are two phases to each cycle
                                         % and I reverse by 180deg the phase of the 
                % I just reverse the grating every cycle. Since I do it
                % first, this means that actually I've started the stimulus
                % presentation from the 180 offset relative to what is
                % defined in myObjectColor; this doesn't matter but is
                % worth noting.
                myObjectBinaryColor = ~myObjectBinaryColor;
                
                % COMPUTE THE OBJECTCOLOR FOR THIS CONTRAST AND POSITION
                % I don't do it two loops out (which would've been more
                % efficient) because then it'd break down for the
                % full-field condition. 
                % now create the true colors based on the specified
                % contrast using I - b*2*mu*c + (1-c)*mu where b is either zero or
                % one (i.e. existing state of myObjectColor)
                myObjectColor(1,:) = myObjectBinaryColor(1,:).*2.*meanColor(1).*contrastVec(contrast_i) ...
                    + (1-contrastVec(contrast_i))*meanColor(1); % note the elementwise addition on this line
                myObjectColor(2,:) = myObjectBinaryColor(2,:).*2.*meanColor(2).*contrastVec(contrast_i) ...
                    + (1-contrastVec(contrast_i))*meanColor(2); % note the elementwise addition on this line
                myObjectColor(3,:) = myObjectBinaryColor(3,:).*2.*meanColor(3).*contrastVec(contrast_i) ...
                    + (1-contrastVec(contrast_i))*meanColor(3); % note the elementwise addition on this line
                myObjectColor = floor( myObjectColor );
                
                % draw this color into the field and the photodiode ovalclear Screen
                Screen('FillRect', mywindow, myObjectColor, object);
                Screen('FillOval', mywindow, myObjectColor(:,1), photodiode); % photodiode is same color as top bar of object

                if KbCheck % Allow user to exit out by pressing any key
                    ShowCursor
                    Screen('CloseAll');
                    return;
                end

                vbl=Screen('Flip', mywindow, vbl + frameTime-0.01);
            end %for frame_i = 1 : Frames
        end %for position_i = 1 : locationMovesVec(barsize_i)
    end %for barsize_i = 1 : length( barSizeVec )
end %for contrast_i = 1 : length( contrastVec )
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