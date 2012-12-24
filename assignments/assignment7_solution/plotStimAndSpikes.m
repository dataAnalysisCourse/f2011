% plotStimAndSpikes.m
%
% NENS 230 Autumn 2011
% Called by SpikeTriggeredAverageStimulus.m to create a figure showing the 
% visual stimulus projected onto the retina, with marks to denote when the spikes
% happened.
%
% USAGE:
%       figh = plotStimAndSpikes( spikeTimes, stim )
%
% INPUTS:
%       spikeTimes   Vector of time (in ms) of each spike.
%     
%       stim         structure containing a field .intensity
%                    which contains intensity of the stimulus at 
%                    corresponding time in the .t field.
% OUTPUTS:
%       figh         Figure handle of resulting figure.
%       
% Created by Sergey Stavisky on 18 November 2011
% Last modified by Sergey Stavisky on 18 November 2011

function figh = plotStimAndSpikes( spikeTimes, stim )
    % Figure out the axes; do this based on 
    minT = min( [spikeTimes ; stim.t] );
    maxT = max( [spikeTimes ; stim.t] );
    % set y limits based on maximum value of stimulus intensity
    yMax = max( stim.intensity );
    yMin = min( stim.intensity );
    yAbsMax = ceil( max( abs( [yMax yMin] ) ) );
    
    % Generate figure and axes. Note that I don't plot the whole time series
    % or it is too compressed. It still benefits from zooming in with the plot
    % tools.
    figh = figure( 'Name', 'Unprocessed Stimulus and Spike Times', ...
        'Position', [50 50 1400 450]);
    axh = axes( 'Parent', figh, 'FontSize', 12, 'XLim', [minT 12e4], ...
        'YLim', [-yAbsMax yAbsMax]  );
    hold on
    
    % Plot stimulus intensity
    stimh = plot( stim.t, stim.intensity, 'Color', 'r', 'LineWidth', .5, 'Parent', axh );
    
    % Plot spikes with vertical lines
    linesh = line( [spikeTimes spikeTimes], [yAbsMax-1 yAbsMax], 'Color', 'k', 'LineWidth', 1 );

    % Labels
    xlabel('Time (ms)', 'FontSize', 16)
    ylabel('Stimulus (AU)', 'FontSize', 16)
    titlestr = 'Stimulus and Evoked Spikes';
    title( titlestr, 'FontSize', 18, 'FontWeight', 'bold' );    
end