% Query the file
% Query user as to which image to load
fprintf('Running Cell Counting Tool...\n')



%% ***********************************************************************
%             Select an image to load and load it
% ***********************************************************************
% I use uigetfile to let user select which file to edit.
% The first argument are filter options, second is the dialog box text
[fname, pathname] = uigetfile({'*.jpg'}, 'Select image to process');

% Load the image
if ~fname % user cancelled
    fprintf('User aborted\n')
    return % ends this script or functon
else
    [imdata, cmap] = imread( [pathname fname] );% Can actually use imread without specifying format
                                                % and MATLAB will usually figure it out. The better
                                                % way would be to parse fname for the file extension
                                                % and use that as the format input to imread( ).
    fprintf( 'Loaded file %s from %s\n', fname, pathname);
    fprintf( 'Image is %ix%i pixels with %i color channels\n', size( imdata, 1 ), size( imdata, 2), size( imdata, 3) )
end

% Draw the original image in the left subplot
figh = figure('Name', 'Cell Counting Tool');
ax1h = subplot(1,2,1);
im1h = image( imdata, 'Parent', ax1h );
axis square
title(ax1h,'Original image', 'FontSize', 16)
xlabel('x (\mum)', 'Parent', ax1h, 'FontSize', 12 )
ylabel('y (\mum)', 'Parent', ax1h, 'FontSize', 12)


%% ***********************************************************************
%                      Ask which color channel to look at  
% ***********************************************************************
% I use menu to display buttons that the user can click to choose a channel.
% First argument is the prompt string, the rest are options. The output is 
% an integer specifying the index of which choice was selected 
% (1==RED, 2 == GREEN, 3 == BLUE)
userChoice = menu( 'Which color channel to isolate?', 'RED', 'GREEN', 'BLUE');


% Create rowx * cols * 3 zero matrix called monochrome, in which we will
% fill one channel with data from the image
monochrome = uint8( zeros( size( imdata ) ) ); % Note typecast to unsigned 8-bit integer;
                                               % these images are 8-bit

switch userChoice
    case 1 % RED
        monochrome(:,:,1) = imdata(:,:,1); % Grab the red channel; leave others as all zeros
        choiceStr = 'R';
    case 2 % GREEN
        monochrome(:,:,2) = imdata(:,:,2);
        choiceStr = 'G';
    case 3 % BLUE
        monochrome(:,:,3) = imdata(:,:,3);
        choiceStr = 'B';
    otherwise
        fprintf('User aborted\n')
        return % ends this script or functon
end
fprintf( 'Zeroing all but %s intensities\n', choiceStr )

% Display the isolated channel
ax2h = subplot(1,2,2);
im2h = image( monochrome, 'Parent', ax2h);
axis square
colormap( ax2h, gray(256) ) % Use grayscale colormap
title( ax2h, sprintf('%s Intensity', choiceStr), 'FontSize', 16 )
xlabel( 'x (\mum) ', 'Parent', ax2h, 'FontSize', 12 )
ylabel( 'y (\mum) ', 'Parent', ax2h, 'FontSize', 12 )
hold on; % will prevent axes from being deleted each time
         % we update the image.

%% ***********************************************************************
%                    Allow repeated change of image intensity
% ***********************************************************************
keepGoing = true; % This will be used to control the while loop.
while keepGoing
    % Use inputdlg to let user enter their threshold choice in a popup box
    % If user hits cancel, an empty cell is returned to myThresh
    myThresh = inputdlg('Enter Threshold intensity. Hit Cancel when satisfied'); 
    if isempty( myThresh ) 
        keepGoing = false; % User is satisfied; loop will end after this run-through
    else
        myThresh = str2num( myThresh{1} ); % Remember that inputdlg returns strings, but I want a number
        thresholded = monochrome; % always start from the original; if I change monochrome I might
                                  % not be able to undo changes if I don't like them.
        thresholded( thresholded < myThresh ) = 0; % Applies the threshold
        % Display this new image
        delete(im2h); % You don't really need to do this, but it's good practice.
        im2h = image( thresholded, 'Parent', ax2h);
        axis square
        title(ax2h, sprintf('%s Intensity, Thresh = %.1f', choiceStr, myThresh), 'FontSize', 16)
    end
end %while keepGoing

%% ***********************************************************************
%                    User clicks to label the cells they like
% ***********************************************************************
% Now let the user go in and click on all of the cells they like. Will use this
% to populate a list of cells, and their location.
fprintf('Now manually left click on those cells which you want counted in the right pane\n') 
fprintf('Hit any other key to finish\n') 
% Initialize the <cells> structure that I'll be adding to with each click.
cells.x = []; 
cells.y = [];

keepGoing = true;
numCells = 0; % will be used to keep track of how many cells were clicked.
while keepGoing
    [x, y, key] = ginput( 1 ); % get 1 click's worth of data
    if key == 1
        cells.x(end+1) = x;
        cells.y(end+1) = y;
        numCells = numCells + 1;
        
        % Let user know what they selected:
        fprintf('   Cell %i selected at x=%.2fum, y=%.2fum\n', numCells, x, y);
        
        % Add a number next to this cell in the image to identify it as having been
        % selected.
        texth = text(x,y, mat2str( numCells), 'FontSize', 14, 'Color', [1 1 0], ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    else % any other key means user wants to stop    
        keepGoing = false;
    end
    
end % while keepGoing

fprintf('Counting complete. %i Cells Counted.\n', numCells )
pause(0.5); % Just for a nicer user interface feel, really

%% ***********************************************************************
%           User selects where to save the .txt file and image
% ***********************************************************************
% We will make a .txt file with all of these cells' information using the provided
% writeCountsFile.m function.
fprintf('Program will now offer to save selected cells'' positions to a .txt file\n')
[saveName, savePath] = uiputfile('*.txt', 'Specify name of a .txt file which will store cell counting data');
if ~saveName
    fprintf('  User chose not to save cell positions .txt file\n')
else % saveName was provided, go ahead and save
    writeCountsFile( cells, [savePath saveName])
    fprintf('  File %s saved to %s\n', saveName, savePath);
end


% Now save the appearance of the tool (the figure)
fprintf('Program will now offer to save a figure showing original and thresholded/counted images\n')
[saveName, savePath] = uiputfile('*.fig', 'Choose where to save this figure');
if ~saveName
    fprintf('  User chose not to save an image of the current tool state\n')
else % Go ahead and save
    saveas( figh, [savePath saveName], 'fig' )
    fprintf('  File %s saved to %s\n', saveName, savePath);
end


fprintf('Program Terminated.\n\n')
