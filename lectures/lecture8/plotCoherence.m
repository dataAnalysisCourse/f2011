% plotCoherence.m
%
% NENS 230 Autumn 2011
%
% Helper Function to plot coherence
% INPUTS:
%    f     frequencies used (x axis)
%    C     coherences at each frequency
%    Cerr  Jackknife error (lower, upper)
% OUTPUTS:
%    figh    figure handle


function figh = plotCoherence( f, C, Cerr )
    % plot frequency versus coherence
    figh = figure; 
    hold on
    plot( f, C, 'LineWidth', 3)
    % Let's also plot its error bars
    plot( f, Cerr(1,:), 'LineWidth', .5, 'Color', 'k')
    plot( f, Cerr(2,:), 'LineWidth', .5, 'Color', 'k')
    ylim([0 1])
    xlabel('Frequency (Hz)', 'FontSize', 16)
    ylabel('Coherence', 'FontSize', 16)
end