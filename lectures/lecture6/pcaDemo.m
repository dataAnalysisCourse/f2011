
nPoints = 200;
nEmbeddingDimensions = 50;
noiseSD = 0.3;

% generate random points on a circle
angles = 2*pi*rand(nPoints,1);
radii = 8 + 0.2*randn(nPoints,1);
origX = cos(angles).*radii;
origY = sin(angles).*radii;

origEmbedded = [origX origY noiseSD*randn(nPoints, nEmbeddingDimensions-2)];

rotated = (randn(nEmbeddingDimensions)*origEmbedded')';
x = rotated(:,1);
y = rotated(:,2);
z = rotated(:,3);

figure(7), clf, set(7, 'Color', 'w');
plot3(x,y,z, 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k');
xlabel('x');
ylabel('y');
zlabel('z');
title('Demo Data, pre-PCA');
box on;

%% Make histograms in x, y, z

figure(8), clf, set(8, 'Color', 'w');

subplot(3,1,1);
plot(x,y,'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k');
xlabel('x');
ylabel('y');
box off

subplot(3,1,2);
plot(x,z,'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k');
xlabel('x');
ylabel('z');
box off

subplot(3,1,3);
plot(y,z,'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k');
xlabel('y');
ylabel('z');
box off

%% Run PCA to find orthogonal axes with largest variance

% Build the data matrix. Each row is an observation, each column is a
% dimension or measurement (x, y, z)

data = [x y z];

% subtract the means off each column and normalize the variance
dataNormalized = zscore(data);

[coeff score latent] = princomp(data);

figure(9), clf, set(9, 'Color', 'w');
plot(score(:,1), score(:,2), 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k');
xlabel('PC 1');
ylabel('PC 2');
title('Demo Data, post-PCA');
box off;


