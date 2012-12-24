% LabNotebook.m
%
% This function serves to keep an exact record of the stimuli-generating
% code used to run a particular experiment. It relies on the investigator
% calling LabNotebook() on each command-string that will start a
% stimulus-generating function. LabNotebook() then records that command,
% <commandstr> along with the time at which it was executed, in a .txt
% file. It also saves a copy of the .m file called by <commandstr>. Both
% the ExperimentStimulus_DATETIMESTR and the .m files are saved in a
% directory specified by the <saveDir> parameter. 
%
% NOTE: This will not find the .m files of functions called in commandstr 
% which are subfunctions (i.e. name of their mfile is not same as the 
% function). But you shouldn't be calling subfunctions out of scope anyway!
%
% USAGE:
%       filename = LabNotebook( commandstr, saveDir (,filename) )
%
% INPUTS:
%       commandstr   string (eval()-able) that calls a stimulus-generating
%                    function. It will be saved in the .txt file and also
%                    parsed to find the function, a copy of which will be
%                    saved in <saveDir>. 
%       saveDir      directory where all generated experiment records will
%                    be saved.
%       (,filename)  (optional) if a <filename> is provided then
%                    will append to this file instead of creating a new
%                    one. Note that <filename> can include a path.
% OUTPUTS:
%       filename    name of the created .txt file. Note that <filename> can
%                   include a path.
%
%
% Created by Sergey Stavisky on October 21, 2010
% Last modified by Sergey Stavisky on October 25, 2010

function filename = LabNotebook( commandstr, saveDir, filename )
% ----------------------------------------------------------------
%        Check that saveDir exists. If it doesn't, create it.
% ----------------------------------------------------------------
if ~isdir( saveDir )
    mkdir( saveDir )
    fprintf('[LabNotebook] Created directory %s\n', saveDir )
end
% make sure saveDir has a filesep after it so it can be used as a path in
% creating filenames.
if ~strcmp( saveDir(end), filesep )
    saveDir(end+1) = filesep;
end

% ----------------------------------------------------------------
%                Save commandstr to a text file
% ----------------------------------------------------------------
% Try to open filename if it is provided and is a legit file. Otherwise
% create a new file.
if nargin == 3
    fid = fopen( filename, 'a' );
    if fid < 0 % if failure to open given filename, warn user and create a
        % new file as if no filename was provided.
        fprintf('[LabNotebook] Could not open provided filename %s.\n', filename);
        filename = [saveDir 'ExperimentStimuli_' datestr(now, 'yyyy_mm_dd_HH_MM_SS.txt')];
        fid = fopen( filename, 'a' );
        if fid < 0
            error('Could not open file %s',fid)
        end
        
    end
else % Create the filename
    filename = [saveDir 'ExperimentStimuli_' datestr(now, 'yyyy_mm_dd_HH_MM_SS.txt')];
    fid = fopen( filename, 'a' );
    if fid < 0
        error('Could not open file %s',fid);
    end
end

% Write datestamp and commandstr to the .txt file
fprintf( fid, ['\n[' datestr(now, 'yyyy_mm_dd_HH_MM_SS') '] '] );
fprintf( fid, commandstr );
    
% ----------------------------------------------------------------
%      Find the .m function called in commandstr and save a copy
% ----------------------------------------------------------------
% I take advantage of the fact that there will be an open perentheses
% immediately after each function. So, I find each open perentheses, find
% the word before it, and check if it's an m function. If it is, I make a
% copy of it in saveDir

commandstr = [' ' commandstr];% add a space at the start of commandstr; 
% gets rid of an edge condition in insubsequent logic
openParenIndices = find( commandstr == '(' );
spaceIndices = find( commandstr == ' ');
for paren_i = 1 : length( openParenIndices ); % for every open parenthesis..
    % FIND NAME OF PUTATIVE FUNCTION CALLED
    tau = openParenIndices(paren_i)-spaceIndices;
    % The smallest positive tau is the space preceding the function name
    % we're looking for
    startOfFunctionName = openParenIndices(paren_i) - min( tau(tau>0) )+1;
    functionName = [commandstr(startOfFunctionName:openParenIndices(paren_i)-1) '.m']; % adding .m prevents it from finding variables with this name
    pathAndFunction = which( functionName ); % find this putative function if it is indeed a m-file
   
    % COPY .m FILES CONTAINING FUNCTIONS CALLED TO <saveDir>
    if ~isempty( pathAndFunction ) % hurray, we've found a .m file called in this command
        status = copyfile(pathAndFunction, saveDir ); % note:if it already exists in saveDir, new copy will overwrite old copy
        if ~status % copy failed
           fprintf('[LabNotebook] Warning: Unable to copy %s to %s\n', pathAndFunction, saveDir);
        end
    end % if ~ismepty( pathAndFunction )
    
end %for paren_i = 1 : length( openParenIndices );

    
% CLEANUP
fclose(fid);

end % function