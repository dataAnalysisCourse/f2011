% spikeFieldCoherenceEx.m
% NENS230 Autumn 2011
% Demonstrates using Chronux to look at spike-LFP coherence and infer underlying
% relationships between the spikes and LFP. Uses synthetic data where we know
% this relationship to better make the point.

% Chronux must be on path
addpath( genpath( '/Users/sstavisk/Dropbox/NENS230_private/MATLAB/chronux' ) ) 


%% Spikes follow 25Hz signal
% Create 10 seconds of synthetic LFP and spike data. 
% In this case spikes tend to follow the 25Hz signal

Fs = 1000; % Sampling frequency is 1000 Hz
duration = 10; 
scale = 60; % gets the signal into approximately the range of actual LFP (-100 to 100 uV)

t = (0 : 1/Fs : duration)';
numSamples = numel( t );

f1 = 25; % 25 Hz signal
f2 = 4;  % 4 Hz signal
f3 = 40; % 40Hz signal
signalOfInterest = scale * sin(f1 * t * 2 * pi);

figure;


lfp = signalOfInterest + (scale/4)*sin(f2*t*2*pi) +  (scale/4)*sin(f3*t*2*pi) + ...
    10* randn( numSamples, 1 );
plot( t, lfp )

% Now let's generate some spike times
spikeTimes = synthesizeSpikeTrain( signalOfInterest./max(signalOfInterest), Fs, .6, 1 );

% Plot the spike times on the same plot
hold on; scatter( spikeTimes, lfp( round( spikeTimes*Fs ) ), 'Marker', 'v', ...
    'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k' )
xlabel('Time (s)', 'FontSize', 16)
ylabel('LFP (uV) and Spike Times', 'FontSize', 16)

% Now let's use Chronuz to calculate the spike-field coherence
% Will use coherencycpt
% Need to figure out tapers. If I want to use all the data, I have T = 10 s, W = 3 Hz
% so TW = 30 and K = 2TW-1 = 59
params.tapers = [30 59];
params.err = [2 .05];
params.Fs = Fs;
params.fpass = [0 100] ; % show results between 0 and 100 Hz
[C, phi, S12, S1, S2, f, zerosp, confC, phistd, Cerr] = coherencycpt( lfp, spikeTimes, params)	;

% Plot the coherence
plotCoherence( f, C, Cerr )

%% Random spikes
% Create 10 seconds of synthetic LFP and spike data. 
% In this case spikes tend to happen at random times throughout signal

Fs = 1000; % Sampling frequency is 1000 Hz
duration = 10; 
scale = 60; % gets the signal into approximately the range of actual LFP (-100 to 100 uV)

t = (0 : 1/Fs : duration)';
numSamples = numel( t );

f1 = 25; % 25 Hz signal
f2 = 4;  % 4 Hz signal
f3 = 40; % 40Hz signal
signalOfInterest = scale * sin(f1 * t * 2 * pi);

figure;


lfp = signalOfInterest + (scale/4)*sin(f2*t*2*pi) +  (scale/4)*sin(f3*t*2*pi) + ...
    10* randn( numSamples, 1 );
plot( t, lfp )

% Now let's generate some spike times
spikeTimes = synthesizeSpikeTrain( repmat(.5, numel(lfp),1) , Fs, .4, .1 );

% Plot the spike times on the same plot
hold on; scatter( spikeTimes, lfp( round( spikeTimes*Fs ) ), 'Marker', 'v', ...
    'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k' )
xlabel('Time (s)', 'FontSize', 16)
ylabel('LFP (uV) and Spike Times', 'FontSize', 16)

% Now let's use Chronuz to calculate the spike-field coherence
% Will use coherencycpt
% Need to figure out tapers. If I want to use all the data, I have T = 10 s, W = 3 Hz
% so TW = 30 and K = 2TW-1 = 59
params.tapers = [30 59];
params.err = [2 .05];
params.Fs = Fs;
params.fpass = [0 100] ; % show results between 0 and 100 Hz
[C, phi, S12, S1, S2, f, zerosp, confC, phistd, Cerr] = coherencycpt( lfp, spikeTimes, params)	;

% Plot the coherence
plotCoherence( f, C, Cerr )

%% Spikes tend to follow the 40Hz signal
% Create 10 seconds of synthetic LFP and spike data. 
% In this case spikes tend to happen when 40Hz signal is strongly NEGATIVE

Fs = 1000; % Sampling frequency is 1000 Hz
duration = 10; 
scale = 60; % gets the signal into approximately the range of actual LFP (-100 to 100 uV)

t = (0 : 1/Fs : duration)';
numSamples = numel( t );

f1 = 25; % 25 Hz signal
f2 = 4;  % 4 Hz signal
f3 = 40; % 40Hz signal
signalOfInterest = (scale/3)*sin(f3 * t * 2 * pi);

figure;


lfp = signalOfInterest + (scale/3)*sin(f2*t*2*pi) +  (scale/3)*sin(f1*t*2*pi) + ...
    10* randn( numSamples, 1 );
