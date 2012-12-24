function opsinTracking = compareOpsinTracking(patchData, dataDirectory)
% compareOpsinTracking : plots averaged light frequency tracking curves for each unique opsin
%
% Note: each abf file for a given opsin must use the same set of light pulse
% frequencies (after rounding) in order to facilitate averaging. 
%
% INPUTS
% patchData - a struct array with at least the following fields:
%     opsin - string name of the construct
%     abfName - filename of the abf file
%
% dataDirectory - path to the directory where abf files are located
%
% OUTPUTS
% opsinTracking - a struct array whose length is equal to the number of unique opsins
%     opsin - name of the opsin
%     pulseFrequencyHz - nFreq x 1 array of light pulse frequencies used
%     spikesEvokedMean - nFreq x 1 array of mean spikes evoked
%     spikesEvokedStd  - nFreq x 1 array of std dev of spikes evoked
%     spikesEvokedSEM  - nFreq x 1 array of standard error of the mean spikes evoked
%     nNeurons - number of neurons

% Check the arguments passed in
if nargin < 2
    error('Usage: compareOpsinTracking(patchData, dataDirectory)');
end

% Extract a list of unique opsins found in patchData and count how many
% unique opsins there are
opsinNamesByPatch = ???
opsinNames = ???
nOpsins = ???

% Loop over the unique opsins
for iOpsin = ???

    % Pull out the current opsin for convenience
    currentOpsin = ???
    
    % Store this in opsinTracking(iOpsin) in field opsin
    ??? = currentOpsin;
    
    % Find and pull out those neuron structs in patchData that
    % match the current opsin name
    matches = strcmp(???, ???);
    currentOpsinData = ???; 
    
    % Figure out how many cells there are for this opsin
    % and store this in opsinTracking(iOpsin) as field nNeurons
    nNeuronsThisOpsin = numel(???);
    ??? = nNeuronsThisOpsin;
        
    % Loop over the neurons for the current opsin
    for iNeuron = ???
        % Grab the struct for this neuron
        currentNeuron = ???
        
        % Build the abf file name for this neuron, assume its inside dataDirectory
        abfName = fullfile(???, ???);
        
        % Check to make sure this file exists, error if not
        if ~exist(abfName, 'file')
            error('Cannot find abf file %s', abfName);
        end
        
        % Call countSpikesByLightPulseFrequency
        [nSpikesEvokedThisNeuron pulseFrequencyHzThisNeuron] = ???;
        
        % Is this is the first run-through for this opsin?
        if iNeuron == 1
            % Figure out how many frequencies were used
            nFreq = ???;
            
            % First run-through, store the list of frequencies used
            opsinTracking(iOpsin).pulseFrequencyHz = pulseFrequencyHzThisNeuron;
            
            % Create an empty matrix to store the tracking curve for all the 
            % neurons for this opsin. We want these to be filled with 0s and
            % size [nNeuronsThisOpsin nFreq]
            nSpikesEvokedThisOpsin = ???;
        else
            % Not the first time through, compare pulseFrequencyHz for this
            % file against the stored pulseFrequencyHz from the first file
            % to make sure they're the same. Round these off first to allow 
            % small differences though.
            if any(round(???) ~= round(???))
                error('Different light pulse frequencies used for opsin %s', currentOpsin);
            end
        end
        
        % Store the nSpikesEvokedThisNeuron curve as row iNeuron in
        % nSpikesEvokedThisOpsin. Remember that nSpikesEvoked is a column
        % vector, so you'll have to transpose it to make it a row vector so
        % that it fits into the matrix correctly
        nSpikesEvokedThisOpsin(???, ???) = ???;
    end
    
    % Now use the mean and std functions to compute the mean and standard deviation
    % of nSpikesEvokedThisOpsin for each light pulse frequency. Remember that
    % nSpikesEvokedThisOpsin is size nNeuronsThisOpsin x nFreq, thus we want
    % to compute the mean and std along the first dimension. This is the
    % default behavior of mean and std, but to be explicit, let's call mean
    % with two arguments, the second being 1 to indicate that we
    % want the mean along the first dimension. We want std to do the same
    % thing, but if you look at help std, you'll notice that std wants
    % three arguments in this case, with the second argument being how to
    % normalize (use 0 for this argument to get the unbiased estimator
    % which normalizes by n-1), and the third argument to indicate which
    % dimension to find the standard deviation along (1)
    % Store the results in opsinTracking(iOpsin)
    
    ???.spikesEvokedMean = mean(???, 1);
    ???.spikesEvokedStd = std(???, 0, 1);
   
    % Now compute the standard error of the mean, which is the standard
    % deviation divided by the square root of the number of neurons for
    % this opsin (nNeuronsThisOpsin). Again, store in opsinTracking(iOpsin)
    ???.spikesEvokedSEM = ???
    
    % Now you should be thinking to yourself, have we computed and stored
    % all of the things into opsinTracking(iOpsin) that we promised we
    % would in the documentation?
end

% Now we want to plot a summary curve of all the opsins. Technically, we
% could have done this one trace at a time in the loop above and avoided
% having a second loop over opsins down here, but it's generally a good
% idea to separate code that does analysis from code that generates
% figures, just for clarity.

% Make the figure
figure; clf; 
set(gcf, 'Color', 'w', 'Name', 'Opsin Tracking Summary', 'NumberTitle', 'off');

% Now come up with a set of colors to use for each opsin
% A useful function for coming up with colors is lines()
% We'll store the colors in a colormap. 
% jet() is also nice for a rainbow colormap, but only when 
% you have enough elements to fill out the rainbow.
cmap = lines(nOpsins);

% You can check that cmap is of size nOpsins x 3. 
% The 3 values are red, green, blue intensity values
% so the color for a given opsin is the 1x3 row of cmap, that is 
% cmap(iOpsin, :);

% Loop over the unique opsins
for iOpsin = ???
    
    % Use errorbar to plot the mean and SEM for this opsin
    % See help errorbar to see what each argument means, you want to use
    % the errorbar(x,y,e) version in the second paragraph. 
    % You'll want to pull these values out of three different fields in the 
    % struct opsinTracking(iOpsin)
    errorbar(???, ???, ???, ...
		'Color', cmap(iOpsin,:), 'LineWidth', 2);
    hold on
    
end

% Label the axes
xlabel('Light Pulse Frequency (Hz)')
ylabel('Number of Spikes Evoked');
title('Opsin Tracking Summary');

% Add a legend (we'll talk about this next week)
legend(opsinNames, 'Location', 'Best');

% Hide the surrounding box
box off

end
