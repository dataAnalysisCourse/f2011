% fasterCodeDemo.m
% NENS 230 Autumn 2011
%
% Demonstrates how to speed up your code:
% Part 1: Preallocation
% Part 2: No Display Output
% Part 3: Vectorization
% Part 4: Cellfun

          
% ---------------------------------------------
% Part I - Preallocation
%  ---------------------------------------------
% Let's say we want to record the squares of the
% first 2000 integers. Here we do it without preallocation,
% such that the variable squares grows with each loop.

N = 1000; % number of times to repeat each timing measurement. Lets me
          % me report in ms

tic
for iClock = 1 : N
    
    clear('squares')
    for num = 1 : 2000
        squares(num) = num^2;
    end
    
end
noPreallocT = toc;
fprintf('Without preallocating: %.2fs\n', noPreallocT);

%% Now do it with preallocation
tic
for iClock = 1 : N   
    clear('squares')
    
    squares = zeros(2000,1);
    for num = 1 : 2000
        squares(num) = num^2;
    end
end
preallocT = toc;
fprintf('With preallocating: %.2fs\n', preallocT);
fprintf('%.2fx improvement\n', noPreallocT/preallocT)

%% ---------------------------------------------
%         Part II - No display output
%  ---------------------------------------------
% This time display the square of each integer as 
% soon as it is calculated
N = 5;
tic
for iClock = 1 : N
    clear('squares')
    squares = zeros(2000,1);
    for num = 1 : 2000
        squares(num) = num^2;
        fprintf('The square of %i is %i\n', num, squares(num) );
    end
end
withOutputT = toc;
fprintf('With output: %.2fs total\n', withOutputT);

%% Now do it without output
tic
for iClock = 1 : N
    clear('squares')
    squares = zeros(2000,1);
    for num = 1 : 2000
        squares(num) = num^2;
        % still use a printf command to make it a more fair
        % comparison, but don't output it to anywhere
        sprintf('The square of %i is %i\n', num, squares(num) ); 
    end
end
withoutOutputT = toc;
fprintf( 'No output: %.2fs total\n', withoutOutputT);
fprintf( '%.2fx improvement\n', withOutputT/withoutOutputT )


%% ---------------------------------------------
%             Part III - Vectorization
%  ---------------------------------------------
N=5000;

% Non-vectorized
tic
for iClock = 1 : N
    clear('squares')
    
    squares = zeros(2000,1);
    for num = 1 : 2000
        squares(num) = num^2;
    end
    
end
nonVectorizedT = toc/5;
fprintf('Using a for loop: %.2fms\n', nonVectorizedT);

%% Vectorized
tic
for iClock = 1 : N
    
    clear('squares')
    integers = 1 : 2000; % create a vector of the numbers 
                         % we want squares of
    squares = integers.^2;
    
end
vectorizedT = toc/5;
fprintf('Vectorized: %.2fms\n', vectorizedT);

fprintf('%.2fx improvement\n', (nonVectorizedT/vectorizedT))





%% Using repmat
N = 1000;
% Let's say we have a bunch of current data, chans x samples
currents = rand(16,1000); % 16 channels, 1000 samples
% we want to transform it to voltage by multiplying by a different resistance
% for each electrode
resistances = [7e6 ; 7.2e6; 7.5e6; 9e6; 12e6; 9.2e6; 9.1e6 ; 8.8e6; ...
    6.5e6 ; 7.1e6; 7.1e6; 8.2e6; 6.9e6; 9.2e6; 9.0e6 ; 8.7e6];

% We can do this in two for loops, without preallocation:
tic
for iClock = 1 : N
    
    clear( 'voltages')
    for iChan = 1 : size( currents, 1 )
        
        for iSample = 1 : size( currents, 2 )
            voltages(iChan,iSample) = currents(iChan,iSample)*resistances(iChan);
        end
        
    end
end
nonVectorizedT = toc;
fprintf('The slow way: %.2fms\n', nonVectorizedT);

%% Or we can work our vectorization magic
tic
for iClock = 1 : N
    clear( 'voltages')

    % I want a matrix which is same size as currents, but looks like:
    % R1   R1   R1   R1  ... (1000 cols)
    % R2   R2   R2   R2  ...
    % ...
    % R16  R16  R16  R16 ...
    multiplyByThis = repmat( resistances, 1, size( currents,2 ) );
    voltages = currents .* multiplyByThis; %elementwise multiplicaiton


end
vectorizedT = toc;
fprintf('The fast way: %.2fms\n', vectorizedT);

fprintf('%.2fx improvement\n', (nonVectorizedT/vectorizedT))



%% ---------------------------------------------
%             Part IV - Cellfun
%  ---------------------------------------------
% Lets say we have some a cell array of spike times for 
% different trials, and we want to know the number of spikes 
% in each trial:
clear('spikeTimes')
spikeTimes{1} = [13 446 499 998];
spikeTimes{2} = [100 314];
spikeTimes{3} = [34 101 190 223 291 330 453 565 596 622 804 949];
spikeTimes{4} = [35 103 201 245 490 560 596 621 805 940];
spikeTimes{5} = [];
spikeTimes{6} = [343 435 534 848 890 907];
spikeTimes = repmat(spikeTimes', 100, 1); % now it's 600 trials

N = 100;

% We can do this in a loop, without preallocation:
tic
for iClock = 1 : N
    clear( 'spikeCounts')
    spikeCounts = zeros( length( spikeTimes ), 1 ); % preallocate
    for iTrial = 1 : length( spikeTimes )
        spikeCounts(iTrial) = numel( spikeTimes{iTrial} );
    end
end
nonVectorizedT = toc;
fprintf('The slow way: %.4fms\n', nonVectorizedT*10);

%% But we can do we better with vectorization using cellfun
tic
for iClock = 1 : N
    clear('spikeCounts')
    spikeCounts = cellfun( @length, spikeTimes );
    % Secret tip: replace @length with 'length' and it becomes
    % incredibly fast. 
    % That's a 3d degree black belt MATLAB ninja move right there.
end
vectorizedT = toc;
fprintf('The vectorized way: %.4fms\n', vectorizedT*10);
fprintf('%.2fx improvement\n', (nonVectorizedT/vectorizedT))
