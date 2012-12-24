% photoDemo.m
% NENS 230 Autumn 2011, Stanford University
%
% This demo demonstrates importing a photograph in .jpg format and 
% manipulating the resulting three-dimensional matrix to change the
% red, blue, and green color channels.

%% ****************************************************************
%                        Loading an image
%  ****************************************************************
% Load in the image using imread function
photoFilename = 'SamplePhoto';
[imdat, cmap] = imread( photoFilename, 'jpg'); % Note that jpg format comes in RGB 0-255, so cmpa is meaningless
size( imdat )  % pixelRow x pixelCol x RGB matrix
size( cmap ) % doesn't exist for jpg

% Let's take a look at this photo
figh = figure;
axh = axes( 'Parent', figh );
imh = image( imdat );

axis square
% Note that when given a 3-dimensional matrix input (with RGB channel)
% the colormap is ignored. Thus, image and imagesc do the same thing. 
% Yes, this is weird.
delete( imh );
imh = imagesc( imdat ); 
axis square

%% ****************************************************************
%                   Working with each color channel
%  ****************************************************************
% Let's look at each channel separately
R = imdat(:,:,1);
figure; imagesc( R ); % note that since this is just a 2D matrix, imagesc( )
                      % and image( ) are once again different

colormap( gray ) % counterintuitive to look at intensity of red channel in color

% Can also look at Green and Blue channels.
G = imdat(:,:,2);
B = imdat(:,:,3);

% Plot Red
figRh = figure('Name', 'RED');
axRh = axes( 'Parent', figRh );
imagesc( R, 'Parent', axRh );
axis square
colormap( axRh, gray )

% Plot Green
figGh = figure('Name', 'GREEN');
axGh = axes( 'Parent', figGh );
imagesc( G, 'Parent', axGh );
axis square
colormap( axGh, gray )

% Plot Blue
figBh = figure('Name', 'BLUE');
axBh = axes( 'Parent', figBh );
imagesc( B, 'Parent', axBh );
axis square
colormap( axBh, gray )

% Let's make colormaps that makes it easy to see what these three channels
% mean
redCmap = zeros(50,3);
redCmap(:,1) = 0 : 1/49: 1;
colormap( axRh, redCmap )

greenCmap = zeros(50,3);
greenCmap(:,2) = 0 : 1/49 : 1;
colormap( axGh, greenCmap )

blueCmap = zeros(50,3);
blueCmap(:,3) = 0 : 1/49 : 1;
colormap( axBh, blueCmap )

% We can do some image processing. Let's say we want to tint the whole
% photograph red:
R = R + 50;
R(R>255) = 255;
imagesc( R, 'Parent', axRh )

% Put together a new image 3D matrix using the cat (concatenate) function
newImage = cat( 3, R, G, B ); % first argument specifies dimension to concatenate
size(newImage)  
% Let's look at this new image:
figure; image( newImage )

%% ****************************************************************
%                   Working within a region of the image
%  ****************************************************************
% Let's say Dan fails quals and we need to erase all memory of him:
newImage = imdat;
newImage( 6:96, 227:305, :) = 0; 
figure; image( newImage )
% Just kidding Dan, you're gonna rock it! -SDS


