function runIFNeuronContinuous(varargin)

% Simulation parameters
Tdisplay = 0.5;     % simulation time to display at one time(sec)
dt = 1e-3;          % simulation timestep (sec)
tVec = 0:dt:Tdisplay;      % time vector for display (sec)
N = length(tVec);   % number of timesteps per display

% Visualization parameters
updateInterval = 10;   % number of timesteps between updates

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

% Additional injected current on each timestep
iInjectedVec = zeros(N,1);

% Allow parameter overrides
%assignargs(varargin);

% History traces for each state variable
% initialize with NaNs so they don't appear on the plot yet
vMembraneVec = nan(N,1);    % membrane voltage (V)
pSynapseVec = nan(N,1);            % fraction of synaptic channels open
iSynapseVec = nan(N,1);            % synaptic current (A)
zVec = nan(N,1);                   % synaptic drive
synapticEventVec = zeros(N,1);     % synaptic event indicator

% seed the first timepoint correctly
vMembraneVec(1) = vRest;
pSynapseVec(1) = 0;
iSynapseVec(1) = 0;
zVec(1) = 0;

% Conversion factors for plotting
vMult = 1000; % convert V to mV for plotting
iMult = 1e9;  % convert A to nA for plotting
hVisualization = initializeVisualization();

% Main simulation loop
n = 1;

nLastUpdate = 1;
updateCounter = 1;
abort = 0;
while ~abort
    
    % loop around reusing the same simulation vector again and again
    lastN = n;
    n = mod(n, N) + 1; % increase n, but loop around at N;
    
    % Compute synaptic current
    iSynapseVec(n) = -pSynapseVec(lastN) * gSynapse * ...   % fraction of open channels times total synaptic conductivity
        (vMembraneVec(lastN) - eRevSynapse);   % driving potential
    
    % Update vMembrane
    if vMembraneVec(lastN) > vThresh
        % Just spiked!
        vMembraneVec(lastN) = vSpike;  % visual indicator
        vMembraneVec(n) = vReset;    % reset potential
    else
        % No spike last timestep, integrate current coming into the cell
        derivMembraneVec = 1/tauMembrane * (... % membrane time constant
            -(vMembraneVec(lastN)-vRest) + ... % exponential decay to resting potential
            iSynapseVec(n) * rMembrane + ... % voltage change due to synaptic current (V=I*R)
            iInjectedVec(n) * rMembrane );   % voltage change due to injected current
        
        vMembraneVec(n) = vMembraneVec(lastN) + derivMembraneVec * dt;
    end
    
    % Determine whether there's a synaptic event this timestep
    synapticEventVec(n) = rand(1) <= inputRateHz * dt; % vector with 1s on
    
    % Update z, the synaptic drive
    if synapticEventVec(n)
        % Incoming spike this timestep
        zVec(n) = 1;
    else
        % No incoming spike, z decays exponentially
        derivZ = -zVec(lastN) / tauSynapse;
        zVec(n) = zVec(lastN) + derivZ * dt;
    end
    
    % Update pSynapse
    derivPSynapse = (exp(1) * pSynapseMax * zVec(lastN) - pSynapseVec(lastN)) / tauSynapse;
    pSynapseVec(n) = pSynapseVec(lastN) + derivPSynapse * dt;
    
    if updateCounter >= updateInterval
        updateVisualization(hVisualization);
        updateCounter = 0;
        nLastUpdate = n;
    end
    
    updateCounter = updateCounter + 1;
    
    % sleep to implement real-time simulation
    pause(dt);
    
end % Main simulation loop

