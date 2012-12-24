% NENS 230 2011
% Will generate fake spike times for a retinal ganglion cell which is a biphasic
% OFF cell.



%PARAMETERS
refractory = 5;    % 5 ms refractory period
thresh = 2;        % Threshold for the nonlinear part of the LN model
numSamples = 5 * 60 * 1000; % in ms
updateEvery = 8;   % stimululus is changed <updateEvery> samples. Used to simulate that a monitor doesn't update every ms
                   % Here I pretend our monitor is ~120Hz, so update it every 8 samples

%% Let's generate a bunch of noisy data. Assume 1ms sampling rate. Also assume
stim.intensity = zeros( numSamples, 1 );
stim.t = stim.intensity;
for i = 1 : updateEvery : numSamples
    stim.intensity(i: i+updateEvery-1) = wgn(1,1,0);
end
stim.t(1:end) = (1 : numSamples);


%% Now let's convolve the RGC kernel with the stimulus to get a L(inear) response
load OFFkernel ; % should give us vector u
L = conv( u, stim.intensity );

%% Simple nonlinear step
LN = L;

LN(LN < thresh) = 0;

%% Now we need to generate spiking. I will enforce a refractory period.
spikeVec = zeros(numSamples, 1);
t = 1;
while t <= numSamples  %t is in units of ms
    % Whether or not there is a spike during this ms is determined by 
    % a poisson process where the instantaneous underlying rate lambda
    % comes from LN above.
    % Poisson firing (for just 1 event): lambda*exp(-lambda)
    lambda = LN(t);
    P_spike = lambda * exp( - lambda );
    % uniform rand to see wheter we spike.
    if rand <= P_spike
        spikeVec(t) = 1;
        t = t + refractory; % refractory period
    else
        t = t + 1; % keep moving through the time vector
    end
    
end

% Report average firing rate
mu_rate = ( nnz(spikeVec)/numSamples ) * 1000; % divide by 1000 to get Hz
fprintf( 'Avg rate is %fHz\n', mu_rate )

% Make spike times vector, in ms
spikeTimes = find( spikeVec );

%% Save the stimulus and the spike times
% save the stimulus
% Shorten stim so we have way more spikes than stimulus;
% Idea being that the smart thing to do is to cut out these extraneous ones
numStimSamples = numSamples / 3;
stim.intensity = stim.intensity(1:numStimSamples);
stim.t = stim.t(1:numStimSamples);

% Make them all singles. Otherwise I get bizarro comparison roundoff errors
save( 'VisualStim', 'stim' );
save( 'RGCspikes', 'spikeTimes' );