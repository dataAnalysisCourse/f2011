% plotSTA.m
%
% USAGE:
%       [figh] = plotSTA( STA, tau, numSpikes )
%
% INPUTS:
%       STA:         Spike triggered average stimulus value 
% INPUTS: 
%       STA          vector of the average stimulus (assumes stimulus is scalar)
%                    preceding a spike. The length of STA is determined by 
%                    input vector <tau>. Each element i of STA corresponds to the
%                    average stimulus value tau(i) seconds preceding a spikle
%       tau          vector of tau; without it you wouldn't know what delay
%                    each element of STA. Units should be ms
%       numSpikes    How many spikes were averaged to generate this STA. Will be
%                    displayed in figure.
% OUTPUTS:
%       
% Created by Sergey Stavisky on 18 November 2011
% Last modified by Sergey Stavisky on 18 November 2011
function figh = plotSTA( STA, tau, numSpikes )

    figh = figure('Name', 'STA'); 
    axh = axes( 'Parent', figh );
    linesh = plot( tau, STA , 'Parent', axh );
    % Reverse x limits so that time 0 is on right side
    set( axh, 'XDir', 'reverse', 'FontSize', 12 )

    % Make plot prettier
    set( linesh, 'LineWidth', 3, 'Color', 'k' ) %Thicker line
    line( get(axh, 'XLim'), [0 0], 'LineStyle', ':', 'Color', [.5 .5 .5], ...
        'LineWidth', 1 );% show zero line
    
    % Labels
    xlabel('\tau (ms before spike)', 'FontSize', 16)
    ylabel('Average Stimulus Intensity (AU)', 'FontSize', 16)
    titlestr{1} = 'Spike-Triggered Average Stimulus';
    titlestr{2} = sprintf('(averaged over %i spikes)',numSpikes );
    title( titlestr, 'FontSize', 18, 'FontWeight', 'bold' );
    
end %function