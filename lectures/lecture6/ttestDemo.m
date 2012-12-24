%% Draw random data from a normal distribution near zero
mu = 0.5;
sigma = 2;
nSamples = 100;

samples = randn(nSamples,1)*sigma + mu;

[sig p ci stats] = ttest(samples);

if sig
    msg = 'Null hypothesis rejected';
else
    msg = 'Null hypothesis not rejected';
end

fprintf('%s: p = %.4f\n', msg, p);
fprintf('95%% CI for the mean: [%.4f %.4f]\n', ci(1), ci(2));

%% Plot the histogram and confidence intervals for the mean

figure(2); clf;
set(gcf, 'Color', 'w')
set(gca, 'FontSize', 18, 'FontName', 'Helvetica');

% plot a histogram with 100 bins to show the samples
binCenters = linspace(mu-3*sigma, mu+3*sigma, 100);
binCounts = hist(samples, binCenters);
bar(binCenters, binCounts, 'k');
hold on

% plot a vertical line at zero
plot([0 0], [0 max(binCounts)*1.1], 'r-', 'LineWidth', 2);

% plot a horizontal line for the confidence interval
plot(ci, [max(binCounts) max(binCounts)], 'r-', 'LineWidth', 2);

box off
xlabel('Value');
ylabel('Frequency');
title(sprintf('T-test demo, true \\mu = %g', mu));

