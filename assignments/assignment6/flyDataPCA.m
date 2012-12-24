%% Load the behavioral data
load flyData.mat

%% plot the Raw data for each genotype as a timeseries
nGenotypes = length(genotypeNames);
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
% START WRITING YOUR CODE HERE



% Plot the tubes from each genotype in a particular color in a scatter plot
% A good way way to generate the distinct colors is to use hsv(nGenotypes)
% where n is the number of genotypes (which should calculate from
% genotypeIds or genotypeNames). You can this using plot in a loop. You should hold on to
% the handles from each call to plot in an array that you can later use to
% specify the legend(handlesList, genotypeNames, ...)
%
% You'll want to plot the coordinates of each tube along the first and
% second principal components as the x and y axes. label your axes
% accordingly.



