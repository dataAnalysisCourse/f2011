% varCloudEx.m
% NENS230 Autumn 2011
% Demonstrates the plotting of mean +- std with translucent variance clouds

% Generate some data
mean1 = rand(50,1)*5+50;
mean2 = rand(50,1)*2+42;

std1 = rand(50,1)*10;
std2 = rand(50,1)*7;

% generate std values

plotWithVarianceClouds( {mean1, mean2}, {std1, std2}, [], [1 .1 0 ; 0 .2 1], [], [])