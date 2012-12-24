% Plots spikes evoked vs. light pulse frequency curves for all
% neurons in a given csv database

% name of the patching database to load
fnameDB = 'patchingDatabase.csv';

% look for the abf files in a subfolder named Data relative to where I am 
thisFolder = fileparts(mfilename('fullpath')); % get the directory that this script is located in
dataDirectory = fullfile(thisFolder, 'Data');

% load the patched neuron database
patchData = loadPatchData(fnameDB);

% run the frequency tracking analysis
opsinTracking = compareOpsinTracking(patchData, dataDirectory);

