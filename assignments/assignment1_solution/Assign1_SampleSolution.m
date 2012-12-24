% NENS 230 Autumn 2011
% Assignment 1 Sample Solution
% Written by Sergey Stavisky on 29 September 2011

% You must set path correctly before running this.

% Step 1: Generate and load the data
genData
load('I_trace_segment1.mat')
load('I_trace_segment2.mat')
load('I_trace_segment3.mat')
load('I_trace_segment4.mat')
load('I_trace_segment5.mat')

% Step 2: Remove first 5 elements of all the time and current vectors
I_1 = I_1(6:end);
I_2 = I_2(6:end);
I_3 = I_3(6:end);
I_4 = I_4(6:end);
I_5 = I_5(6:end);

t_1 = t_1(6:end);
t_2 = t_2(6:end);
t_3 = t_3(6:end);
t_4 = t_4(6:end);
t_5 = t_5(6:end);

% Step 3: Deal with the bizarre t_1
% Excise faulty element 46 of t_1.
t_1(46) = []; 
% NOTE: Several of you incorrectly excised element 51 because this was the
% index of the bad element in the original t_1. However, once you removed the
% first 5 elements of t_1, the bad element's index became 46.

% Transpose t_1 so it's a column vector like the other t_ variables
t_1 = t_1';

% Step 4: Concatenate the current and time values into single vectors.
t   = [t_1 ; t_2 ; t_3 ; t_4; t_5];
I_m =  [ I_1 ; I_2 ; I_3; I_4; I_5];

% Step 5: Convert from current to voltage
% Convert from nA to A
I_m = I_m / 1e9;   % note use of the 1e9 notation; this is more clear than writing out 1000000000. 
% Multiply by resistance to get voltage.
ELECTRODE_RESISTANCE = 8e6; % Once again, note use of the 8e6 notation.
V_m = I_m * ELECTRODE_RESISTANCE;
% Convert from Volts to mV
V_m = V_m*1000;

% Step 6: Compute the resting membrane voltage
% With what you currently know, you would do this by visually inspecting V_m
% or plotting it. Here I'm doing it programitcally; you will learn this in week 2.
% Find start of first spike 
firstSpikeInd = find(V_m > 0, 1); % the second argument, 1, tells the function to return the first occurance
firstSpikeInd = firstSpikeInd - 3; % go back a few measurements just to be safe (since the voltage is rising)
restV = mean( V_m(1:firstSpikeInd) );

% Step 7: Call VoltageTracePlot.m to make the plot
VoltageTracePlot

% Step 8: Change the color of the scatter plot to blue (at this point
% in the course you would have resumably done this through
% Plot Tools rather than programatically )
plot_h_vec = get( gca, 'Children' );
set(plot_h_vec(2), 'CData', [0 0 1]); % the vector is the red-green-blue definition
                             % of the color I want, in this case blue.

% Step 9: Save the resulting figure as a .png
saveas( figh, 'VoltageTrace', 'png')