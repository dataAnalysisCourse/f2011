%% Demonstrate the one-way anova
groupMeans = [0 1 2 3];

noiseSD = 4;
nSubjects = 100;

nGroups = length(groupMeans);
groupNames = cell(1,nGroups);
data = zeros(nSubjects, nGroups);

for iGroup = 1:nGroups
    data(:, iGroup) = randn(nSubjects,1)*noiseSD + groupMeans(iGroup);
    groupNames{iGroup} = sprintf('Group %d', iGroup);
end

[p table stats] = anova1(data, groupNames, 'on');
fprintf('p-value from ANOVA1: %g\n', p);

fprintf('\n');

%% Perform interactive multiple comparisons testing

[c,m] = multcompare(stats);

%% Demonstrate the n-way anova

nSubjects = 100;

factorNames = {'Age Group', 'Treatment Group'};

% each mouse belongs to one of two age groups
ageGroupNames = {'young', 'old'};
ageGroupId = randi(numel(ageGroupNames), nSubjects, 1);
ageGroup = ageGroupNames(ageGroupId);

% each mouse belongs to either the control group, drugA, or drugB
treatmentNames = {'control', 'drugA', 'drugB'};
treatmentGroupId = randi(numel(treatmentNames), nSubjects, 1);
treatmentGroup = treatmentNames(treatmentGroupId);

% simulate there being a real linear relationship corrupted by noise
ageOffsets = [0 50];
treatmentOffset = [0 20 70];
noiseSD = 80;

assayScore = randn(nSubjects, 1) * noiseSD + ...
    ageOffsets(ageGroupId)' + treatmentOffset(treatmentGroupId)';

% Test for effects of age, treatment, and interaction of age x treatment
[p t stats terms] = anovan(assayScore, {ageGroup treatmentGroup}, ...
    'varnames', factorNames, 'model', 'interaction');

fprintf('Main effect of %s: p = %.10f\n', factorNames{1}, p(1));
fprintf('Main effect of %s: p = %.10f\n', factorNames{2}, p(2));
fprintf('Interaction %s x %s: p = %.10f\n', factorNames{1}, factorNames{2}, p(3));


% Test for significant differences among the treatment groups
multcompare(stats, 'dimension', 2);