%% Plot results of simulation: vMembrane and iSynapse
function hVisualization = initializeVisualization()
    % Setup figure and axes
    figh = figure(1); clf, set(figh, 'Color', 'w', 'Name', 'Integrate and Fire Simulation', 'NumberTitle', 'off');
    set(figh, 'DeleteFcn', @figureDeleteCallback); % Have the simulation stop on close

    axisWidth = 0.8;
    hVisualization.hAxes(1) = axes('ActivePositionProperty', 'OuterPosition', 'OuterPosition', [0 0.5 axisWidth 0.5]);
    hVisualization.hAxes(2) = axes('ActivePositionProperty', 'OuterPosition', 'OuterPosition', [0 0 axisWidth 0.5]);

    axes(hVisualization.hAxes(1));
    
    % Plot membrane voltage trace
    hVisualization.hVMembraneVec = plot(tVec, vMult * vMembraneVec, 'k-');
    hold on
    plot(tVec, vMult * vReset *ones(N,1), 'r:');
    plot(tVec, vMult * vRest  *ones(N,1), 'r:');
    plot(tVec, vMult * vThresh*ones(N,1), 'r:');

    % Plot spiking events
    hVisualization.hSpikeIndicators = scatter([], [], 'v', 'filled', 'Cdata', [0 0 0.9]);

    title('Membrane Potential Trace')
    ylabel('Membrane Potential (mV)');
    set(gca,'YLim',vMult * [vReset vSpike]);
    set(gca,'XLim',[0 Tdisplay]);
    set(gca,'XTick', [0 Tdisplay]);
    box off

    % Plot synaptic current trace
    axes(hVisualization.hAxes(2));
    hVisualization.hISynapseVec = plot(tVec,iMult * iSynapseVec, 'k-');
    hold on
    yMax = max(get(gca, 'YLim'));
    set(gca,'YLim',[0 max(yMax,5)]);
    set(gca,'XTick', [0 Tdisplay]);

    % Plot synaptic input events
    hVisualization.hPresynapticIndicators = scatter([], [], 'v', 'filled', 'Cdata', [.9 0 0]);

    title('Synaptic Current and Presynaptic Release Events')
    ylabel('Synaptic Current (nA)');
    xlabel('Time (sec)');
    set(gca,'XLim',[0 Tdisplay]);
    box off

    linkaxes(hVisualization.hAxes, 'x');
    
    % Add GUI Controls for various parameters
    guiParams(1).name = 'inputRateHz';
    guiParams(1).min = 0;
    guiParams(1).max = 200;
    
    guiParams(2).name = 'gSynapse';
    guiParams(2).min = 1e-8;
    guiParams(2).max = 1e-7;
    
    hPanel = uipanel('Units', 'normalized', ...
        'Position', [0.8 0 0.2 1], ...
        'BackgroundColor', 'w', ...
        'Title', 'Parameters');
    
    for iParam = 1:length(guiParams)
        % param label
        uicontrol('Style', 'text', ...
            'Parent', hPanel, ...
            'Units', 'normalized', ...
            'Position', [0.05 1-0.13-(iParam-1)*0.15 1-0.3 0.04], ...
            'String', guiParams(iParam).name, ...
            'BackgroundColor', 'w');
        
        % param slider
        guiParams(1).h = uicontrol('Style', 'slider', ...
            'Parent', hPanel, ...
            'Units', 'normalized', ...
            'Position', [0.05 1-0.2-(iParam-1)*0.15, 1-0.15 0.07], ...
            'String', guiParams(iParam).name, ...
            'Min', guiParams(iParam).min, ...
            'Max', guiParams(iParam).max, ...
            'Value', eval(guiParams(iParam).name), ...
            'Tag', guiParams(iParam).name, ...
            'Callback', @paramSliderCallback);
        
        % Min and max indicators
        uicontrol('Style', 'text', ...
            'Parent', hPanel, ...
            'Units', 'normalized', ...
            'Position', [0.01 1-0.21-(iParam-1)*0.15 0.3 0.04], ...
            'String', num2str(guiParams(iParam).min), ...
            'BackgroundColor', 'w');
        uicontrol('Style', 'text', ...
            'Parent', hPanel, ...
            'Units', 'normalized', ...
            'Position', [1-0.3 1-0.21-(iParam-1)*0.15 0.3 0.04], ...
            'String', num2str(guiParams(iParam).max), ...
            'BackgroundColor', 'w');
    end
    
    
end

function updateVisualization(hVisualization)
    % erase a portion of the trace beyond this point to make a blank gap
    % between the last sweep and this one
    blankWidth = ceil(N / 20);
    indsToBlank = n+1 : n+1+blankWidth;
    indsToBlank = mod(indsToBlank - 1, N) + 1;

    % figure out what portions of the trace need to be updated
    indsToUpdate = min(n-1,nLastUpdate+1) : n;
    indsToUpdate = mod(indsToUpdate-1, N) + 1;

    % update membrane voltage
    hData = hVisualization.hVMembraneVec;
    yData = get(hData, 'YData');
    yData(indsToUpdate) = vMult*vMembraneVec(indsToUpdate);
    yData(indsToBlank) = NaN;
    set(hData, 'YData', yData);

    % update spike indicator markers
    hData = hVisualization.hSpikeIndicators;
    xData = find(vMembraneVec == vSpike);
    xData(ismember(xData, indsToBlank)) = [];
    xData = tVec(xData);
    
    yMax = max(get(hVisualization.hAxes(1), 'YLim'));
    yData = yMax * ones(size(xData));
    set(hData, 'XData', xData, 'YData', yData);

    % update current
    hData = hVisualization.hISynapseVec;
    yData = get(hData, 'YData');
    yData(indsToUpdate) = iMult*iSynapseVec(indsToUpdate);
    yData(indsToBlank) = NaN;
    set(hData, 'YData', yData);
    initialMaxI = 5; % nA
    set(hVisualization.hAxes(2),'YLim',[0 max(max(yData), initialMaxI)]);

    % update presynaptic input indicator markers
    hData = hVisualization.hPresynapticIndicators;
    xData = find(synapticEventVec);
    xData(ismember(xData, indsToBlank)) = [];
    xData = tVec(xData);
    
    yMax = max(get(hVisualization.hAxes(2), 'YLim'));
    yData = yMax * ones(size(xData));
    set(hData, 'XData', xData, 'YData', yData);

    drawnow
end

function figureDeleteCallback(varargin)
    % tell the simulation loop to abort
    abort = 1;
end

function paramSliderCallback(hObject, varargin)
    paramName = get(hObject, 'Tag');
    newValue = get(hObject, 'Value');
    
    eval(sprintf('%s = %g', paramName, newValue));
end

end


