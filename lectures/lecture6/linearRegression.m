%% Generate linearly correlated x and y values

nPoints = 1000;
slope = 0.5;
icept = 20;

xOffset = 100;
xSD = 30;
noiseSD = 40;

x = randn(nPoints,1) * xSD + xOffset;
y = icept + slope * x + randn(nPoints,1) * noiseSD;

%% Fit using polyfit

figure(3), clf, set(3, 'Color', 'w');
hData = plot(x,y, 'kx');

% fit a linear trend line
[p s] = polyfit(x, y, 1);

% evaluate the fit and 95% prediction intervals
xFit = linspace(min(x), max(x), 100);
[yFit delta] = polyconf(p, xFit, s);

hold on
hFit = plot(xFit, yFit, 'r-', 'LineWidth', 2);
hCI = plot(xFit, yFit+delta, 'r--', 'LineWidth', 2);
plot(xFit, yFit-delta, 'r--', 'LineWidth', 2);
box off
xlabel('x');
ylabel('y');
legend({'Data', 'Fit', '95% Prediction Intervals'}, 'Location', 'Best');
title({'Linear Regression Demo', sprintf('Fit: y = %g * x + %g', p(1), p(2))});

%% Fit regression using regress
fprintf('\n');

% make a matrix that has x in the first columns, all ones in the second
XWithOnes = [x ones(size(x))];

% fit the regression
[coeffs ci residuals residualIntervals stats] = regress(y, XWithOnes);

% print out the coefficients and the confidence intervals
fprintf('Slope:     %g [%g %g]\n',coeffs(1), ci(1,1), ci(1,2));
fprintf('Intercept: %g [%g %g]\n',coeffs(2), ci(2,1), ci(2,2));

% print the R^2 statistic
fprintf('R^2 = %g\n', stats(1));

