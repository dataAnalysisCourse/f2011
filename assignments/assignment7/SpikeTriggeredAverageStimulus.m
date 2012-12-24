% SpikeTriggeredAverageStimulus.m
%
% Computes the spike-triggered average (STA) stimulus preceding an action 
% potential from a recorded neuron. You provide a vector of spike
% times and a recording of the stimulus intensity. The user can specify the taus
% that will be sampled. Returns a vector <STA> which is the average stimulus intensity
% at time <tau> preceding a spike of this cell.
%   For example, if the stimulus recording gave the brightness value of a full
% field illumination of a retina, and the spike times are the recorded spikes
% of a retinal ganglion cell (RGC) when exposed to this stimulus, and <tau>
% is [1 10 100] then  STA would be a length 3 vector where the elements represent 
% the average stimulus brightness 1, 10, and 100 ms before this RGC spikes.
% In effect, the STA is an estimate of the response function of the RGC,
% i.e. what kind of stimulus pattern most likely evokes a spike from the neuron.
%
%
% NOTE: spikeTimes and stim.t should be in the same units (ms)
% and coordinated; thus, if stim.t times go from 0 to 1e5 ms (100 seconds)
% then spikeTimes should also be in ms and a spikeTime of 0 would correspond 
% to a spike at the very start of the stimulus. 
%
% Created by Sergey Stavisky on 8 November 2011
% Last modified by Sergey Stavisky on 20 November 2011



function [STA C tau] = SpikeTriggeredAverageStimulus( spikeTimesFile, stimFile, tau, ignoreFirstNms )
% Load and confirm the spike times
load( spikeTimesFile )
if ~exist( 'spikeTimes', 'var' )
    error('waaah!')
end
% Load and confirm the stimulus
load( stimFile )
if ~exist( 'stim', 'var' )
    error('WAAAAH!')
end

% INSTRUCTOR COMMENT:
%  YOU DO NOT NEED TO IMPROVE THIS FUNCTION; IT'S JUST TO SHOW
%  YOU WHAT THE RAW DATA LOOK LIKE
plotStimAndSpikes( spikeTimes, stim );
% END OF INSTRUCTOR COMMENT

% take care of the beginning of the data
if ignoreFirstNms > max( tau )
spikeTimes( spikeTimes < ignoreFirstNms ) = [];
end
if max( tau ) > ignoreFirstNms
spikeTimes( spikeTimes < max( tau ) ) = [];
end
C = 0; % keeps track of usable spikes.
for i = 1 : length( spikeTimes )
st = spikeTimes(i); % my spike time
% Make sure we actually have stimulus preceding this spike all the way to
% tau(1) beforhand
if max( stim.t ) >= st - tau(1)
% Ok great this spike can be analyzed
C = C + 1
% tau loop
for j = 1 : length( tau )
    T = find( stim.t == st - tau(j) );
    STA(C, j) = stim.intensity(T);
end
end
end
STA = mean( STA, 1 );







% figure time
figh = figure('Name', 'STA');
axh = axes( 'Parent', figh );
linesh = plot( tau, STA , 'Parent', axh );
set( axh, 'XDir', 'reverse', 'FontSize', 12 )
set( linesh, 'LineWidth', 3, 'Color', 'k' )
line( get(axh, 'XLim'), [0 0], 'LineStyle', ':', 'Color', [.5 .5 .5], 'LineWidth', 1 );
xlabel('\tau (ms before spike)', 'FontSize', 16)
ylabel('Average Stimulus Intensity (AU)', 'FontSize', 16)
titlestr{1} = 'Spike-Triggered Average Stimulus';
titlestr{2} = sprintf('(averaged over %i spikes)', C );
title( titlestr, 'FontSize', 18, 'FontWeight', 'bold' );
end