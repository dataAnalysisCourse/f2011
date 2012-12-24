% synthesizeSpikeTrain.m
% NENS230 Autumn 2011
% Given an continuous signal which determines the likelihood of spiking,
% will generate a point process (vector of spike times) of spikes randomly
% generated based on this input.
% Serves as a helper function for spikeFieldCoherence.m
% INPUT:
%     r     input driving vector; value at step i is nonlinearly related to 
%           to probability of firing at step i. note that if r is > 1 then
%           the probability actually decreases!
%     Fs    sampling frequency of r; used to properly set units of output
%     threshold (optional) Threshold for nonlinear part of LN model
%     multiplier (optional) Can be used to raise firing rate by multiplying 
%
% OUTPUT:
%     spikeTimes    vector of spike times, in seconds assuming that r
%                   starts at t=0s and ends at t = numel(r)/Fs

function spikeTimes = synthesizeSpikeTrain( r, Fs, threshold, multiplier )
    %PARAMETERS
    refractory = .005;    % refractory period in seconds
    
    if nargin < 3
        threshold = .3;     % Threshold for the nonlinear part of the LN model
    end 
    if nargin < 4
        multiplier = 5;    % Increases firing rate
    end

    % Make sure no r is > 1; if there is warn user
    if any( r > 1.00001 )
        fprintf('Warning: input <r> to synthesizeSpikeTrain has values greater than 1\n')
    end
    

    
    % Simple nonlinear step
    r(r < threshold) = 0;
    
    % Scale r so there are more spikes
    r = r .* multiplier;
    r( r > 1 ) = 1; % Saturate
    
    % Now we need to generate spiking. I will enforce a refractory period.
    numSamples = length( r );
    spikeVec = zeros(numSamples, 1);
    step = 1;
    while step <= numSamples  
        % Whether or not there is a spike during this ms is determined by
        % a poisson process where the instantaneous underlying rate lambda
        % comes from LN above.
        % Poisson firing (for just 1 event): lambda*exp(-lambda)
        lambda = r(step);
        P_spike = lambda * exp( - lambda );
        % uniform rand to see wheter we spike.
        if rand <= P_spike
            spikeVec(step) = 1;
            step = step + refractory*Fs; % refractory period
        else
            step = step + 1; % keep moving through the time vector
        end
    
    end
    
    % Report average firing rate
    mu_rate = ( nnz(spikeVec)/numSamples ) * 1000; % divide by 1000 to get Hz
    fprintf( 'Avg rate is %fHz\n', mu_rate )
    
    % Make spike times vector, in ms
    spikeTimes = find( spikeVec )/Fs;

end