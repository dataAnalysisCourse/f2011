% Used to search through a styxLog for specific search terms specified
% as column-number value pairs.
% INPUTS:
%     styxLog            cell array returned by StyxLog_Reader
%     search-parameter pairs:
%        colNum          which of the styxLog columns to search for
%                        this keyword.
%        searchTerm      search term to look for in that column. Note
%                        that (for now) exact matches are sought.
% OUTPUTS:
%     matchingLines      cell array of the same type as styxLog containing
%                        just those lines which match the search terms
%                        specified.
%     indices            the row number from styxLog corresponding to each 
%                        line in matchingLines.
%
% USAGE:
%      [matchingLines indices] = SearchStyxLog( myStyxLog, 2, 'STATE', 4,
%      ... 'trueState')
function [matchingLines indices] = SearchStyxLog( styxLog, varargin )
% I'll do the search one column-searchterm pair at a time. Then I'll find
% the intersection of the returned lines to get the final indices. I store
% the results of each column search in an entry of matchVecs. So if there
% are 3 pairs of col-searchterm, then matchVec is a 3x1 cell array.

matchVecs = cell(0);
for pair = 1: 2 : length( varargin )
    col = varargin{ pair };
    searchTerm = varargin{ pair+1 };
    
    % search the appropriate column for the searchTerm
    matchVecs{end+1} = cellfun( @strcmp, styxLog(:,col), repmat({searchTerm}, size( styxLog,1),1) );
end %for searchpair = 1: 2 : length( varargin )

% output the indices, which is the overlap between the matchVecs
indices = matchVecs{1};
for i = 2 : length(matchVecs)
    indices = indices .* matchVecs{i};
end
% convert to entry as opposed to logical indexing
indices = find(indices);

% get the matchingLines
matchingLines = styxLog(indices,:);


end