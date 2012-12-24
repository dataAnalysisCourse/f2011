%% Generate synthetic spike trains using poisson model
clc

%select firing rat and length of sample
r = 150;
t = 1;

%generate spike trains
[s1, st1, ISIs AFR CV Fano] = HomoPoisSpkGen(r, t);
[s2, st2, ISIs2 AFR2 CV2 Fano2] = HomoPoisSpkGen(r, t);

%plot histogram of inter-spike intervals
figure(2); clf;
hist(ISIs,35)


%% plot cross-correlogram from the two synthetic spike trains
% show spike raster

figure(1); clf;
subplot('position', [.1 .7 .8 .25])
hold on
for i = 1:length(st1)
   line([st1(i) st1(i)], [.1 .9]); 
end
for i = 1:length(st2)
    line([st2(i) st2(i)], [1.1 1.9]); 
end

% plot cross correlogram
subplot('position',[.1 .1 .8 .5])
[tsOffsets, ts1idx, ts2idx] = crosscorrelogram(st1, st2, [-.2 .2]);
hist(tsOffsets,100)


%% Plot autocorrelogram

figure(4); clf;
[tsOffsets, ts1idx, ts2idx] = crosscorrelogram(st1, st1, [-.2 .2]);
hist(tsOffsets,100)


%% Plot Cross-Correlogram

load J20110809_M1
%unpack 'N' direction reaching data
d = reachingData(1).spikeTimes;

%select two cells, extract spike train for given trial
cell1 = 13;
cell2 = 50;
trial = 1;
s1 = d{trial,cell1}/1000;   %convert to seconds from 
s2 = d{trial,cell2}/1000;

% show spike raster
figure(5); clf;
subplot('position', [.1 .7 .8 .25])
hold on
for i = 1:length(s1)
   line([s1(i) s1(i)], [.1 .9]); 
end
for i = 1:length(s2)
    line([s2(i) s2(i)], [1.1 1.9]); 
end

%show cross correlogram
subplot('position',[.1 .1 .8 .5])
[tsOffsets, ts1idx, ts2idx] = crosscorrelogram(s1, s2, [-.4 .4]);
hist(tsOffsets,100)
xlabel('Time offset (s)')
ylabel('Count')
title('Cross Correlogram')


%% Plot Autocorrelogram

%select two cells, extract spike train for given trial
cell1 = 49;
trial = 1;
s3 = d{trial,cell1}/1000;   %convert to seconds from 

% show spike raster
figure(5); clf;
subplot('position', [.1 .8 .8 .1])
hold on
for i = 1:length(s3)
   line([s3(i) s3(i)], [.1 .9]); 
end
title('Raster Plot')

%show cross correlogram
subplot('position',[.1 .1 .8 .6])
[tsOffsets, ts1idx, ts2idx] = crosscorrelogram(s3, s3, [-5 5]);
hist(tsOffsets,100)
xlabel('Time offset (s)')
ylabel('Count')
title('Cross Correlogram')

figure(6); clf;
hist(diff(s3),100)
title('Inter-spike interval')
xlabel('Interval (s)')
ylabel('count')








