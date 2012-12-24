function tau = fitInactivation(fname)
% tau = fitInactivation(fname)
% Loads an abf file with a neuron recorded in voltage clamp and measures the
% inactivation kinetics of the depolarizing photocurrent using an exponential
% fit. Assumes that channel 1 is the voltage, channel 2 is the laser state (fit
% starts 1 ms after laser onset). Looks at sweep 1 only, fits the portion from
% 1ms after laser on to 50 ms after laser on.
%
% Inputs
% 	fname - abf file name for use with abfload
%
% Outputs
%   tau - the time constant of inactivation from the exponential fit
%
% NENS 230, Fall 2011, Stanford University.

% I'd recommend commenting out the first line of the file when writing this so that
% you can edit it as a script. Then define fname as:
%
% fname = 'photocurrent.abf';
%
% and you can just run this code as a script. Just be sure to change it
% back at the end to a function.

% Load the abffile using abfload.
[data samplingIntervalUs] = abfload(fname);

% Figure out how many samples in tvecMs there are along dim 1
nSamples = size(data,1);

% Generate a tvecMs vector in ms! 
tvecMs = ((1:nSamples) * samplingIntervalUs/1000)';

% Pull out channel 1, sweep 1 of the data, which is the membrane voltage. 
vmTrace = data(:,1,1);

% Pull out channel 2, sweep 1 of the data, which is the laser state signal
laserTrace = data(:,2,1);

% Threshold the laser and figure out the onset and offset tvecMss
laserOn = laserTrace > mean([min(laserTrace) max(laserTrace)]);
tLaserOn = tvecMs(find(laserOn, 1, 'first'));
tLaserOff = tvecMs(find(laserOn, 1, 'last'));

% Plot it
hFullTrace = figure(1); clf, set(1, 'Color', 'w');
plot(tvecMs, vmTrace, 'k-');
box off
box off
xlabel('Fit Time (ms)');
ylabel('Current (pA)');
title('ChR2 Photocurrent');

% Zoom in on the relevant portion
tPadding = 20;
xlim([tLaserOn-tPadding tLaserOff+tPadding]);

%% Extract the portion to fit

% Extract the region 1 ms after the laser turns ON until 50 ms after the
% laser turns ON. (Yes, both relative to onset).
% Also generate a tvecMs vector that has the same size as this portion
% and starts at 0. 

% START WRITING YOUR CODE HERE



% Plot the fragment against this tvecMs vector to verify you've pulled it
% out correctly.



% Note that this exponential doesn't return to zero after it decays, due
% to the remaining steady-state photocurrent. You'll need to fit an offset
% term in the exponential function. The function form will look like:
%
%    a * exp(-t/tau) + b
%
% Call fittype, make sure you specify 'independent', 't'



% Now you'll call fit with this model, and pass in the optional arguments
%
% Reasonable starting points [lower bounds, upper bounds] are:
%   a : min(vmPortionToFit)-max(vmPortionToFit)   [-Inf 0]
%   tau: 2   [0 Inf]
%   base: max(vmFit)     [-Inf 0]
%
% In calling fit, you'll want the extra arguments to look like this, since
% they are specified in alphabetical order
% 
%  'StartPoint', [startA startBase startTau], ...
%  'Lower',      [lowerA lowerBase lowerTau], ...
%  'Upper',      [upperA upperBase upperTau] );
%



% Now we evaluate the fit results on tFit. The output argument of fit() is an 
% object which you call just like a function and it will tell you the value of 
% the fit at the tvecMs points you pass in.



% Now we can plot this fit on the original trace.
% Think carefully about what tvecMs vector to use here. tFit has the same
% size, but it starts at zero, whereas this fitted exponential should start
% where you pulled out the start of vmPortionToFit from.
% Plot the exponential fit in red, width 2, in figure(hFullTrace).
figure(hFullTrace); % recall the original figure
hold on



% Change the title of this plot and use sprintf to include the fitted tau
% in the title. If you want the special tau character use \\tau inside
% sprintf. This is because sprintf will replace the \\ with \, and then
% title will replace the \tau with the tau character.
%
% Remember you can access the fit parameters using fitResults.nameOfParam



% Lastly, remember we're supposed to return the fitted tau so assign this
% into tau



