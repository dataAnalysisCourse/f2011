% trackingDemo.m
% NENS 230 Autumn 2011, Stanford University
%
% This demo demonstrates how to create a movie to show the location over time
% of a mouse in an Elevated Plus Maze.

% *************************************************************
%              Initialize the figure
% *************************************************************
% Load Tracking Data
load trackingDemoData

% Draw the maze
figh = drawPlusMaze;
axh = get( figh, 'Children');

numFrames = length( tracking.time );

% Let's figure out the frame rate of the data
% so later we can make the movie play at true speed
% if we so desire.
timeBetweenFrames = tracking.time(2)-tracking.time(1);
fps = 1/timeBetweenFrames;

% We'll also keep track of total time spent in closed versus open arms
timeOpenArm = 0;
timeClosedArm = 0;

% Initialize the scene by creating the graphics objects
% which will be manipulated in each successive frame.

% will display time of each frame
timetexth = text( 100, 500, sprintf('t = %.3fs', 0), ...
    'FontSize', 16, 'Parent', axh, 'HorizontalAlignment', 'left' ); 

% Put an orange circle where mouse is
mouseh = scatter( tracking.x(1), tracking.y(1), 'Parent', axh, ...
    'Marker', 'o', 'SizeData', 10^2, 'MarkerFaceColor', [.7 .4 .2], ...
    'MarkerEdgeColor', [.7 .4 .2]);

% Display cumulative time spent in open arms up to current frame
timeOpenTexth = text( 100, 300, sprintf('t_{open} = %.3fs', 0), ...
    'FontSize', 16, 'Parent', axh, 'HorizontalAlignment', 'left' ); % will display time of each frame

% Display cumulative time spent in closed arms up to current frame
timeClosedTexth = text( 100, 200, sprintf('t_{closed} = %.3fs', 0), ...
    'FontSize', 16, 'Parent', axh, 'HorizontalAlignment', 'left' ); % will display time of each frame

% *************************************************************
%               Build the movie frame by frame
% *************************************************************
display('Waiting to build movie frames');
% Assemble the movie by saving as a frame each step in the plot
for iFrame = 1 : numFrames
    thisFrameX = tracking.x(iFrame);
    thisFrameY = tracking.y(iFrame);
    
    % Compute whether it is in open or closed arm and update
    % the cumulative timeOpenArm and timeClosedArm accordingly.
    if (thisFrameX > 50 || thisFrameX < -50) && (thisFrameY < 50 && thisFrameY > -50)
        % I'm in one of the closed arms
        timeClosedArm = timeClosedArm + 1/fps;
    elseif (thisFrameY > 50 || thisFrameY < -50) && (thisFrameX < 50 && thisFrameX > -50)
        timeOpenArm = timeOpenArm + 1/fps;
    end
    
    % Update the time text
    set( timetexth, 'String', sprintf('t = %.3fs', tracking.time(iFrame) ) )
    % Update the mouse location
    set( mouseh, 'XData', thisFrameX, 'YData', thisFrameY );

    % Update the time spent in open/closed arm text
    set( timeOpenTexth, 'String', sprintf('t_{open} = %.3fs', timeOpenArm ) )
    set( timeClosedTexth, 'String', sprintf('t_{closed} = %.3fs', timeClosedArm ) )

    % Let's record this frame in a growing structure array called movFrames
    movFrames(iFrame) = getframe( axh ); % NOTE: For some reason figure must be on primary display  
end %for iFrame = 1 : numFrames

% *************************************************************
%          Now take this structure and make it into a movie
% *************************************************************
display('Waiting to play movie');
keyboard
% We can play it within MATLAB:
movie( movFrames, 1, fps ) % second argument means play it 1 times

% But it's better to make this into a movie that can be played
% outside matlab
movie2avi( movFrames, 'mouseTrackingMovie', 'fps', fps )
display('Movie saved')