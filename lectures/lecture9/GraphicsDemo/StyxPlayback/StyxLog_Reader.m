% StyxLog_Reader
% Parses a .styxlog file (a record of everything that happens during a Styx
% game) and returns a Matlab cell array of each event. 
% Works for games using StyxLogger Version 1.0.
%
% INPUTS:
%       filename    name (and path if it's not in current directory) of the
%                   .styxLog file to be read.
% OUTPUTS: 
%       out         cell array that is Nx5, where N is the number of
%                   styxLog events and 5 is the number of columns in
%                   styxLogs. As of StyxLoggerVersion 1.0 there were 5
%                   log columns. If this changes, the textscan formatting
%                   below should be changed accordingly. 
%
% (c) 2010 Sergey Stavisky   The BrainGate Project

function out = StyxLog_Reader( filename )
% a preliminary .styxlog reading function
      fid = fopen( filename );
      C = textscan(fid, '[%s [%s [%s [%s [%s', 'delimiter', ']');
      
      % unpack such that instead of 1x5 cells it is Nx5.
      out = cell( length(C{1}), length(C) );
      for i = 1 : length(C)
          out(1:length(C{i}),i) = C{i};
	  end
      
	  fclose( fid );





end