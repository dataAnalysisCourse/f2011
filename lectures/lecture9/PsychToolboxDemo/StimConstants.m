% StimConstants.m
%
% Opens a screen window and returns handle to said window.
% It also returns a number of constants that are used by most 
% stimuli-generating functions and are derived from the window.
%
% USAGE:
%       [mywindow photodiode screenDim ifi black white meanIntensity] = StimConstants()
%
% INPUTS:
%    (none)
%
% OUTPUTS: 
%    mywindow       handle of window opened        
%    photodiode     coordinates of photodiode, [left top right bottom]
%    screenDim      [ysize xsize] of the screen (in pixels)
%    ifi            inter-frame interval (in seconds)
%    black          value of black (probably 0)
%    white          value of white (probably 255)
%    meanIntensity  mean of black/white
%
% Created by Sergey Stavisky on October 20, 2010
% Last modified by Sergey Stavisky on October 20, 2010

function [mywindow photodiode screenDim ifi black white meanIntensity] = StimConstants()

AssertOpenGL;
try
    myscreen=0;
    
    % Open a window; mywindow pointer is returned
    mywindow=Screen('OpenWindow',myscreen);
    [screenDim(2) screenDim(1)] = Screen('WindowSize', mywindow); % screenDime=[xsize ysize]
    ifi=Screen('GetFlipInterval',mywindow);    % frame period
    
    % Get rect coordinates of oval visible by the photodiode 
    photodiode=ones(4,1);
    photodiode(1)=screenDim(2)/10*9;
    photodiode(2)=screenDim(1)/10*1;
    photodiode(3)=screenDim(2)/10*9+80;
    photodiode(4)=screenDim(1)/10*1+80;
    
    % get black/white values and meanIntensity
    black=BlackIndex(mywindow);
    white=WhiteIndex(mywindow);
%     meanIntensity = ((black+white+1)/2)-1;
    meanIntensity = (black+white)/2; % note that this isn't an integer and so isn't
    % a displayable value. Thus, anytime it is used don't forget to floor()
    
catch exception
    Screen('CloseAll');
    error(['[StimConstants] StimConstants.m failed:' exception.message])
    
end % try..catch

end %function