% ClassificationBattery.m
%     
%     Goes through the eight types of stimuli in the classification experiment.
% This function is just a shell to call the respective stimulus functions
% with appropriate arguments.
%     This script first asks the user to press any key except spacebar to
% start the stimuli manually (without waiting for record strobe) or to press 
% spacebar to wait for the strobe from the recording computer before
% starting the stimuli.
%     It uses the LabNotebook() function to create a .txt record of all
% commands used as well as a copy of all stimulus-generating m-functions
% called, and important parameters.
% 
% USAGE:
%       [] = ClassificationBattery(  )
%
% INPUTS:
%       (none)
% OUTPUTS: 
%       (none)
%
% Created by Sergey Stavisky on October 25, 2010
% Last modified by Sergey Stavisky on December 4, 2011
% (for NENS 230 Demo)
%---------------------------------------------------------------------
%                        User-Specified Parameters
%---------------------------------------------------------------------
highDensity = false; % using high-density array

%---------------------------------------------------------------------
%                                Prep
%---------------------------------------------------------------------
% The LabNotebook()-generated record of the experiment stimuli will be
% saved in this directory.
saveDir = [pwd filesep 'ExperimentStimuli_' datestr(now, 'yyyy_mm_dd_HH_MM_SS')];
 
% Create the window and constants that will be passed to each stimulus
% function.
[screen_s.mywindow screen_s.photodiode screen_s.screenDim screen_s.ifi screen_s.black screen_s.white screen_s.meanIntensity] ...
    = StimConstants();

% Use overload of LabNotebook() to record some values of parameters that
% otherwise wouldn't be saved.
filename = LabNotebook(['screenDim = ' mat2str(screen_s.screenDim)], saveDir );
filename = LabNotebook(['ifi = ' mat2str(screen_s.ifi)], saveDir, filename );
filename = LabNotebook(['highDensity = ' mat2str(highDensity)], saveDir, filename );


%---------------------------------------------------------------------
% Prompt user to press key to start, either with or without WaitForRec
%---------------------------------------------------------------------
HideCursor
Screen('FillRect', screen_s.mywindow, screen_s.meanIntensity);
Screen('FillRect', screen_s.mywindow, screen_s.white, screen_s.photodiode );
Screen('DrawText', screen_s.mywindow, '1) Position photodiode over white box', 50, 50);
Screen('DrawText', screen_s.mywindow, '2) Press spacebar to wait for recording computer', 50, 100);
Screen('DrawText', screen_s.mywindow, '   OR press any other key to start stimuli without', 50, 130);
Screen('DrawText', screen_s.mywindow, '   waiting for record signal', 50, 160);
Screen('DrawText', screen_s.mywindow, ['NOTE: Use high density array is set to ' mat2str(highDensity)], 50, 210);
Screen('Flip', screen_s.mywindow);

[~, keyCode] = KbWait;
keyInt = find(keyCode);

if keyInt==KbName('space')
    try
        fprintf('[ClassificationBattery] Starting stimuli after WaitForRec\n')
        WaitForRec;
        % record that WaitForRec was used..
        filename = LabNotebook('WaitForRec was used', saveDir, filename );
    catch exception
        clear mex
        error('[ClassificationBattery] Tried and failed to call WaitForRec')
    end
else
    fprintf('[ClassificationBattery] Starting stimuli without WaitForRec\n')
end
fprintf('[ClassificationBattery] Starting stimuli...\n')
startT = tic;

%---------------------------------------------------------------------
%                         Run battery of stimuli
%---------------------------------------------------------------------
% LinesRFmap( time, contrast, barSize, seed, highDensity (,screen_s) )
% Total Duration = <time>;
command = 'LinesRFmap( 5, .35, 8, 0, highDensity, screen_s );';
filename = LabNotebook( command, saveDir, filename );
eval(command);

% SensitizationLines( c1TimeC2Time, numBlocks, contrast1, contrast2, barSize, seed, highDensity (,screen_s)
% Total Duration = <numBlocks> * (<c1TimeC2Time>(1) + <c1TimeC2Time>(2))
command = 'SensitizationLines( [2 2], 1, .35, .08, 480, 0, highDensity, screen_s );';
filename = LabNotebook( command, saveDir, filename );
eval(command);


% FullFieldRandomColor( time, GaussianRGBmean, GaussianRGBcontrast, seed, highDensity (,screen_s)
% Total Duration = <time>
command = 'FullFieldRandomColor( 4, [.5; .5; .5], [.35; .35; .35], 0, highDensity, screen_s);';
filename = LabNotebook( command, saveDir, filename );
eval(command);

% ObjectMotion( cycles, blocks, speed, rate, lineWidth, highDensity (,screen_s)
% Total Duration = <cycles>*<blocks>*(1/<rate>)*4  (Double if using <highDensity> is true)
command = 'ObjectMotion( 2, 1, 1, 1, 8, highDensity, screen_s );';
filename = LabNotebook( command, saveDir, filename );
eval(command);

% DirectionalMotion( cycles, speed, directions, lineWidth, highDensity (,screen_s)
% Total Time = length(<directions>)*<cycles>*<linewidth>*2*(1/speed)*ifi
command = 'DirectionalMotion( 4, 2, {''up'', ''right'', ''down'', ''left''}, 16, highDensity, screen_s );';
filename = LabNotebook( command, saveDir, filename );
eval(command);

% SquaresRFmap( time, contrast, sideLength, seed, highDensity, (,screen_s) )
% Total Duration = <time> 
command = 'SquaresRFmap( 4, 1, 16, 0, highDensity, screen_s );';
filename = LabNotebook( command, saveDir, filename );
eval(command);


%---------------------------------------------------------------------
%                        Clean-Up
%---------------------------------------------------------------------
% display and log how long the total run took
endT = toc( startT );
fprintf('[ClassificationBattery] Total elapsed time was %f sec\n', endT)
filename = LabNotebook(['Total elapsed time was = ' mat2str(endT)], saveDir, filename );

% Show cursor and clear away the window
ShowCursor
Screen('CloseAll');