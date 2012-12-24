function patchData = loadPatchData( fname )
%LOADPATCHDATA Loads a patching database saved as a csv
% The file should have 1 header line, and then comma separated values in
% the following order:
%      Date, Neuron Number or ID, Opsin Name, ABF Name
%
% INPUTS
% fname - the name of the csv file to load
% 
% OUTPUTS
% patchData - a struct array with the following fields:
%     date - string representation of the date
%     id - a numeric id for that neuron
%     opsin - string name of the construct
%     abfName - filename of the abf file

% Check that the file exists
if ~exist(fname, 'file')
    error('Cannot find database file %s', fname);
end

% Open the file and hold onto the file handle
fid = fopen(fname);

% Build a format string which describes each line of the file
fmatStr = '%s %u %s %s';

% Now we use the format string with textscan to extract the data
% Pass in 'ReturnOnError', false as trailing arguments so that this function
% fails if the csv file isn't in the correct format. Then, we wrap the call
% in a try catch block, so that we can throw our own error.

try 
    C = textscan(fid, fmatStr, 'Delimiter', ',', 'HeaderLines', 1, ...
        'ReturnOnError', false);
catch exception
    fprintf('Error reading patch data from %s\n', fname);
    fclose(fid);
    rethrow(exception);
end

fclose(fid);

% Figure out how many patched neurons were in the file by looking at the
% size of C ( is it numel(C) or numel(C{1})? )

nPatched = numel(C{1});

% Loop over the patched neurons loaded and build up the struct array
patchData = struct();
for iPatch = 1:nPatched 
    patchData(iPatch).date    = C{1}{iPatch};
    patchData(iPatch).id      = C{2}(iPatch);
    patchData(iPatch).opsin   = C{3}{iPatch};
    patchData(iPatch).abfName = C{4}{iPatch};
end

% Print a message saying how many neurons were loaded from the file
fprintf('Loaded %d patched neurons from database\n', nPatched);

end