plot( t, lfp )
hold on;
plot( t, signalOfInterest, 'r') % Make it easier to see the 40Hz signal

% Now let's generate some spike times
spikeTimes = synthesizeSpikeTrain( -signalOfInterest./max(signalOfInterest), Fs, 0, .05 );

% Plot the spike times on the same plot
hold on; scatter( spikeTimes, lfp( round( spikeTimes*Fs ) ), 'Marker', 'v', ...
    'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k' )
xlabel('Time (s)', 'FontSize', 16)
ylabel('LFP (uV) and Spike Times', 'FontSize', 16)

% Now let's use Chronuz to calculate the spike-field coherence
% Will use coherencycpt
% Need to figure out tapers. If I want to use all the data, I have T = 10 s, W = 3 Hz
% so TW = 30 and K = 2TW-1 = 59
params.tapers = [30 59];
params.err = [2 .05];
params.Fs = Fs;
params.fpass = [0 100] ; % show results between 0 and 100 Hz
[C, phi, S12, S1, S2, f, zerosp, confC, phistd, Cerr] = coherencycpt( lfp, spikeTimes, params)	;

% Plot the coherence
plotCoherence( f, C, Cerr )

%% Spikes tend to follow the raw LFP signal
% Create 10 seconds of synthetic LFP and spike data. 
% In this case spikes tend to happen when LFP is higher

Fs = 1000; % Sampling frequency is 1000 Hz
duration = 10; 
scale = 60; % gets the signal into approximately the range of actual LFP (-100 to 100 uV)

t = (0 : 1/Fs : duration)';
numSamples = numel( t );

f1 = 25; % 25 Hz signal
f2 = 4;  % 4 Hz signal
f3 = 40; % 40Hz signal

figure;


lfp = (scale/3)*sin(f1*t*2*pi) + (scale/3)*sin(f2*t*2*pi) +  (scale/3)*sin(f3*t*2*pi) + ...
    10* randn( numSamples, 1 );
plot( t, lfp )

% Now let's generate some spike times
spikeTimes = synthesizeSpikeTrain( lfp./max(lfp), Fs, 0, .2 );

% Plot the spike times on the same plot
hold on; scatter( spikeTimes, lfp( round( spikeTimes*Fs ) ), 'Marker', 'v', ...
    'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k' )
xlabel('Time (s)', 'FontSize', 16)
ylabel('LFP (uV) and Spike Times', 'FontSize', 16)

% Now let's use Chronuz to calculate the spike-field coherence
% Will use coherencycpt
% Need to figure out tapers. If I want to use all the data, I have T = 10 s, W = 3 Hz
% so TW = 30 and K = 2TW-1 = 59
params.tapers = [30 59];
params.err = [2 .05];
params.Fs = Fs;
params.fpass = [0 100] ; % show results between 0 and 100 Hz
[C, phi, S12, S1, S2, f, zerosp, confC, phistd, Cerr] = coherencycpt( lfp, spikeTimes, params)	;

% Plot the coherence
plotCoherence( f, C, Cerr )


%% Spikes tend to follow an oscillation not strongly present in lfp
% Create 10 seconds of synthetic LFP and spike data. 
% In this case spikes tend to happen atop an invsible 9 Hz signal

Fs = 1000; % Sampling frequency is 1000 Hz
duration = 10; 
scale = 60; % gets the signal into approximately the range of actual LFP (-100 to 100 uV)

t = (0 : 1/Fs : duration)';
numSamples = numel( t );

f1 = 25; % 25 Hz signal
f2 = 4;  % 4 Hz signal
f3 = 40; % 40Hz signal
signalOfInterest = sin(9*t*2*pi);

figure;


lfp = (scale/3)*sin(f1*t*2*pi) + (scale/3)*sin(f2*t*2*pi) +  (scale/3)*sin(f3*t*2*pi) + ...
    10* randn( numSamples, 1 );
plot( t, lfp )

% Now let's generate some spike times
spikeTimes = synthesizeSpikeTrain( signalOfInterest./max(signalOfInterest), Fs, .5, .2 );

% Plot the spike times on the same plot
hold on; scatter( spikeTimes, lfp( round( spikeTimes*Fs ) ), 'Marker', 'v', ...
    'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k' )
xlabel('Time (s)', 'FontSize', 16)
ylabel('LFP (uV) and Spike Times', 'FontSize', 16)

% Now let's use Chronuz to calculate the spike-field coherence
% Will use coherencycpt
% Need to figure out tapers. If I want to use all the data, I have T = 10 s, W = 3 Hz
% so TW = 30 and K = 2TW-1 = 59
params.tapers = [30 59];
params.err = [2 .05];
params.Fs = Fs;
params.fpass = [0 100] ; % show results between 0 and 100 Hz
[C, phi, S12, S1, S2, f, zerosp, confC, phistd, Cerr] = coherencycpt( lfp, spikeTimes, params)	;

% Plot the coherence
plotCoherence( f, C, Cerr )
