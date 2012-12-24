% plotWithVarianceClouds.m
%
% General-purpose plotting function with option for variance clouds
%
% USAGE: 
% INPUTS:
%    meanWave      vector of  T samples containing the mean waveforms 
%                  to be plotted. Can also be a cell array for multiple 
%                  waveforms.
%    (stdWavestd)  (optional) vector of T samples containing the std at each time point.
%                  If provided, std clouds will be plotted.
%                  Can also be a cell array              
%    (axish)       (optional) if and axis handle is provided, this trial is
%                  plotted in it. Otherwise, a new axis is created.
%    (color)       (optional) Will plot the waveform in the specified color. Can be a Nx3 matrix if
%                  multiple mean lines are being input as argument
%    (times)       (optional) will provide alternate numbering to the x-axis. Must be 
%                   of same length as samples in <waveforms>. 
%                  Can be cell array.
%    (name)        (optional) Can name the resulting line; makes legends more meaningful
%                  Can be cell array.
%    
% OUTPUTS:
%    axish    handle of axis where this trial's kinematics are plotted.
% Sergey Stavisky May 13, 2011


function axish = plotWithVarianceClouds( meanWave, stdWave, axish, color, times, name )
    %% ********************************************************************************
    %                               PROPERTIES
    % *********************************************************************************
    transparency = 0.75; % how transparent the cloud will look
    
    
    %% ********************************************************************************
    %                              INPUT PROCESSING
    % *********************************************************************************
    % This part is long to allow a lot of flexibility in the optional arguments
    
    % Note: to make it easier to accomodate both cell array and single vector inputs, I'll 
    % take all non-cell inputs and put them into cells. Then a single syntax will work throughout.
    if ~iscell( meanWave )
        meanWave = {meanWave};
    end 
    numWaves = length( meanWave );
    % force meanWave to be a row vector
    for i = 1 : numWaves
        if size(meanWave{i},1) ~= 1
            meanWave{i} = meanWave{i}';
        end
    end
    
    if nargin < 2
        stdWave = [];
    end

    % CREATE THE AXIS IF NECESSARY
    % If user doesn't provide an axis handle, a figure and axis handle is 
    % created.
    if nargin < 3 || isempty( axish ) 
        axish = axes( 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1] );
        figh = get( axish, 'Parent' );
        set( figh, 'Color', [.5 .5 .5]); % makes the white axes easier to read.
    end
    
    % Allows user to set colors of each line
    if nargin < 4 || isempty( color )
        color = colormap( jet( numWaves ) );
    end
    
    %
    if nargin < 5 || isempty( times )
        for i = 1 : numWaves
            times{i} = 1 : length( meanWave{i} );
        end
    else
        if ~iscell( times )
            times = {times};
        end
        for i = 1 : numWaves
            if length( times{i} ) ~= size( meanWave{i}, 2 )
                error('[%s] <times> argument provided was of length %i, but <mean> has %i samples.', ...
                    mfilename, length( times{i} ), length( meanWave{i} ) )
            end
        end
    end %if nargin < 5 || isempty( times )
    
    if nargin < 6 || isempty( name )
        for i = 1 : numWaves
            name{i} = [];
        end
    else
        if ~iscell( name )
            name = {name};
        end
    end
    
    if nargin >= 2 && ~isempty( stdWave )
        if ~iscell( stdWave)
            stdWave = {stdWave};
        end
        
        for i = 1 : numWaves
            if length( stdWave{i} ) ~= length( meanWave{i} )
                error('[%s] <mean> argument provided has %i samples, but <std> has %i samples.', ...
                    mfilename, length( meanWave{i} ), length( stdWave{i} ) )
            else
                % ensure that stdWave is a row vector
                if size(stdWave{i},1) ~= 1
                    stdWave{i} = stdWave{i}';
                end
            end
        end
    end
    
    %% ********************************************************************************
    %                     Set X-Limits based on min/max across all plots
    % *********************************************************************************
    % Find the min/max times
    minT = inf;
    maxT = -inf;
    for i = 1 : numWaves
        minT = min( minT, times{i}(1) );
        maxT = max( maxT, times{i}(end) );
    end
    xlim( [minT, maxT] )
    
    %% ********************************************************************************
    %                             Draw Variance/Error Cloud
    % *********************************************************************************
    hold on
    if ~isempty( stdWave )
        for i = 1 : numWaves
            % I need to create the cloud as a polygon; compute the vertices here
            X = [times{i} fliplr( times{i} )];
            Y = [(meanWave{i} + stdWave{i}) fliplr( meanWave{i} - stdWave{i} )];
            
%             % FOR IN-CLASS EXAMPLE:
            for iVertex = 1 : length(X)
                text(X(iVertex),Y(iVertex), mat2str(iVertex), 'Color', 'w')
            end %for iVertex = 1 : length(X)
%             End in-class example
            
            % And here is the key part
            patchh = patch(X,Y,color(i,:), 'FaceAlpha', (1-transparency), 'LineStyle', 'none' );
        end
    end
        
    %% ********************************************************************************
    %                              Draw the Solid Plot Lines
    % *********************************************************************************
    % For some reason the patches still occlude the lines even though lines are plotted second, so I use a 
    % trick; I give the mean waveforms a slightly elevated z coordinate
    for i = 1 : numWaves
        myZ = ones( 1, length(meanWave{i}) ); % give every x,y point a z value of 1.
        plot3( times{i}, meanWave{i}, myZ, 'Color', color(i,:), 'LineWidth', 3, 'DisplayName', name{i})
    end
    pause(0.010); % sometimes helps with weird axis issues
    
    %% ********************************************************************************
    %                              Pretty up the figure
    % *********************************************************************************
    % Make the figure bigger
    figh = get( axish, 'Parent' );
    set( figh, 'Position', [118 107 1540 804] )

    
    % LEGEND FOR THIS LINE
    if ~isempty( name{1} )
        legh = legend(name);
        set( legh, 'TextColor', [1 1 1] );
    end
    
    
    


end %function 