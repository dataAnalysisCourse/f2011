% timingExample.m
% NENS 230 Autumn 2011
%
% Demonstrates timing how long pieces of code take using tic and toc


%% tic and toc lets you see how long a function takes

% Let's see how long a few operations takes:
A = rand(50); %50x50 random matrix

tic
B = inv(A);   %calculate matrix inverse
traceB = trace( B );
toc

%% For very fast operations, estmate is noisy. So run it 
% many times and report mean.
N = 10000;
tic
for i = 1 : N
    clear('B')
    B = inv(A);   %calculate matrix inverse
    traceB = trace( B );
end
fprintf('Mean execution time is %fs\n', toc / N )



%% Let's time one of the programs we've written already:
% We'll time the execution of Assignment 4's Reach Figure.
% Make sure Assignment4 is on your path. For those following 
% at home, you'll want to change this to match your own path.
addpath('/Users/sstavisk/Dropbox/NENS230/Assignment4_Solution');

tic;
figh = MakeReachingFigure_timingEx( 'J20110809_M1', 16 );
toc
close( figh );

%% Now go into makeReachingFigure_timingEx and uncomment the TIMING lines
% to see how to have more than one "stopwatch" running at once.

