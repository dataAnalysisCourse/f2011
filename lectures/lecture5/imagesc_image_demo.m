% imagesc_image_demo.m
% NENS 230 Autumn 2011, Stanford University
%
% This demo demonstrates the basics of visualizing a matrix using
% the imagesc( ) and image( ) functions, as well as the concept of a colormap


%% *******************************************************************
%                                 imagesc
% *******************************************************************
% Let's build a matrix
M = [ 1  2  3  4  5  6 ;
      7  8  9  10 11 12;
      13 14 15 16 17 18;
      19 20 21 22 23 24;
      25 26 27 28 29 30; 
      31 32 33 34 35 36; 
       0  8 15 22 29 36]
  
% The most common way to visualize the contents of a matrix looks like 
% is using imagesc
h = imagesc( M ) ; % note I'm being sloppy and not keeping track of figure
                   % and axis object handle
axh = get( h, 'Parent');
% Add a colorbar to see what each color represents
cbarh = colorbar( 'peer', axh ); % colorbar is a child of the axis, not the image object

%% *******************************************************************
%                                Colormaps
% *******************************************************************
% Can play with colormaps in figure window -> Edit -> Colormap
% Programatically show several colormaps
colormap( axh, 'bone')
colormap( axh, 'hot')
colormap( axh, 'cool')
colormap( axh, 'lines') % repeats colors!
colormap( axh, 'jet'); % Blue -> Red; Very popular

% Negative or decimal values are treated the same way
M = M -15.3
h = imagesc( M ); % no change, since scale is the same

% Note that imagesc scales colormap to full range of matrix
% values. This can cause a problem:
M(end,end) = 100
h = imagesc( M );

% undo this:
M = M + 15.3;
M(end, end) = 36;
colormap( axh, 'jet')
h = imagesc( M )

% We can load in a pre-built colormap and modify it.
myColormap = jet( 15 ) % the argument tells it how many different color 
                         % increments to include.
                         
colormap( axh, myColormap )   

% We probably want more fine-grained color gradations:
myColormap = jet( 256 );
size( myColormap )
colormap( axh, myColormap)

% Let's change the colormap to make our mininum value black:
myColormap(1,:) = [0 0 0];
colormap( axh, myColormap )

% We can also build our own colormap. Let's make one that goes
% from red to green:
myColormap = zeros(50,3)
myColormap(:,1) = 1: -1/49: 0; % Red decreases from 1 to 0
myColormap(:,2) = 0:  1/49: 1 % Green increases from 0 to 1
colormap( axh, myColormap )

%% *******************************************************************
%                                 image
% *******************************************************************%
h = image( M ); 
colorbar( 'peer', axh);
% Make this more obvious
A = [ 1 2 10:15 50];
h = image( A );
colorbar( 'peer', axh);
