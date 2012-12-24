%% Plot probability mass function for die roll

vals = 1:6;
prob = ones(size(vals)) / numel(vals);

figure; clf;
set(gcf, 'Color', 'w')
set(gca, 'FontSize', 18, 'FontName', 'Helvetica');

bar(vals, prob, 'k');
box off;
xlabel('Values');
ylabel('Probability');
title('PMF for fair die');

%% Plot probability density function for normal distribution

mu = 3;
sigma = 2;

% generate 1000 evenly spaced points between 0 and 
vals = linspace(mu-4*sigma, mu+4*sigma, 1000);

% normpdf will evaluate PDF of a normal distribution for you,
% but since it's in the stats toolbox, we'll do it manually here.
% prob = normpdf(vals, mu, sigma);

% this is the syntax for an anonymous function, meaning it's a shortcut
% way of defining a function "inline" without having to create a .m for it.
% this function has one input argument "x" and can only return one output.
% Note the use of .^2 in the definition, so that we can pass in a vector 
% to this function and get a vector back out.
normpdfFn = @(x) 1/(sigma * sqrt(2*pi)) * exp(-(x-mu).^2 / (2*sigma^2));

% like so...
prob = normpdfFn(vals);

figure; clf;
set(gcf, 'Color', 'w')
set(gca, 'FontSize', 18, 'FontName', 'Helvetica');

% plot the pdf
plot(vals, prob, 'k-', 'LineWidth', 3);

hold on

% plot a vertical line at the mean
plot([mu mu], [0 max(prob)*1.1], 'r-', 'LineWidth', 2);

% plot a horizontal line at the mean
% place it vertically so that it touches the pdf on either side
horzLineY = normpdf(mu+sigma, mu, sigma);
plot([mu-sigma mu+sigma], [horzLineY horzLineY], 'r-', 'LineWidth', 2);

box off;
xlim([min(vals) max(vals)]);
xlabel('Values');
ylabel('Probability');
title(sprintf('PDF for normal distribution \\mu = %g, \\sigma = %g', mu, sigma));

%% Plot CDF for normal distribution


% normpdf will evaluate PDF of a normal distribution for you,
% but since it's in the stats toolbox, we'll do it manually here.
% cdf = normcdf(vals, mu, sigma);

% quad is a tool for numerically evaluating the integral of a function.
% Basically it tries to calculate the area under the curve by evaluating
% the function at many points using a clever algorithm.
% Here we tell it to integrate from a value far below mu (since we can't
% tell it to use -infinity) up until some value x. This will give us the
% value of the CDF at x. Think, why can't we just use cumsum to keep a
% running tally of the values? If we do this we'll get values that are too
% high, because cumsum is not taking ito account the "width" of each of these
% rectangles when we're tallying up the total area.

% another way of doing this is arrayfun, see help arrayfun
cdf = zeros(size(vals));
for iVal = 1:length(vals)
    cdf(iVal) = quad(normpdfFn, mu-10*sigma, vals(iVal));
end

figure; clf;
set(gcf, 'Color', 'w')
set(gca, 'FontSize', 18, 'FontName', 'Helvetica');

% plot the cdf
plot(vals, cdf, 'k-', 'LineWidth', 3);

hold on

% plot a vertical line at the mean
plot([mu mu], [0 1], 'r-', 'LineWidth', 2);

% plot a horizontal line at the mean
% place it vertically so that it intercepts the cdf at the mean
horzLineY = normcdf(mu, mu, sigma);
plot([mu-sigma mu+sigma], [horzLineY horzLineY], 'r-', 'LineWidth', 2);

box off;
xlim([min(vals) max(vals)]);
xlabel('Values');
ylabel('Cumulative Probability');
title(sprintf('CDF for normal distribution \\mu = %g, \\sigma = %g', mu, sigma));
