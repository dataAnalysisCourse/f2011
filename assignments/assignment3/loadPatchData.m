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
%     neuronId - a numeric id for that neuron
%     opsin - string name of the construct
%     abfName - filename of the abf file

% Check that the file exists
if ~exist(fname, 'file')
    error('Cannot find database file %s', fname);
end

% Open the file and hold onto the file handle
fid = ???

% Build a format string which describes each line of the file
fmatStr = ???

% Now we use the format string with textscan to extract the data
% Pass in 'ReturnOnError', false as trailing arguments so that this function
% fails if the csv file isn't in the correct format. Then, we wrap the call
% in a try catch block, so that we can throw our own error.

try 
    C = textscan(???, ...
		'HeaderLines', ???, 'Delimiter', ???, 'ReturnOnError', false);
catch exception
    fprintf('Error reading patch data from %s\n', fname);
    rethrow(exception);
end

% Figure out how many patched neurons were in the file by looking at the
% size of C ( is it numel(C) or numel(C{1}) ? )

nPatched = ???

% Loop over the patched neurons loaded and build up the struct array

for ???
    
    patchData(???).??? = ???
    patchData(???).??? = ???
    patchData(???).??? = ???
    patchData(???).??? = ???
end

% Print a message saying how many neurons were loaded from the file
fprintf(???, ???);

% Close the file handle
fclose(fid);

end

