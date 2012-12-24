% interactiveDemo.m
% NENS 230 Autumn 2011, Stanford University
%
% This demo demonstrates a few particularly useful interactive programming
% functions available in MATLAB. We will use them to make a simple program
% that allows the user to choose an image to load, examine a single color
% channel, amplify and threshold the intensities, draw a bounding box around
% a region of interest, label this region, and then save the modified image.

%% ***********************************************************************
%                               uigetfile  
% ***********************************************************************
% This function presents a file selection graphical user interface (GUI)
% We're going to use this to select the image file to load in.
%
% Query user as to which image to load
fprintf('Running Simple Color Channel Seperator/Adjuster...\n')
% First argument are filter options, second is the dialog box text
[fname, pathname] = uigetfile({'*.jpg';'*.tif'}, 'Select image to process');
% Choose retina.tif for the demo

if nnz( ~fname ) % user cancelled
    fprintf('User aborted\n')
    return % ends this script or functon
else
    [imdata, cmap] = imread( [pathname fname] );% Can actually use imread without specifying format
                                                % and MATLAB will usually figure it out. The better
                                                % way would be to parse fname for the file extension
                                                % and use that as the format input to imread( ).
end
% Display the image that was loaded
fprintf('Displaying selected image %s\n',  fname)
figh = figure;
imh = image( imdata );
title('Original image', 'FontSize', 16)

%% ***********************************************************************
%                               menu  
% ***********************************************************************
% This presents a GUI with push-buttons you define. We're going to use it
% to ask the user which color channel they want to look at.

% First argument is the prompt string, the rest are options. The output is 
% an integer specifying the index of which choice was selected 
% (1==RED, 2 == GREEN, 3 == BLUE)
userChoice = menu( 'Which color channel to look at?', 'RED', 'GREEN', 'BLUE', 'dont click me' );


% Create rowx * cols * 3 zero matrix called monochrome, in which we will
% fill one channel with data from the image
monochrome = uint8( zeros( size( imdata ) ) ); % Note typecast; these images are 8-bit

switch userChoice
    case 1 % RED
        monochrome(:,:,1) = imdata(:,:,1);
        choiceStr = 'Red';
    case 2 % GREEN
        monochrome(:,:,2) = imdata(:,:,2);
        choiceStr = 'Green';
    case 3 % BLUE
        monochrome(:,:,3) = imdata(:,:,3);
        choiceStr = 'Blue';
end
fprintf( 'Zeroing all but %s intensities\n', choiceStr )
delete( imh )
imh = image( monochrome );
title( sprintf('%s Only', choiceStr), 'FontSize', 16)


%% ***********************************************************************
%                               input  
% ***********************************************************************
% Asks for command-line from the user. We're going to use it to ask the user
% how much to amplify (brighten/darken) the image.
response = input('How much to amplify the image intensity?\n(e.g. 1 is no change, 2 means double, 0.5 means halve) ');
% Note that without second ,'s' argument, response automatically evaluates 
% the input string. So entering '[5+3 10]' would yield response of [8 10]

% Amplify the image as specified
monochrome = monochrome .* response;
% Update the image
fprintf('Amplifying the image by a factor of %.2f\n', response)
delete( imh )
imh = image( monochrome );
title( sprintf('%s Only, Amplified %.2fx', choiceStr, response), 'FontSize', 16)


%% ***********************************************************************
%                               inputdlg 
% ************************************************************************
% Graphical input dialog box. We're going to use this to ask the user to select 
% a brightness threshold below which we'll set the intensity to zero.

% We can use data cursor to see what intensity values various pixels have.
% This is crude; for a real tool, we'd probably want to add a slider bar and let
% you play with it to see how that changes the image. See function 'uicontrol'.
% Unfortunately we do not have time to cover building graphical user interfaces today.
threshold = inputdlg( 'Enter minimum threshold or cancel to skip thresholding' )
if isempty( threshold ) % The user cancelled
    fprintf('User chose to skip thresholding\n')
else % User specified a threshold
    threshold = str2num( threshold{1} ); % need to convert from string-within-
                                         % cell to a scalar.
    fprintf( 'Thresholding at %.1f\n', threshold )
    % Apply the thresholding
    monochrome(monochrome < threshold) = 0;
    % Update the image and title
    delete( imh )
    imh = image( monochrome );
    title( sprintf('%s Only, Amplified %.2fx, Threshold at %.1f', ...
        choiceStr, response, threshold), 'FontSize', 16 )
end %if isempty (threshold )


%% ***********************************************************************
%                              ginput 
% ************************************************************************
% Gets the position of a user's click in an axis. We will use it to have the 
% user draw a bounding box around the cell of interest and give it a text
% label.

% allow user to select four points, and will connect lines between them
fprintf('Draw bounding box around cell of interest\n')

axh = get(imh, 'Parent');
% GET USER CLICK COORDINATE
[x0,y0] = ginput( 1 ) % argument of 1 means do it once
% Mark this initial location
hold on;
scatter(x0,y0, 'Marker', 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', ...
    'w', 'SizeData', 4, 'Parent', axh)
% save the INITIAL x0,y0; we'll use these to complete the box at the end
xfirst = x0;
yfirst = y0;
% Allow user to select three more points
for i = 1 : 3 
    [x1, y1] = ginput(1);
    % Now draw a line connecting start point (x0,y0) with endpoint (x1,y1)
    line([x0 x1],[y0 y1], 'Parent', axh, 'Color', 'w', 'LineWidth', 3);
    % And now copy the endpoint to the startpoint so the cycle can be repeated
    x0 = x1;
    y0 = y1;
end
% Final line connecting initial clicked point and most recent clicked point
line([xfirst x1],[yfirst y1], 'Parent', axh, 'Color', 'w', 'LineWidth', 3);

% Now prompt the user to give a string label to be added to the figure.
labelStr = input('Annotation label? ', 's'); % Note second argument 's'
                                            % keeps input as string
% Add this annotation to the image
annotationh = text( xfirst, yfirst-10, labelStr, 'Color', 'w', ...
    'VerticalAlignment', 'bottom', 'FontSize', 14);


%% ***********************************************************************
%                              uiputfile 
% ************************************************************************
% Provides a GUI for choosing the directory and name to save a file.
% We ill use it to save this new image.
fprintf('Now save your modified image')
[saveName, savePath] = uiputfile('*.tif', 'Choose where to save image');
% Now do the save
saveas( figh, [savePath saveName], 'tif' )

