%% Demonstrate the meaning of the significance threshhold by simulation

% We're going to repeatedly run t-tests on data generated from a zero-mean
% normal distribution and see what percentage come up significant at varing
% significance thresholds

% Number of times to simulate, make this large
nRepeats = 1000;

significanceThresh = 0.05;

useNullDistribution = false;

% Generating distribution
if useNullDistribution
    mu = 0;
else
    mu = 5;
end
sigma = 1;
nSamples = 10;

result = zeros(nRepeats, 1);

for iRep = 1:nRepeats
    % generate samples
    samples = randn(nSamples,1)*sigma + mu;

    % Test the hypothesis that these samples were generated with non-zero mean
    [sig p] = ttest(samples, 0, significanceThresh);

    result(iRep) = sig;
end

%% Print out the results

if useNullDistribution
    % figure out how many false-rejections there were
    nFalseRej = nnz(result);
    
    fprintf('%d / %d (%.3f %%) False rejections at thresh %.3f\n', ...
        nFalseRej, nRepeats, nFalseRej/nRepeats*100, significanceThresh);
else
    % figure out how many times we successfully rejected the null
    % hypothesis
   nTrueRej = nnz(result);
   
   fprintf('%d / %d (%.3f %%) True rejections at thresh %.3f\n', ...
       nTrueRej, nRepeats, nTrueRej / nRepeats*100, significanceThresh);
end



