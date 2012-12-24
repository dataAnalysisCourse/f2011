%% Load the behavioral data
load flyData.mat
nGenotypes = length(genotypeNames);

%% plot the Raw data for each genotype as a timeseries
figure(8), clf, set(8, 'Color', 'w');
cmap = hsv(nGenotypes);

for iGeno = 1:nGenotypes
    hRaw(iGeno) = subplot(nGenotypes, 1, iGeno);
    matches = find(genotypeIds == iGeno);
    
    plot(rawData(matches,:)', '-', 'Color', cmap(iGeno, :));
    box off
    
    xlim([1 size(rawData,2)]); % 1 to the number of dimensions
    ylim([min(rawData(:)) max(rawData(:))]); % global min to global max
    title(genotypeNames{iGeno});
end
% make the axes zoom together 
linkaxes(hRaw);

%% Run PCA on rawData to find orthogonal axes with largest variance

[coeff score latent] = princomp(rawData);

% Plot the tubes from each genotype in a particular color in a scatter plot
% A good way way to generate the distinct colors is to use hsv(nGenotypes)
% where n is the number of genotypes (which should calculate from
% genotypeIds or genotypeNames). You can this using plot in a loop. You should hold on to
% the handles from each call to plot in an array that you can later use to
% specify the legend

% You'll want to plot the coordinates of each tube along the first and
% second principal components as the x and y axes. label your axes
% accordingly.

figure(9), clf, set(9, 'Color', 'w');

nGenotypes = numel(genotypeNames);
cmap = hsv(nGenotypes);

for iGeno = 1:nGenotypes
    matches = find(genotypeIds == iGeno);
    hForLegend(iGeno) = plot(score(matches,1), score(matches,2), ...
        'o', 'MarkerFaceColor', cmap(iGeno, :), 'MarkerEdgeColor', 'none', 'MarkerSize', 6);
    hold on
end

set(gca, 'FontSize', 16);    
xlabel('PC 1');
ylabel('PC 2');
title('PCA-reduced behavioral data');
legend(hForLegend, genotypeNames, 'Location', 'Best');
box off;

