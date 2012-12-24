% spectrogramDemo.m
% NENS 230 Autumn 2011, Stanford University
%
% This demo demonstrates using imagesc to display a spectrogram showing power
% in various frequencies of the field potentials recorded from macaque M1 
% during a reaching movement.

% Load the spectrogram data. It was generated from .3-500Hz filtered local field potential
% data (sampled at 2kHz) using the open-source Chronux package (http://chronux.org/)
load specDat.mat
% Contents of specDat:
% S:      Power(freq). timeBin x freq
% f:      center of each frequency bin (in Hz)
% labelt: the time (relative to trial start) of each bin

% We want the spectrogram to be freq (rows) x time (cols), so we want to 
% visualize the transpose of S, i.e. S'.
figh = figure;
axh = axes( 'Parent', figh );
imh = imagesc( S', 'Parent', axh );

% Problem is evident: the values for lower frequency are so much higher 
% (recall that most neural data shows 1/f power curve) that it overwhelms
% the color range. So let's plot the logarithm of power instead:
delete( imh )
imh = imagesc( log(S)', 'Parent', axh ); % This looks better!

% However, we want the axis tick labels to be meaningful. Fortunately,
% we can call imagesc with x, y ticks specified as the first two arguments
delete( imh )
imh = imagesc( labelt, f, log10(S)', 'Parent', axh );

% We're getting there! However, a spectrogram typically has the frequency
% going from low (bottom) to high (top) so let's make the y axis direction
% normal (image and imagesc default to 'reverse' y axis)
get( axh, 'YDir')
set( axh, 'YDir', 'normal')

% Let's add a title and axis labels
xlabel('Time (s)', 'FontSize', 14)
ylabel('Frequency (Hz)', 'FontSize', 14)
title(axh, 'Spectrogram of LFP Power during Arm Reach   ', 'FontSize', 16)
% Let's add a colorbar 
cbarh = colorbar( 'peer', axh ); % colorbar is a child of the axis, not the image object
title(cbarh, '     log_{10}( Power ) (AU)', 'FontSize', 12) % leading spaces to avoid title

% The graphics object we've entitled imh exists in axh. We can add other
% things to axh. Let's make a vertical line to mark the trial start.
lineh = line([0 0], get(axh, 'YLim'), 'Parent', axh, 'Color', 'w', ...
    'LineWidth', 2);
