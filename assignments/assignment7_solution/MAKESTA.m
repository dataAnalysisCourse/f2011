% MAKESTA script
%
% NENS 230 Autumn 2011
%
% This is the start point. You will want to edit SpikeTriggeredAverageStimulus
% and possibly break it into subfunctions. Follow the best practices lecture
% to improve the following aspects of the code:
%     1. Add proper documentation and comments
%     2. Use sensible function and variable names.
%     3. Use good style; make the code neat and readable
%     4. Break the single function down into useful, logical functions.
%     5. Improve the performance. Preallocation and vectorization are the 
%        lowest hanging fruit. 
%        * If you feel ambitious, there is a slight change
%        in the algorithm that can really speed things up. Hint: do you really 
%        need all the intermediate results? Note: this makes only a marginal
%        performance improvement.
%        * Another hint: do you need to look at all the spikes if there isn't
%         stimulus accompanying it?
%
%     The plotStimAndSpikes function is not part of the assignment. 
%     YOU DO NOT NEED TO IMPROVE plotStimAndSpikes.m
%     It's just there to help you see what kind of 
%     data this is. STA over thousands of spikes appears to be magic in that
%     you can pull out a meaningful  response function of a neuron from a seemingly
%     random jumble of stimulus and spikes.
% 



tic 
% ignore first 3 seconds of data; plot average stimulus from 0 to 500ms 
% preceding each spike.
SpikeTriggeredAverageStimulus( 'RGCspikes', 'VisualStim', 1:10:500, 3*1000 ) ;
toc