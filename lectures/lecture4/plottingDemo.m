% plottingDemo.m
% NENS 230 Autumn 2011, Stanford University
%
% This demo demonstrates a number of MATLAB concepts related to graphics
% object handles, figures, axes, and various plot types.

function figh = plottingDemo( inputArgument )
    % *********************************************************
    %          Demo 1: Figure handle and its properties
    % *********************************************************
    keyboard   % Stops execution here and lets user manipulate workspace in scope
    % Let's create a figure window. It has no axes yet, just a blank figure.
    figh = figure;

    ishandle( figh )
    
    % Let's check what properties this figure object has
    figureProperties = get( figh )
    
    % We can query for the VALUE of specific object PROPERTIES
    myName = get( figh, 'Name' )
    myColor = get( figh, 'Color' )
    myPosition = get( figh, 'Position')
    % Position is always a length 4 vector: [xPosition yPosition width height]
    
    % We can also change the value of a property using set
    newName = 'DemoFigure';
    
    set( figh, 'Name', newName )
    newColor = 'k'; 
    % We can even make the figure bigger.
    biggerSize = [myPosition(1) myPosition(2) myPosition(3)*1.3 myPosition(4)*1.3];
    
    % Look, setting multiple parameters at once using property-value pair syntax
    set( figh, 'Color', newColor, 'Position', biggerSize )

   
    % Most graphics object can be created with specified property values
    close( figh )
    ishandle( figh )
    
    % Recreate the figure, with a few changes
    figh = figure( 'Name', [newName ' Reborn'], 'Position', biggerSize );
    
    %% *********************************************************
    %          Demo 2: Axes, Lineseries, and Legend
    % *********************************************************
    
    keyboard %DEV
    % Load the example data
    load reachKinematics.mat
    
    % Let's add an axis to our figure
    axh = axes( 'Parent', figh )
    
    % You can see it's the child of figh, and vice versa
    [figh get(axh, 'Parent')]
    [axh get(figh, 'Children')]
    
    % We can look at the axis' properties in the same was as the figure's properties
    axProperties = get( axh )
    % Let's make it black
    set( axh, 'Color', 'k' )
    
    % The axis also has a position, which is in terms of fraction 
    axisPosition = get(axh, 'Position')

    
    % Let's plot the x position of the first reach trial to the NE target.
    line1h = plot( NEtrials{1}(1,:), 'Parent', axh )
    
    
    get(axh, 'Children')           % This is a child of axh
    [axh, get( line1h, 'Parent' )]   % Conversely, axh is the parent of line1h
    
    % ----------------------------------------------
    %                LINE SERIES
    % ----------------------------------------------
    % A lineseries object has properties
    line1props = get( line1h )
    
    % Let's manipulate a few of the more commonly used ones. 
    set( line1h, 'Color', [1 0 1], 'LineWidth', 3, 'LineStyle', ':' )
    box off;
    
    % We can plot more lineseries on the same axis. Let's add the Y and Z 
    % positions of the arm. You MUST first turn hold on
    hold on
    line2h = plot( NEtrials{1}(2,:), 'Parent', axh, 'Color', [1 0 0] )
    line3h = plot( NEtrials{1}(3,:), 'Parent', axh, 'Color', [0 0 1] )
    
    % ----------------------------------------------
    %                  LEGEND
    % ----------------------------------------------
    % Let's add a legend
    legh = legend('show')
    % That's not helpful. Let's try it the right way, by setting the 
    % 'DisplayName' property of each lineseries.
    delete( legh )
    set( line1h, 'DisplayName', 'X Position' )
    set( line2h, 'DisplayName', 'Y Position' )
    set( line3h, 'DisplayName', 'Z Position' )
    legh = legend(axh,'show')
    % We can move the legend around. Let's put it in top-left
    set( legh, 'Location', 'NorthWest')
    set( legh, 'Location', 'Best') % Useful if you don't know what data will be
    
    
    
    %% *********************************************************
    %          Demo 3: Limits, Line, Patch
    % *********************************************************
    % ----------------------------------------------
    %                        LIMITS
    % ----------------------------------------------
    % Let's say we want to focus on the 200 to 600ms epoch
    % and make 0mm the center of the vertical axis
    
    % Set the x limits
    set( axh, 'XLim', [200 600] )
    % Get the y limits and make symmetrical around zero
    myYlim = get( axh, 'YLim' )
    extrema = max( abs( myYlim ) )
    myYlim = [-extrema extrema]
    set( axh, 'YLim', myYlim )
    
    % Labels are objects to, although generally it's easier to just use the
    % xlabel shortcut and not keep track of this.
    myxLabelh = xlabel('Time (ms)')
    set( myxLabelh, 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'r')
    ylabel( '(mm)', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'r')
    
    % We can also reverse the direction of either of the axes
    set( axh, 'YDir', 'reverse' )
    set( axh, 'XDir', 'reverse' )
    set( axh, 'YDir', 'normal' )
    set( axh, 'XDir', 'normal' )
    
    % ----------------------------------------------
    %                         LINE
    % ----------------------------------------------
    % Let's make a horizontal line that marks y=0
    % We need to get it's x-coordinates to be the far left to far right of
    % visible part of the line.
    % Want a line from (200,0) to (600, 0):
    zerolineh = line( [200 600], [0 0], 'Parent', axh );
    get(zerolineh)
    % Let's make it gray and dotted.
    set( zerolineh, 'Color', [.5 .5 .5], 'LineStyle', ':')
    
    % ----------------------------------------------
    %                       PATCH
    % ----------------------------------------------
    % Let's shade the target region (it's the same for X and Y)
    targetDeflectionMM = [50 70];
    
    % We'll need the x and y positions of all the vertices; in this case
    % I want a rectangle, thus 4 vertices.
    patchCoordinates = [200 targetDeflectionMM(2) ;  % top-left
                        600 targetDeflectionMM(2) ;    % top-right
                        600 targetDeflectionMM(1) ;  % bottom-right
                        200 targetDeflectionMM(1)] %bottom-left
    
    % DRAW THE PATCH
    % Now call patch. Remember that it wants separate inputs for the x-coordinates
    % of the vertices and the y-coordinates of the vertices.
    % Note that patch is strange and color 
    patchh = patch( patchCoordinates(:,1), patchCoordinates(:,2), [.7 .4 .1], 'Parent', axh ); 
    % note that patch( ) requires the color to be the third argument. It can
    % later be changed with 'FaceColor', and 'EdgeColor' properties.
    % To make it transparent, change the FaceAlpha and EdgeAlpha property
    set( patchh, 'FaceAlpha', .5, 'EdgeAlpha', .5 ) ;
    
    %% *********************************************************
    %              Demo 4: 3D Plotting
    % *********************************************************
    % Let's delete everything that's currently in these axes.
    allChildren = get( axh, 'Children')
    delete( allChildren)
    delete( legh )
    % still have the axis limits. So let's just make a new axis.
    delete( axh )
    axh = axes( 'Parent', figh )
    % Let's plot a trial in 3D:
    trajh = plot3( NEtrials{1}(1,:), NEtrials{1}(2,:), NEtrials{1}(3,:), 'Parent', axh )
    
    % Make it easier to see the individual points, and also mark start and stop
    set( trajh, 'LineStyle', '.' )
    hold on;
    startPth = scatter3( NEtrials{1}(1,1), NEtrials{1}(2,1), NEtrials{1}(3,1), 'MarkerFaceColor', 'g', 'SizeData', 12^2 )
    endPth = scatter3( NEtrials{1}(1,end), NEtrials{1}(2,end), NEtrials{1}(3,end), 'MarkerFaceColor', 'r', 'SizeData', 12^2 )
    xlabel('X (mm)', 'FontSize', 14 )
    ylabel('Y (mm)', 'FontSize', 14  )
    zlabel('Z (mm)', 'FontSize', 14  )
    
    % You can get the properties that define a viewpoint using the 'CameraPositon', 'CameraTarget', 
    % 'CameraTarget', and 'CameraUpVector' properties
    myCamPos = get( axh, 'CameraPosition' )
    myCamTar = get( axh, 'CameraTarget' )
    myCamUp = get( axh, 'CameraUpVector' )
    
    % Go back to the view we liked
    set( axh, 'CameraPosition', myCamPos, 'CameraTarget', myCamTar, 'CameraUpVector', myCamUp )
    
    close all
    
    %% *********************************************************
    %              Demo 5: Subplots
    % *********************************************************
    % Let's make separate plots for the x,y, and z positions in 
    % this data
    % Load the example data
    load reachKinematics.mat
    figh = figure( 'Name', 'Subplot Example' );
    
    % X position
    axXh = subplot( 3,1,1 );
    title('X Position', 'FontSize', 12 )
    % Plot all of the trials with NE target in RED
    for iTrial = 1 : length( NEtrials )
        plot( NEtrials{iTrial}(1,:), 'Color', 'r', 'Parent', axXh );
        hold on
        pause(0.5)
    end
    % Plot all of the trials with NW target in BLUE
    for iTrial = 1 : length( NWtrials )
        plot( NWtrials{iTrial}(1,:), 'Color', 'b', 'Parent', axXh );
    end
    
    % Y position
    axYh = subplot( 3,1,2 );
    title('Y Position', 'FontSize', 12 )
    for iTrial = 1 : length( NEtrials )
        plot( NEtrials{iTrial}(2,:), 'Color', 'r', 'Parent', axYh );
        hold on
    end
    % Plot all of the trials with NW target in BLUE
    for iTrial = 1 : length( NWtrials )
        plot( NWtrials{iTrial}(2,:), 'Color', 'b', 'Parent', axYh );
    end
    
    % Z position
    axZh = subplot( 3,1,3 );
    title('Z Position', 'FontSize', 12 );
    for iTrial = 1 : length( NEtrials )
        plot( NEtrials{iTrial}(3,:), 'Color', 'r', 'Parent', axZh );
        hold on
    end
    % Plot all of the trials with NW target in BLUE
    for iTrial = 1 : length( NWtrials )
        plot( NWtrials{iTrial}(3,:), 'Color', 'b', 'Parent', axZh );
    end
    
    
    % Let's link the axes between the subplots
    linkaxes( [axXh axYh axZh], 'xy' )
    
    close all

    %% *********************************************************
    %      Demo 6: Bar Plots, Tick Labels, and Text
    % *********************************************************
    clear
    % Example data with behavioral data from 4 mice. The values 
    % correspond to discrete meaning:
    % 1 == No Attempt at Task
    % 2 == Attemped Task With No Success
    % 3 == Partial Success
    % 4 == Full Success
    load pharmaBehavior
    
    % Make a grouped bar plot with this data:
    % bar expects each row is a different group, elements within a row
    % are different elements of the same group.
    groupedData = [behavior.noDrug; behavior.placebo; behavior.drugA; behavior.drugB]
    figh = figure('Name', 'Categorial Behavior Bar Plot Example');
    barh = bar( groupedData ) % This will automatically create an axis
    % We can change the appearance of the bar object
    set( barh, 'BarWidth', .9 );
    
    % I can pull out the axis handle from the bar handle
    axh = get( barh(1), 'Parent');
    % Add a legend; note this alternate way of specifying the descriptive strings
    legh = legend( axh, 'Subj 1', 'Subj 2', 'Subj 3', 'Subj 4' );
    set( legh, 'Location', 'NorthWest', 'Color', [.6 .6 .6], 'FontSize', 12 )
    
    
    % TICK LABELS
    % Let's make the x ticks meaningful 
    myXticks = get( axh, 'XTick')
    class( myXticks )
    
    myXtickLabels = get( axh, 'XTickLabel' )
    class( myXtickLabels )
    
    % Replace the X axis labels with strings of our choosing
    newXtickLabels = {'None', 'Placebo', 'Drug A', 'Drug B'}; % Can be a cell array of strings
    % Note: You must have as many tick labels as there are ticks (4 in this case)!
    set( axh, 'XTickLabel', newXtickLabels, 'FontSize', 12 )
    
    % Let's take a look at y ticks...
    myYticks = get( axh, 'YTick' )
    % Now make it so there are only 4 yTicks, at values 1, 2, 3, 4
    set( axh, 'YTick', [1 2 3 4])
    set( axh, 'YTickLabel', {'No Attempt', 'Attempted', 'Partial Success', 'Full Success'} )
    
    % Make the upper y-limit just a bit larger to make the figure look nicer.
    set( axh, 'YLim', [0 4.5] )
    
    titleh = title( 'Behavioral Test Results  ', 'FontSize', 16) % Pro-Tip: spaces at start and finish;
   
    % As with everything, the title is an object with properties to play with
    get( titleh )
    set( titleh, 'BackGroundColor', 'b', 'Color', [1 1 1], 'FontSize', 16 )
    
    
    % TEXT
    % Suppose we had some additional data to show that the effects of Drug B
    % are significant and want to show this with an annotation of '*' above
    % that group. The text command let's you put a text object anywhere.
    % Its syntax is text_handle = text(x,y, YourString, 'Property1', 'Value1', ... )
    texth = text( 4, 4.1, '* (p=.03)', 'FontSize', 16, 'VerticalAlignment', 'bottom', 'Parent', axh )
    set( texth, 'HorizontalAlignment', 'center' )
    

end