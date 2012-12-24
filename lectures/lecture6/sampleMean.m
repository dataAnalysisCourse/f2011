%% Plot probability density function for normal distribution

% these are the true, underlying parameters of the distribution
mu = 3;
sigma = 2;

% plot the true distribution underneath the sampling distribution?
overlayExperimentalDistribution = true;

% nSamples is the number of samples we draw from this distribution, 
% which would correspond to the number of subjects / cells that you
% do your experiment on.
nSamples = 1000;

% nRepeats is the number of times we simulate running the experiment.
% In reality, you'd only do the experiment once on nSamples subjects.
% The point of simulating these virtual experiments many times 
% is to see the spread of our estimate of the mean. Our actual experiment
% would yield an estimate of the mean that would be drawn from the distribution
% that we get by simulating it and looking at the histogram.
nRepeats = 10000;

estMeans = zeros(nRepeats,1);

for iRep = 1:nRepeats 
    
    % generate the data by generating random numbers from the normal distribution
    data = sigma * randn(nSamples, 1) + mu;
    
    % compute the sample mean
    estMeans(iRep) = mean(data);
end
    
%% Plot the histogram of estimates of the mean

figure(2); clf;
set(gcf, 'Color', 'w')
set(gca, 'FontSize', 18, 'FontName', 'Helvetica');

% prepare a histogram with 100 bins
binCenters = linspace(mu-3*sigma, mu+3*sigma, 100);
binCounts = hist(estMeans, binCenters, 'k-', 'LineWidth', 3);
binWidth = mean(diff(binCenters));

if overlayExperimentalDistribution
    % plot the true distribution underneath in light gray
    vals = linspace(mu-4*sigma, mu+4*sigma, 1000);
    prob = normpdf(vals, mu, sigma);
    normalizedCounts = prob / max(prob) * max(binCounts);
    hTrueDist = fill(vals, normalizedCounts, [0.7 0.7 0.7], 'EdgeColor', 'none');
    hold on
end

% now plot the distribution of sample means
hSampleDist = bar(binCenters, binCounts, 'k');

% plot a vertical line at the true mean
plot([mu mu], [0 max(binCounts)*1.1], 'r-', 'LineWidth', 2);

% plot a horizontal line at the mean
% place it vertically so that it touches the pdf on either side
samplingStd = sigma / sqrt(nSamples);
horzLineY = binWidth * nRepeats * normpdf(mu + samplingStd, mu, samplingStd);
plot([mu-samplingStd mu+samplingStd], [horzLineY horzLineY], 'r-', 'LineWidth', 2);

box off;
xlim([min(binCenters)-binWidth max(binCenters)+binWidth]);
xlabel('Values');
ylabel('Frequency');
title(sprintf('Sampling mean distribution, true mean is \\mu = %g', mu));

