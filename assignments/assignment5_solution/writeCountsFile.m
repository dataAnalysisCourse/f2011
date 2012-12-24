% writeCountsFile.m
%
% Takes the <cells> structure created by the cellCount tool and writes the
% data contained in this structure to a .txt file whose name and location 
% is specified by the user.
%
% USAGE:
%  binnedMat = binSpikeTimes( spikeTimes, binT, startT, endT )
%
% INPUTS:
%      cells              contains a .x and .y field, with elements for each
%                         cell identified/located.
%      fileFullPathName   Path and name of the .txt file to create
% OUTPUTS:
%      status             -1 if the operation failed, 0 if it succeeded.
% Created by Sergey Stavisky on 25 October 2011


function status = writeCountsFile( cells, fileFullPathName )
    status = -1; % unless we succeed, return failure.
    
    fid = fopen( fileFullPathName, 'w' ); % Open a file for (w)rite
    if ~fid % file didn't open
        fprintf('Could not open file\n')
        return
    end
    % First Line: Announce what this is and when it was created
    % Note that if you provide a fileid <fid> to fprintf, it prints to this
    % file rather than to the MATLAB command line. Otherwise it's the same.
    fprintf(fid, 'Cell Counting Results. Counting is from %s\n', datestr(now) );
    
    % Second Line: Write down total number of cells
    numCells = length( cells.x );
    fprintf(fid, '%i Total Cells Counted\n', numCells );

    % Now record each cell's x and y position.
    for iCell = 1 : numCells
        fprintf(fid, 'Cell %-4i x: %-6.2f um, y: %-6.2f um\n', iCell, cells.x(iCell), cells.y(iCell) );
    end %for iCell = 1 : numCells
    
    % Close the file. If you don't properly close a file after writing to it,
    % it might be unreadable.
    status = fclose( fid ); 
end % function