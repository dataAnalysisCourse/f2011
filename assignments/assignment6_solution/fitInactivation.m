function tau = fitInactivation(fname)
% I'd recommend commenting out this first line when writing this so that
% you can edit it as a script. Then define fname as:
%
% fname = 'photocurrent.abf';
%
% and you can just run this code as a script. Just be sure to change it
% back at the end

% Load the abffile using abfload.
[data samplingIntervalUs] = abfload(fname);

% Figure out how many samples in time there are along dim 1
nSamples = size(data,1);

% Generate a time vector in ms! 
time = (1:nSamples)' * samplingIntervalUs/1000;

% Pull out channel 1, sweep 1 of the data, which is the membrane voltage. 
vmTrace = data(:,1,1);

% Pull out channel 2, sweep 1 of the data, which is the laser state signal
laserTrace = data(:,2,1);

% Threshold the laser and figure out the onset and offset times
laserOn = laserTrace > mean([min(laserTrace) max(laserTrace)]);
tLaserOn = time(find(laserOn, 1, 'first'));
tLaserOff = time(find(laserOn, 1, 'last'));

% Plot it
hFullTrace = figure(1); clf, set(1, 'Color', 'w');
plot(time, vmTrace, 'k-');
box off
box off
xlabel('Fit Time (ms)');
ylabel('Current (pA)');
title('ChR2 Photocurrent');

% Zoom in on the relevant portion
tPadding = 20;
xlim([tLaserOn-tPadding tLaserOff+tPadding]);

%% Extract the portion to fit

% Extract the region 1 ms after the laser onset until 20 ms before the
% laser turns off. Generate a time vector that has the same size as this portion
% and starts at 0 

tStartFit = tLaserOn + 10;
tStopFit = tLaserOn + 300;

% START WRITING YOUR CODE HERE

indsToExtract = time >= tStartFit & time <= tStopFit;
tFit = time(indsToExtract) - tStartFit;
vmPortionToFit = vmTrace(indsToExtract);

% Plot the fragment against this time vector to verify you've pulled it
% out correctly.

figure(2), clf, set(2, 'Color', 'w')
plot(tFit, vmPortionToFit, 'k-');

box off
xlabel('Fit Time (ms)');
ylabel('Current (pA)');
title('Photocurrent fragment');

% Note that this exponential doesn't return to zero after it decays, due
% to the remaining steady-state photocurrent. You'll need to fit an offset
% term in the exponential function. The function form will look like:
%
%    a * exp(-t/tau) + b
%
% In calling fittype, make sure you specify 'independent', 't'

fitModel = fittype('a*exp(-t/tau) + base', 'independent', 't');

% Now you'll call fit with this model, and pass in the optional arguments
%
% Reasonable starting points [lower bounds, upper bounds] are:
%   a : min(vmFit)-max(vmFit)   [-Inf 0]
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

startA = min(vmPortionToFit) - max(vmPortionToFit);
lowerA = -Inf;
upperA = 0;

startTau = 2;
lowerTau = 0;
upperTau = 100;

startBase = max(vmPortionToFit);
lowerBase = -Inf;
upperBase = 0;

startPoint = [startA startBase startTau];
lowerBounds = [lowerA lowerBase lowerTau ];
upperBounds = [upperA upperBase upperTau];

[fitResults gof] = fit(tFit, vmPortionToFit, fitModel,  ...
   'StartPoint', startPoint, 'Lower', lowerBounds, 'Upper', upperBounds);

% Now we evaluate the fit results on tFit. fitResults is an object which
% you call just like a function and it will tell you the value of the fit
% at the time points you pass in.

vmFit = fitResults(tFit);

% Now we can plot this fit on the original trace.
% Think carefully about what time vector to use here. tFit has the same
% size, but it starts at zero, whereas this fitted exponential should start
% where you pulled out the start of vmPortionToFit from.
% Plot the exponential fit in red, width 2, in figure(hFullTrace).

figure(hFullTrace);
hold on

plot(tFit + tStartFit, vmFit, 'r-', 'LineWidth', 2);

% Change the title of this plot and use sprintf to include the fitted tau
% in the title. If you want the special tau character use \\tau inside
% sprintf. This is because sprintf will replace the \\ with \, and then
% title will replace the \tau with the tau character.
%
% Remember you can access the fit parameters using fitResults.nameOfParam

title(sprintf('ChR2 Photocurrent: \\tau = %.3f ms', fitResults.tau));

% Lastly, remember we're supposed to return the fitted tau so assign this
% into tau

tau = fitResults.tau;


