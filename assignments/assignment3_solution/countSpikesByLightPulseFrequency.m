 function [nSpikesEvoked pulseFrequencyHz] = ...
     countSpikesByLightPulseFrequency(abfname)
% [nSpikesEvoked pulseFrequencyHz] = countSpikesByLightPulseFrequency(abfname)
% Computes a frequency tracking curve for an light-sensitized neuron
% recorded in current clamp under periodic optical stimulation.
%
% This function accepts an .abf file name compatible with the abf2load
% utility that contains current clamp recordings (channel 1: membrane voltage)
% along with a laser activation signal (channel 2: laser state).
% Using a simple threshold, it detects how many action potentials the cell
% fires in a given sweep, then computes the light pulse frequency used on
% that sweep, and generates a plot of number of spikes evoked vs. light
% pulse frequency. It also generates a plot for each sweep in the file
% which shows visually where the detected spikes and laser pulses are
% located, allowing visual debugging of the detection algorithm.
%
% INPUTS:
% abfname - *.abf file name to be loaded by abfload()
%
% OUTPUTS:
% nSpikesEvoked - nSweeps x 1, how many spikes were evoked on a given sweep
% pulseFrequencyHz - nSweeps x 1, the laser pulse frequency used on a given sweep

% Parameters
vmThresh = 0; % membrane voltage threshold for spiking, in mV

 if(nargin < 1)
     error('Usage: countSpikesByLightPulseFrequency(abfname)');
 end


% Load the abf file
[abfData samplingIntervalUs abfInfo] = abfload(abfname);

% Dimension 1 of abfData is over time or sample number
% Dimension 2 of abfData is over channels
%     e.g. channel 1 is membrane voltage, channel 2 is laser signal
% Dimension 3 of abfData is over the traces or sweeps
%     in each sweep we have a different light pulse frequency

% Therefore, abfData(i,j,k) is the value of the signal at 
% sample number i, on channel j, in sweep k

nSamples  = size(abfData, 1);
nChannels = size(abfData, 2);
nSweeps   = size(abfData, 3);

% Generate a time vector for each sample
tvecMs = (1:nSamples) * samplingIntervalUs/1000;

% Extract the membrane voltage channel (1) and laser state channel (2)
chVm    = squeeze(abfData(:, 1, :));
chLaser = squeeze(abfData(:, 2, :));

% Preallocation for data by sweep
nSpikesEvoked =  zeros(nSweeps, 1);
pulseFrequencyHz = zeros(nSweeps, 1);

% Loop over sweeps
for iSweep = 1:nSweeps
    
    % Grab the traces for each sweep
    vmTrace = chVm(:, iSweep);
    laserTrace = chLaser(:,iSweep);
    
    % Now we want to figure out when the voltage trace goes above
    % threshold.
    vmTraceAboveThresh = vmTrace >= vmThresh;
    
    % Find threshold crossings by taking the first order difference of this
    % array. 1 is crossing from below, -1 is crossing from above.
    vmTraceThreshCrossings = diff(vmTraceAboveThresh);
    
    % Find crossings from below
    vmTraceThreshCrossingsUpward = find(vmTraceThreshCrossings == 1);
    
    % Count crossings from below
    nSpikesEvoked(iSweep) = length(vmTraceThreshCrossingsUpward);
    
    % Convert crossing indices into times
    spikeTimesMs = tvecMs(vmTraceThreshCrossingsUpward);
    
    % The laser channel alternates between low values when the laser is off and high values
    % when the laser is on. Therefore, we can set a threshold which is
    % halfway between the min and max values. 
    laserThresh = (max(laserTrace) + min(laserTrace)) / 2;

    % Use same approach to find threshold crossings from below on the laser
    % channel
    laserTraceAboveThresh = laserTrace >= laserThresh;
    laserTraceThreshCrossings = diff(laserTraceAboveThresh);
    laserTraceThreshCrossingsUpward = find(laserTraceThreshCrossings == 1);
    
    % And find the laser pulse onset times
    laserPulseTimesMs = tvecMs(laserTraceThreshCrossingsUpward);
    
    % Find the pulse frequency using the average interval
    % between successive laser pulses.
    laserPulseIntervalsMs = diff(laserPulseTimesMs);
    laserPulseIntervalMeanMs = mean(laserPulseIntervalsMs);
    pulseFrequencyHz(iSweep) = 1000 / laserPulseIntervalMeanMs;
    
    % Create a blank figure for this sweep, set its color to white
    figure(1);
    clf; set(gcf, 'Color', [1 1 1]);
    
    % Top axis: voltage trace
    subplot(2,1,1); 
    plot(tvecMs, vmTrace, 'b-');
    hold on
    
    % Plot a marker at each threshold crossing we've detected. Use vmThresh
    % as the y coordinate
    plot(spikeTimesMs, vmThresh * ones(size(spikeTimesMs)), 'rx', 'MarkerSize', 8);
    
    xlabel('Time (ms)');
    ylabel('Membrane Voltage (mV)');
    title(['Sweep ' num2str(iSweep)]);
    box off
    
    % Bottom axis: laser pulse signal.
    subplot(2,1,2);
    
    plot(tvecMs, laserTrace, 'b-');
    hold on
    
    % Plot a marker at each threshold crossing we've detected. Use laserThresh
    % as the y coordinate
    plot(laserPulseTimesMs, laserThresh * ones(size(laserPulseTimesMs)), 'rx', 'MarkerSize', 8);
    
    xlabel('Time (ms)');
    ylabel('Laser Signal (AU)');
    box off
end


% Make a summary figure which plots number of spikes evoked against
% the laser pulse frequency.

figure(2); clf; set(gcf, 'Color', [1 1 1]);
plot(pulseFrequencyHz, nSpikesEvoked, 'ko-', ...
    'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b', 'MarkerSize', 8);

xlabel('Light Pulse Frequency (Hz)');
ylabel('Spikes Evoked');
title('Light Frequency Tracking');
box off
