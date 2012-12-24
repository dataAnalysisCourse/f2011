 function [nSpikesEvoked pulseFrequencyHz] = ...
     countSpikesByLightPulseFrequency(abfname)
% [nSpikesEvoked pulseFrequencyHz] = countSpikesByLightPulseFrequency(abfname)
% Computes a frequency tracking curve for an light-sensitized neuron
% recorded in current clamp under periodic optical sclctimulation.
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

% Typically, it's a good idea to set specific parameters at the beginning
% of a function, so that they're easy to find and adjust later. We'll get
% to other ways of having optional parameters in the future, but this will
% suffice for now. You should also include a comment that explains what
% each parameter controls and if applicable, what units it is specified in.

% Parameters
vmThresh = 0; % membrane voltage threshold for spiking, in mV

% Load the abf file
[abfData samplingIntervalUs abfInfo] = abfload(abfname);

% abfData is returned to us as a 3-dimensional array.
% You can check this by running:
% ndims(abfData)

% Dimension 1 of abfData is over time or sample number
% Dimension 2 of abfData is over channels
%     e.g. channel 1 is membrane voltage, channel 2 is laser signal
% Dimension 3 of abfData is over the traces or sweeps
%     in each sweep we have a different light pulse frequency

% Therefore, abfData(i,j,k) is the value of the signal at 
% sample number i, on channel j, in sweep k

% The sizes along each of these dimensions represents the number 
% of samples, channels, and sweeps in this file. Use the size command
% with two arguments, the first being abfData, the second being the 
% dimension you'd like to know the size along. Use this to get the number
% of samples, channels, and sweeps in this recording.

nSamples  = size(???, ???);
nChannels = size(???, ???);
nSweeps   = size(???, ???);

% The time elapsed at sample number i can be computed by multiplying 
% i by samplingIntervalUs and dividing by 1000 to convert 
% to milliseconds. 

% Generate a time vector tvec such that tvecMs(i) represents the time
% into a given sweep that sample i was taken (in ms). Use colon notation to
% generate a list of sample numbers, e.g. 1:nSamples, then multiply this
% by samplingIntervalUs/1000

tvecMs = ???

