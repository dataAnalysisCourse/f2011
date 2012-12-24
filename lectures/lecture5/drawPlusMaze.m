% Creates a figure containing a depiction of the Elevated Plus Maze, and 
% returns the figure handle.
% NENS 230 Autumn 2011, Stanford University
% Written by Sergey Stavisky on 22 October 2011

function figh = drawPlusMaze
    % Draw the figure
    figh = figure;
    
    axh = axes( 'Parent', figh, 'XLim', [-550 550], 'YLim', [-550 550], 'FontSize', 14 );
    axis(axh, 'square') % square projection
    xlabel( 'X Position (mm)', 'FontSize', 14)
    ylabel( 'Y Position (mm)', 'FontSize', 14)
    
    % Now draw thiner outline of the arms.
    % Here I demonstrate creating multiple lines in a single command using
    % matrix input.
    % Firt, let's define the endpoints
    % [X1 Y1 X2 Y2]
    vertices = ...
        [ 50   50   500   50   ;
        500  50   500  -50   ;
        500 -50   50   -50   ;
        50  -50   50   -500  ;
        50  -500  -50  -500  ;
        -50  -500  -50  -50   ;
        -50  -50   -500 -50   ;
        -500 -50   -500  50   ;
        -500  50   -50   50   ;
        -50   50   -50   500  ;
        -50   500   50   500  ;
        50   500   50   50  ];
    
    linehandles = line( [vertices(:,1) vertices(:,3)], [vertices(:,2) vertices(:,4)], ...
        'Parent', axh,  'Color', [.2 .2 .2], 'LineWidth', 1.5);
    
    % Now draw dark lines to represent the closed arms
    rightarm = ...
        [ 50   50   500   50   ;
        500  50   500  -50   ;
        500 -50   50   -50   ];
    leftarm = ...
        [-50  -50   -500 -50   ;
        -500 -50   -500  50   ;
        -500  50   -50   50   ];
    
    rightarmhandles = line( [rightarm(:,1) rightarm(:,3)], [rightarm(:,2) rightarm(:,4)], ...
        'Parent', axh,  'Color', 'k', 'LineWidth', 6);
    leftarmhandles = line( [leftarm(:,1) leftarm(:,3)], [leftarm(:,2) leftarm(:,4)], ...
        'Parent', axh,  'Color', 'k', 'LineWidth', 6);
    hold on; 
end %function