%% Generate a mono-exponential decay curve

amplitude = 10;
tau = 300;
stimOnset = 1000;
noiseSD = 1;

% build the time vector
time = 0:1:5000;

% start with a slightly smoothed, noisy baseline
signal = smooth(randn(size(time)) * noiseSD, 5)';

% add a decaying mono-exponential after stimOnset
indsPostOnset = time >= stimOnset;
timeFromOnset = time(indsPostOnset) - stimOnset;

signal(indsPostOnset) = signal(indsPostOnset) + ...
    amplitude*exp(-timeFromOnset/tau);

hFullSignal = figure(6); clf, set(6,'Color','w');
plot(time, signal, 'k-');
box off;
xlabel('Time (ms)');
ylabel('Signal');
title('Exponential signal');

%% Extract the portion of the trace we want to fit

% First we need to extract the portion of the trace we'd like to fit to

tStartFitting = stimOnset + 10; % give a little buffer off the peak
tStopFitting = stimOnset + 2000; % generally you want at least 3 * tau

indsForFit = time >= tStartFitting & time <= tStopFitting;

% subtract off tStartFitting so this time vector starts at zero
% since it will be the input to our fit function
timeForFit = time(indsForFit)' - tStartFitting;

% extract just the portion
signalForFit = signal(indsForFit)';

figure(7), clf, set(7,'Color','w');
plot(timeForFit, signalForFit, 'k-');
box off;
xlabel('Time For Fit (ms)');
ylabel('Extracted Signal');
title('Exponential fitting demo');

%% Fit an exponential curve to this extracted segment

% specify the model with these options
fitModel = fittype('ampFit * exp(-t / tauFit)', 'independent', 't', 'options', fitOpts);

% do the fitting
[fitResults goodnessOfFit] = fit(timeForFit, signalForFit, fitModel, ...
    'StartPoint', [max(signalForFit) 1000], ...
    'Lower', [0 0], 'Upper', [Inf Inf]);

% print out the fits and 95% confidence intervals
paramCI = confint(fitResults);
fprintf('Amplitude Fit: %8.4f    [%8.4f %8.4f]\n', fitResults.ampFit, paramCI(1,1), paramCI(2,1));
fprintf('Tau Fit:       %8.4f ms [%8.4f %8.4f]\n', fitResults.tauFit, paramCI(1,2), paramCI(2,2));

% print out the r^2 for the fit
fprintf('R^2 for fit: %.4f\n', goodnessOfFit.rsquare);

% now let's evaluate the fit at a bunch of points so that we can plot it
signalFit = fitResults(timeForFit);

hold on
plot(timeForFit, signalFit, 'r-', 'LineWidth', 2);
legend({'Data', 'Exponential Fit'}, 'Location', 'Best');
title(sprintf('Exponential fit: Amp = %.3f, \\tau = .3f', fitResults.ampFit, fitResults.tauFit));

%% Now let's plot this fit back on the full signal

% select the plot with the full signal on it
figure(hFullSignal);

% we need to offset the time vector to put the fit in the right place on
% top of the full signal
timeForFitShifted = timeForFit + tStartFitting;

hold on
plot(timeForFitShifted, signalFit, 'r-', 'LineWidth', 2);
legend({'Data', 'Exponential Fit'}, 'Location', 'Best');
title(sprintf('Exponential fit: Amp = %.3f, \\tau = %.3f ms', fitResults.ampFit, fitResults.tauFit));


