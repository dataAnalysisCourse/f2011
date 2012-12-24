% SpikeTriggeredAverageStimulus.m
%
% Computes the spike-triggered average (STA) stimulus preceding an action 
% potential from a recorded neuron. You provide a vector of spike
% times and a record of the stimulus intensity. The user can specify the taus
% that will be sampled. Returns a vector <STA> which is the average stimulus intensity
% at time <tau> preceding a spike of this cell.
%   For example, if the stimulus record gives the brightness value of a full
% field illumination of a retina, and the spike times are the recorded spikes
% of a retinal ganglion cell (RGC) when exposed to this stimulus, and <tau>
% is [1 10 100], then  STA would be a length 3 vector where the elements represent 
% the average stimulus brightness 1, 10, and 100 ms before this RGC spikes.
% In effect, the STA is an estimate of the response function of the RGC,
% i.e. what kind of stimulus pattern most likely evokes a spike from the neuron.
%
% NOTE: spikeTimes and stim.t should be in the same units (ms)
% and coordinated; thus, if stim.t times go from 0 to 1e5 ms (100 seconds)
% then spikeTimes should also be in ms and a spikeTime of 0 would correspond 
% to a spike at the very start of the stimulus. 
%
% USAGE:
%       [STA, numSpikesUsed, tau] = SpikeTriggeredAverageStimulus( spikeTimes, reconstructStim (,tau) (,ignoreFirstNms) )
%
% INPUTS:
%       spikeTimes            .mat file containing <spikeTimes> vector 
%                             of recorded spike times of this cell.
%       stim                  <stim> structure
%                             which describes the stimulus presented to the cell.
%       tau   (optional)      vector of latencies to look at when computing the
%                             spike-triggered average. If not provided, a
%                             default will be used. Units are ms.
%       ignoreFirstNms (optional)     will not do STA with spikes within this many
%                                     ms of the start of the stimulus. Useful if you anticipate
%                                     adaptation effects. Default is zero
% OUTPUT 
%       STA              vector of the average stimulus intensity
%                        preceding a spike. The length of STA is determined by 
%                        input vector <tau>. Each element i of STA corresponds to the
%                        average stimulus value tau(i) seconds preceding a spikle
%        numSpikesUsed   how many spikes were used to generate this STA.
%        tau             vector of tau; without it you wouldn't know what delay
%                        each element of STA corresponds to.
%
% Created by Sergey Stavisky on 8 November 2011
% Last modified by Sergey Stavisky on 20 November 2011


function [STA numSpikesUsed tau] = SpikeTriggeredAverageStimulus( spikeTimes, stim, tau, ignoreFirstNms )
    % ********************************************************************
    %                     OPTIONAL ARGUMENTS
    % ********************************************************************
    if nargin < 3
        tau = 1 : 1 : 250; % 250 ms, steps of 1 ms
    end
    if nargin < 4
        ignoreFirstNms = 0; % don't ignore any of the initial data
    end
       
    % ********************************************************************
    %                      INPUT CHECK
    % ********************************************************************
    if ~exist( 'spikeTimes', 'var' )
        error('[SpikeTriggeredAverageStimulus] spikeTimes variable missing from file %s', spikeTimesFile)
    end
    
    if ~exist( 'stim', 'var' )
        error('[SpikeTriggeredAverageStimulus] stim variable missing from file %s', stimFile)
    end
    

    
    % Remove spikeTimes that are outside of our stimulus; these wouldn't contribute
    % to the STA anyway (since there is not stimulus to compare them to) 
    % and only slow down computation.
    spikeTimes( spikeTimes > stim.t(end) ) = []; 
    
    % Throw out spike times that happen before the <ignoreFirstNms> or
    % the maximum of tau, whichever is greatest.
    removeFromStart = max( ignoreFirstNms, max( tau ) );
    spikeTimes( spikeTimes < removeFromStart ) = [];
    
    % ********************************************************************
    %                         COMPUTE STA
    % ********************************************************************
    numSpikesUsed = length( spikeTimes ); % because all remaining spikes will actually be used
    
    % NOTE: Preallocation and vectorization makes this MUCH faster. However,
    % an even better way to do it is to just have a vector of the same length as
    % tau, and for each spike, add the preceding stimulus to this vector and
    % then normalize by the number of spikes at the end. That is, you don't actually
    % store the pre-spike stimulus for each spike, you just keep adding them to one
    % vector.
    % The point here is that while preallocation and vectorizaiton can make the
    % implementation of a particular algorithm much faster, often a different
    % algorithm can be even better. 
    % The different algorithms are presented below, commented out:
    
    %%    STORING EACH PRE-SPIKE STIMULUS
%     STA = zeros( numel( spikeTimes), length( tau ) ); % preallocate STA: spike x tau
% 
%     % Loop through each spike
%     for iSpike = 1 : numSpikesUsed % note I use the more clear <numSpikesUsed> rather than length( spikeTimes ).
%         myT = spikeTimes(iSpike);
%         % Vectorized Form
%         % Get the indexes of the stimulus where the time of that stimulus element corresponds
%         % to the <tau> times preceding this spike's time. The vectorized way to do this is below,
%         % and is a bit tricky.
%         myStimInds = ismember(stim.t, myT - tau); % You'll want to look up how ismember works
%         STA(iSpike,:) = stim.intensity( myStimInds ); %Note this is logical, not numerical, indexing
%     end %for iSpike = 1 : numSpikesUsed
%     
%     % Note also that the way I've done it, the right side of the matrix STA corresponds to tau(1)
%     % and left side to tau(end), since time goes forward in myStimInds. Thus I will reverse the order 
%     % of tau so that things stay lined up.
%     tau = fliplr( tau );
%     % need to keep this in mind
%     
%     % Now find the mean stimulus
%     STA = mean( STA, 1 );

    %% NOT STORING EACH PRE-SPIKE STIMULUS (SLIGHTLY FASTER WAY AND MORE MEMORY EFFICIENT)
    STA = zeros( numel( tau ), 1 ); % preallocate STA: tau x 1
    % Loop through each spike
    for iSpike = 1 : numSpikesUsed % note I use the more clear <numSpikesUsed> rather than length( spikeTimes ).
        myT = spikeTimes(iSpike);
        % Vectorized Form
        % Get the indexes of the stimulus where the time of that stimulus element corresponds
        % to the <tau> times preceding this spike's time. The vectorized way to do this is below,
        % and is a bit tricky.
        myStimInds = ismember(stim.t, myT - tau); % You'll want to look up how ismember works
        STA = STA + stim.intensity( myStimInds ); %Note this is logical, not numerical, indexing
    end %for iSpike = 1 : numSpikesUsed
    STA = STA ./ numSpikesUsed;
    
    % Note also that the way I've done it, the right side of the matrix STA corresponds to tau(1)
    % and left side to tau(end), since time goes forward in myStimInds. Thus I will reverse the order
    % of tau so that things stay lined up.
    tau = fliplr( tau );
    

    


end