% Separate each channel into it's own 2 dimensional array. Channel 1 is the
% recorded membrane voltage channel, and channel 2 is the recorded laser
% signal, i.e. it's high when the laser is on, low when the laser is off.
% Use multidimensional indexing to grab all the samples and all the sweeps
% for a given channel. Remember we want all of dimension 1 (the samples),
% only one element along dimension 2 (either 1 or 2, depending on which channel
% we're grabbing), and all of dimension 3 (the sweeps).
% 
% Then use the squeeze command to squash this into a nice 2d array that
% has size [nSamples nSweeps]. Do this for channel 1 to create chVm, and
% for channel 2 to create chLaser.

chVm    = ???
chLaser = ???

% Now we want to loop over all the sweeps, and for each sweep,
% we figure out what the laser pulse frequency is and 
% how many spikes we observe. While we're looping over the sweeps,
% we need a place to store these values.

% Initialize arrays of size nSweeps x 1 to hold the number of spikes evoked
% in each sweep (nSpikesEvoked) and the laser pulse frequency
% (pulseFrequencyHz)

nSpikesEvoked =  ???
pulseFrequencyHz = ???

% Now we loop over all the sweeps.

for iSweep = 1:nSweeps
    
    % Now we want to grab the membrane voltage trace for this frequency. 
    % Remember that chVm(i,j) is the ith sample for sweep j. We want to
    % grab all samples for sweep iSweep.
    
    vmTrace = ???
    laserTrace = ???
    
    % if you wanted to double check what these look like, you could call
    % plot(tvecMs, vmTrace) or plot(tvecMs, laserTrace);
    
    % Now we want to figure out when the voltage trace goes above
    % threshold. Use a conditional operator to generate a logical array
    % which is 1 when vmTrace is >= vmThresh, and 0 otherwise
    
    vmTraceAboveThresh = ???
    
    % Then take the 1st order difference of this vector using the diff
    % function. This creates an array which is 1 at points where the
    % membrane voltage crosses the threshold from below, -1 at points where
    % the membrane voltage crosses the threshold from above, and 0
    % everywhere else.
    
    vmTraceThreshCrossings = ???
    
    % Use the find function to get a list of indices where this 1st order
    % difference vector is equal to 1, i.e. the indices where vmTrace
    % crosses the threshold from below.
    
    vmTraceThreshCrossingsUpward = ???
    
    % Use length to determine how many threshold crossings from below there
    % are. Store this value in the nSpikesEvokedArray at index iSweep.
    
    nSpikesEvoked(iSweep) = ???
    
    % For the sake of verifying visually that we're detecting spikes
    % correctly, we'll want to plot the membrane trace and annotate it by
    % placing markers at the points where we think the cell spiked. In
    % order to do this, we need to know what time the threshold crossings
    % happened at. Use vmTraceThreshCrossingsUpward to index into the time
    % vector tvecMs to get a list of spikeTimesMs
    
    spikeTimesMs = ???
    
    % Now we find all the laser pulse onset times. The laser channel
    % alternates between low values when the laser is off and high values
    % when the laser is on. Therefore, we can set a threshold which is
    % halfway between the low and high values. Use the max and min
    % functions on laserTrace to find these extrema, then average them
    % together to get the laser threshold to use.
    
    laserThresh = ???
    
    % Repeat the steps you took to find the upward threshold crossings for
    % chVm except use chLaser and laserThresh as the threshold. Be careful
    % when copying and pasting!
    
    laserTraceAboveThresh = ???
    laserTraceThreshCrossings = ???
    laserTraceThreshCrossingsUpward = ???
    
    % And just as we did with the chVm threshold crossings, index into
    % tvecMs to find the laser pulse onset times in ms.
    
    laserPulseTimesMs = ???
    
    % Now to find the pulse frequency, we first find the average interval
    % between successive laser pulses. First use diff to calculate the
    % intervals between successive pulses.
    
    laserPulseIntervalsMs = ???
    
    % Then use mean() to take the average
    
    laserPulseIntervalMeanMs = ???
    
    % And divide this into 1000 ms to get the frequency in Hz
    % Store this frequency in our pulseFrequencyHz array at index iSweep
    
    pulseFrequencyHz(iSweep) = ???
    
    % Create a blank figure for this sweep, set its color to white
    figure(iSweep);
    clf; set(gcf, 'Color', [1 1 1]);
    
    % Create two separate axes (or subplots) on this figure, one above the
    % other. Set the top axis as current.
    % (first arg is number of axes vertically, 
    %  second arg is number of axes horizontally,
    %  third arg is which axis you'd like to select)
    
    subplot(2,1,1); 
    
    % Plot the membrane voltage on this axis, use tvecMs as the x-axis
    % coordinates, and vmTrace as the y axis coordinates
    
    plot(???, ???, 'b-');
    
    % Turn hold on so that we can plot on top of this trace without
    % clearing it
    hold on
    
    % Now plot a marker at each threshold crossing we've detected. Again
    % the x coordinates are the times in ms at which we detected spikes,
    % and for the y coordinates, let's put each marker at vmThresh. In
    % order to do this, we need to create a vector the same size as
    % spikeTimesMs that has all of its values set to vmThresh. Use
    % ones(size(spikeTimesMs)) to create a vector of ones of the right size
    % and multiply this by vmThresh to have each value equal vmThresh
    
    plot(???, ???, 'rx', 'MarkerSize', 8);
    
    % Label our axes
    xlabel('Time (ms)');
    ylabel('Membrane Voltage (mV)');
    
    % Give it a title that indicates which sweep this is. 
    % We'll discuss what's going on here next week
    title(['Sweep ' num2str(iSweep)]);
    
    % Turn off the outer box, it's annoying
    box off
    
    % Now we switch to the bottom axis so that we can do the same for the
    % laser pulse signal.
    subplot(2,1,2);
    
    % Plot the laser trace on this axis, use tvecMs as the x-axis
    % coordinates, and laserTrace as the y axis coordinates
    
    plot(???, ???, 'b-');
    
    % Turn hold on on this axis so that we can plot on top of this 
    % trace without clearing it
    
    hold on
    
    % Now plot a marker at each threshold crossing we've detected. Again
    % the x coordinates are the times in ms at which we detected pulses,
    % and for the y coordinates, let's put each marker at laserThresh. In
    % order to do this, we need to create a vector the same size as
    % laserPulse that has all of its values set to vmThresh. Use
    % ones(size(spikeTimes)) to create a vector of ones of the right size and
    % multiply this by vmThresh to have each value equal vmThresh
    
    plot(???, ???, 'rx', 'MarkerSize', 8);
    
    % Label our axes
    xlabel('Time (ms)');
    ylabel('Laser Signal (AU)');
    
    % Turn off the outer box, it's annoying
    box off
end

% Now we make a summary figure which plots number of spikes evoked against
% the laser pulse frequency. Create a blank figure for this.

figure; clf; set(gcf, 'Color', [1 1 1]);

% Now plot nSpikesEvoked against pulseFrequencyHz
% The additional arguments at the end say to use a blank (k) solid line (-)
% with circular markers (o) at the data points, make these markers blue (b)
% and of size 8
plot(???, ???, 'ko-', ...
    'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b', 'MarkerSize', 8);

% Label our axes
xlabel('Light Pulse Frequency (Hz)');
ylabel('Spikes Evoked');
title('Light Frequency Tracking');

% Hide the outer box, it's annoying
box off

% Now we're done, and if you look at the first line of this function, you
% can see that we've specified nSpikesEvoked and pulseFrequencyHz as our
% output arguments, which means that when you call this function like this:
% [nSpikesEvoked pulseFrequencyHz] = countSpikesByLightPulseFrequency('something.abf');
%
% You'll get whatever we've assigned into nSpikesEvoked and
% pulseFrequencyHz assigned into the variables you've specified.
