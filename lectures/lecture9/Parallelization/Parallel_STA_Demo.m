% Parallel_STA_Demo script
%
% Demonstrates the utility of parallelization with an extension of the retinal
% ganglion cell spike-triggered average example. Now there are 8 trials of data,
% which take quite a while to churn through using the version of 
% SpikeTriggeredAverageStimulus.m included here (there are faster implementations
% which would reduce need for parallelization).
% The compute time can be considerable reduced through parallelization.
% NENS 230 Autumn 2011



% Contains multiple trials' <stim> and <spikes> structures in 
load MultipleTrialsSpikesAndStim
numTrials = length( spikes );
fprintf('Will generate STA for %i separate trials\n', numTrials)

% PARAMETERS
ignoreFirstNms = 3*1000;
tau = 1:10:500;


%% Not parallel
tic 
for iTrial = 1 : numTrials
    fprintf(' Calculating STA for trial %i\n', iTrial )
    [STA{iTrial}, numSpikes{iTrial}] = ...
        SpikeTriggeredAverageStimulus( spikes{iTrial}.spikeTimes, stim{iTrial}.stim, tau, ignoreFirstNms );
end
fprintf( 'Standard for loop computation took %fs\n', toc)


totalSpikesUsed = sum( cell2mat( numSpikes ) );
% Take the average STA and plot it
avgSTA = mean( cell2mat(STA), 2 );
avgSTA = flipud( avgSTA );

% PLOT STA
plotSTA( avgSTA, tau, totalSpikesUsed );


%% Use parallel computing toolbox
clear('STA', 'numSpikes')
useCores = 4; % MacBook Pro Corei7 CPU is quad-core
fprintf('Going parallel with %i cores...\n', useCores )
poolsize = matlabpool('size');
if poolsize == 0
    matlabpool( useCores );
elseif poolsize ~= useCores
    matlabpool close
    matlabpool( useCores );
end

tic 
parfor iTrial = 1 : numTrials
    fprintf(' Calculating STA for trial %i\n', iTrial )
    [STA{iTrial}, numSpikes{iTrial}] = ...
        SpikeTriggeredAverageStimulus( spikes{iTrial}.spikeTimes, stim{iTrial}.stim, tau, ignoreFirstNms );
end
fprintf( 'Parallelized parfor loop computation took %fs\n', toc)

% PLOT STA
plotSTA( avgSTA, tau, totalSpikesUsed );
