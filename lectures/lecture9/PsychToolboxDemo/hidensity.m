% shows where the two subarrays of the high density array are. I use this
% as a scratchpaper to figure out how to translate my low-density stimuli
% to high density stumuli

[mywindow photodiode screenDim ifi black white meanIntensity] = StimConstants();
toparray = [500 327 524 347];
botarray = [500 421 524 441]; 



% CenterOfBottom = (441+421-1)/2; % not sure why I used these before
% CenterOfTop = (327+347-1)/2;

CenterOfBottom = (441+421)/2;     % This seems right
CenterOfTop = (327+347)/2;

% so to have each array looking at the equivalent of 384x384 around the
% center of a low density array, I could make the stimulus:
top =  CenterOfTop - 384/2;
bottom = CenterOfBottom + 384/2;
% this gives 478, which isn't a multiple of 16.
% height of 480 is close enough and is divisible by 16
% width is still 384

fieldSize = [480 384];
% present what this looks like:
screenCenter = floor(screenDim/2);
left = floor( screenCenter(2) - fieldSize(2)/2 + 1 ); % left of field
top = floor( screenCenter(1) - fieldSize(1)/2 - 1);
% left and top of my field
field = [left top (left+fieldSize(2)) (top+fieldSize(1))];

Screen('FillRect', mywindow, meanIntensity);
Screen('FillRect', mywindow, [255;255;255], field)
Screen('FillRect', mywindow, [0 0 ; 0 0; 0 0], [toparray' botarray']);
Screen('Flip', mywindow );

pause(3)
ShowCursor
Screen('CloseAll');