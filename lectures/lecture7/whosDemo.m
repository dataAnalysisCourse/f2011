% whosDemo.m
% NENS 230 Autumn 2011
%
% Demonstrates checking how much memory variables are consuming using
% whos.

% Make variables
a = 1;

b = rand(10);

c = 'A string!';

reallyBig.field1 = rand(100);
reallyBig.field2 = 'This variable is meaty!';
reallyBig.field3 = zeros(1000,500,100);

%% Let's see how big they are
whos

%% Can store this into a variable
sWhosOutput = whos


%% Let's report how much memory <reallyBig> is taking up, in MB:
reallyBigInfo = whos('reallyBig');

fprintf( '%s is %.0f MB\n', ...
    reallyBigInfo.name, reallyBigInfo.bytes/10^6)


