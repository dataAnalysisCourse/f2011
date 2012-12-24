% VoltageTracePlot.m
% NENS 230 Autumn 2011   Assignment 1
% Created by Sergey Stavisky on 26 September 2011

% Generates a voltage trace plot when the appropriately named time and voltage
% values are in the workspace. 



% *************************************************************************************
%                       Check that the requisite variables exist
% *************************************************************************************
% This script expects a variable t and V_m to exist in the workspace before 
% it is called. For your benefit, I've included this thorough check. Although
% it's good practice to do this, in honesty most of the time one is too lazy
% to write in such checks.
if ~exist( 't', 'var' ) % I'm saying, if not (~ symbol) in existance variable named 't'
    % fprintf is the standard text printout command. The \n at the end means "end line", aka 'carriage return' from old school days.
    fprintf('Hint: you do not have variable t in your workspace when VoltageTracePlot is run.\n')
end
if ~exist( 'V_m', 'var' )
    fprintf('Hint: you do not have variable V_m in your workspace when VoltageTracePlot is run.\n')
end

% *************************************************************************************
%                       Make the figure
% *************************************************************************************
figh = figure; % create a figure, and keep track of its handle (basically a variable that points to the figure). 
% You'll learn more about figure handles in lecture 4.


plot( t, V_m ); % note that when I enter two vectors, the first are x-values and the second are y-values. 
                % the vectors MUST be of the same length or you'll get an error
hold on         % This tells MATLAB not to replace the existing graph with the next one.
                % If you didn't have this, then when you try to add the scatter plot
                % it will overwrite the line-plot and you'll just see a scatter plot.
                % Try this out and see for yourself! This is a very common mistake.

% Now you need to add a command to create a scatter plot of the voltage trace data,
% Look through the help to find the appropriate command and how to call it. 
scatter( t, V_m ) 



% *************************************************************************************
%                 Add annotations and detail to the figure
% *************************************************************************************
 
title('Voltage trace', 'FontSize', 16, 'FontWeight', 'bold') % note an optional parameter to set font weight to bold. 
xlabel('time (ms)', 'FontSize', 14)  % note an optional parameter to set font size to 14. If I'd just written xlabel('time (ms)' ) it would default to size 10.
% Add an appropriate y label. 
ylabel('V_m (mV)', 'FontSize', 14) % DEV


% Uncomment these lines to further improve the appearance of your plot. 
% (you can try running it once with these commented out to see the difference)
% Note that the function gca is used to refer to the current axis ("Get Current Axis").
% We will discuss axis and figure handles in Week 4.
set(gca, 'FontSize', 12 ) % the FontSize property of an axis is the size of the axis numbers
ylim([-80 80]) % This sets the range of the y-axis. The equivalent for x-axis is xlim( [min max] )

if exist( 'restV', 'var' )
    line([0 50], [restV restV], 'LineStyle', '--', 'Color', [.5 .5 .5]) % makes a gray dotted line at the resting membrane voltage
else % restV doesn't exist : (
    fprintf(2,'Hey, you forgot to define a variable restV with the rest membrane voltage!\n') % the 2 at the front prints in red (error color). This is a pro trick.
    beep % makes a beep; used to get your attention!
end