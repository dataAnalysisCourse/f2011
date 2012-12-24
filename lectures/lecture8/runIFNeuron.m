
% Simulation parameters
T = 0.5;            % total simulation time (sec)
dt = 1e-3;          % simulation timestep (sec)
tVec = 0:dt:T;      % time vector (sec)
N = length(tVec);   % number of timesteps

% I&F neuron parameters
vRest = -70e-3;     % resting membrane potential (V)
vSpike = -40e-3;     % artificially used to indicate spikes (V)
vReset = -80e-3;    % membrane potential set after spike (V)
vThresh = -55e-3;   % spiking threshold (V)
rMembrane = 10e6;   % membrane resistance (ohms)
tauMembrane = 10e-3; % membrane time constant (sec)

% Synapse parameters
eRevSynapse = 0;    % synaptic reversal potential (volts)
tauSynapse = 10e-3; % synaptic time constant (sec)
gSynapse= 0.5e-7;   % local synaptic conductivity (siemens) 
pSynapseMax = 0.5;  % maximum fraction of open channels

% Generate random presynaptic input arrival times
inputRateHz = 40;   % average rate of presynaptic releases
synapticEventVec = rand(N, 1) <= inputRateHz * dt; % vector with 1s on
synapticEventTimes = tVec(synapticEventVec);

% Additional injected current on each timestep
iInjectedVec = zeros(N,1);

% History traces for each state variable
vMembraneVec = vRest * ones(N,1);    % membrane voltage (V)
pSynapseVec = zeros(N,1);            % fraction of synaptic channels open
iSynapseVec = zeros(N,1);            % synaptic current (A)
zVec = zeros(1,N);                   % synaptic drive

% Main simulation loop
for n = 2:N
    
    % Compute synaptic current
    iSynapseVec(n) = -pSynapseVec(n-1) * gSynapse * ...   % fraction of open channels times total synaptic conductivity
                     (vMembraneVec(n-1) - eRevSynapse);   % driving potential
        
    % Update vMembrane 
    if vMembraneVec(n-1) > vThresh
        % Just spiked!
        vMembraneVec(n-1) = vSpike;  % visual indicator
        vMembraneVec(n) = vReset;    % reset potential
    else
        % No spike last timestep, integrate current coming into the cell
        derivMembraneVec = 1/tauMembrane * (... % membrane time constant
                -(vMembraneVec(n-1)-vRest) + ... % exponential decay to resting potential
                iSynapseVec(n) * rMembrane + ... % voltage change due to synaptic current (V=I*R)
                iInjectedVec(n) * rMembrane );   % voltage change due to injected current
        
        vMembraneVec(n) = vMembraneVec(n-1) + derivMembraneVec * dt;
    end
    
    % Update z, the synaptic drive
    if synapticEventVec(n) 
        % Incoming spike this timestep
        zVec(n) = 1;
    else
        % No incoming spike, z decays exponentially
        derivZ = -zVec(n-1) / tauSynapse;
        zVec(n) = zVec(n-1) + derivZ * dt;
    end    
    
    % Update pSynapse
    derivPSynapse = (exp(1) * pSynapseMax * zVec(n-1) - pSynapseVec(n-1)) / tauSynapse;
    pSynapseVec(n) = pSynapseVec(n-1) + derivPSynapse * dt;
    
end % Main simulation loop

%% Plot results of simulation: vMembrane and iSynapse

vMult = 1000; % convert V to mV for plotting
iMult = 1e9;  % convert A to nA for plotting

% Plot membrane voltage trace
figure(1), clf, set(1, 'Color', 'w', 'Name', 'Integrate and Fire Simulation', 'NumberTitle', 'off');
h(1) = subplot(2,1,1);

plot(tVec, vMult * vMembraneVec, 'k-');
hold on
plot(tVec, vMult * vReset *ones(N,1), 'r:');
plot(tVec, vMult * vRest  *ones(N,1), 'r:');
plot(tVec, vMult * vThresh*ones(N,1), 'r:');

title('Membrane Potential Trace')
ylabel('Membrane Potential (mV)');
%set(gca,'YLim',[vReset vSpike]);
set(gca,'XLim',[0 T]);
box off

% Plot synaptic current trace
h(2) = subplot(2,1,2);
plot(tVec,iMult * iSynapseVec, 'k-');
hold on
yMax = max(get(gca, 'YLim'));
set(gca,'YLim',[0 max(yMax)]);

% Plot synaptic input events
scatter(synapticEventTimes, .99*yMax*ones(size(synapticEventTimes)), 'v', 'filled', 'Cdata', [.9 0 0]);
title('Synaptic Current & Presynaptic Release Events')
ylabel('Synaptic Current (nA)');

xlabel('Time (sec)');
set(gca,'XLim',[0 T]);
box off

linkaxes(h, 'x');

