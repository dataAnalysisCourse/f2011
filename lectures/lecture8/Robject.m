% Robject CLASS
% I'm going to try defining an object to encapsulate the "R-struct" data
% format used by the prosthetics team. The goal is to make some commonly
% used manipulations and search functions into methods. 
%
% I'm not going to be too strict about enforcing that all the properties
% are filled, etc. I just want a nice packaging of the data, rather than
% ironclad guarantees that certain things get done.
%
% NOTE: The way I'm building it now, the Robject is still limited to a
% subset of one R struct, i.e. I can't treat every trial as self-contained
% such that they can be combined from multiple Rstructs. If I want to move
% in that direction, I'll need to either modify the way this object works,
% or create some export method which outputs independent trial objects. 
% Having the current assumptions means, for example, I don't need to worry
% about different arraySources, etc.

% NOT a handle object. So remember to use obj = method( obj ) syntax if you want to 
% modify it.

% SDS April 21 2011

classdef Robject
    properties
        sR % this is the big structure, .R in the original mat file
        origin % path where this Robj came from 
        subsetInds = {}; % if this Robject is made from subselecting trials from
                         % a different Robject using the SubsetRobject
                         % method, this property keeps track of what indices were
                         % used to create it. Each additonal subselection
                         % adds to the next cell of subsetInds
        arraySource;     % When the Robject is created, this should be filled out with
                         % the .dir and .extension for finding the
                         % continuous neural data for this Robject.
                         % Example: 
                         %   arraySource{1}.dir = '/net/data/JenkinsC/rawdata/2011-04-19/cerebus/M1/';
                         %   arraySource{1}.extension = 'ns3';
        contDat = [];    % continuous data will be stored for each trial here. Each trial gets a contDatObject
                         % so this variable is an array of contDataObject of length numTrials.
                         
    end % public properties
    
    properties (Dependent = true, SetAccess = private)
        numTrials % how many trials are in this object
        numArrays % how many arrays were being used
    end % dependent properties
    
    
    
    
    methods   
        %                   CONSTRUCTOR
        function obj = Robject( varargin )
        % Constructor
            if mod( length(varargin), 2 )
               error('[%s] Robject constructor must be called with even number of arguments (property-value pairs)', mfilename) 
            end
            
            % Property-Value Pair construction
            for i =  1 : 2 : length( varargin )
                obj.(varargin{i}) = varargin{i+1};
            end
          
   
        end %function obj = Robject( varargin )

        %*********************************************************
        %                   Set/Get Methods   
        %*********************************************************
        function numTrials = get.numTrials( obj )
           numTrials = length( obj.sR );
        end
        
        function numArrays = get.numArrays( obj )
            % Returns how many arrays worth of data there are for this Robject
            if isfield(obj.sR(1),'spikeRaster2') && any(any([obj.sR(1).spikeRaster2]))
                numArrays = 2;
            else
                numArrays = 1;
            end
        end
        

        %*********************************************************
        %                    Search Methods
        %*********************************************************
        function trialsLogical = TrialwiseCompare(obj, field, value, tolerance) 
            % This is the slow, looping search function into sR, which is needed to
            % look into the nested structures such as sR.startTrialParams.saveTag.
            % It will go through each trial and test whether the value of 
            % sR(i).<field> == value and return a logical vector of length
            % numTrials. 
            % WARNING: This is SLOW and should only be used for the nested
            % fields. Use the [Robject.sR.field] syntax for the top-level
            % fields. 
            %
            % USAGE: TrialsLogical = object.trialwiseCompare( '.startTrialParams.saveTag', 2)
            % 
            % EXAMPLE:  matchingTrialBool = allTrials.TrialwiseCompare( '.startTrialParams.saveTag', 3, 1e-6);
            %
            % INPUTS:
            %     field    string for which field of the .sR structure to
            %              search through, e.g '.startTrialParams.saveTag'.            
            %     value    equality check this value against each trial's
            %              value of <field>. If vectors are being compared,
            %              all elements must equal.
            %     tolerance (optional) does numerical equality comparison with this 
            %              tolerance. Useful when very very small differences may be present
            % OUTPUTS:
            %     trialsLogical   boolean vector specifying which trials
            %              have their <field> contain <value>
            %  
            if field(1) == '.' % ignore the initial '.' in <field>
                field = field(2:end);
            end
            
            
            trialsLogical = false( obj.numTrials, 1 ); % preallocate output
            
            sRstruct = obj.sR; % Needed for parfor to work
            
            if nargin <= 3 % no tolerance set
                tolerance = eps;
            end
               
            % Okay, I have to do crazy annoying things here to get this to parallelize, basically to
            % use dynamic field names instead of eval. So, I see how deep field goes, and if it's sane I 
            % do things parallelized, otherwise not.
            fp = fieldnameArray( field );
            
            switch length( fp )
                case 1
                    a = fp{1}; % slicing for parfor
                    parfor i = 1: obj.numTrials                        
                        trialsLogical(i) = ~any( abs( sRstruct(i).(a) - value ) > tolerance  );
                    end
                case 2
                    a = fp{1}; b = fp{2};
                    parfor i = 1: obj.numTrials
                        trialsLogical(i) = ~any( abs( sRstruct(i).(a).(b) - value ) > tolerance  );
                    end
                case 3
                    a = fp{1}; b = fp{2}; c = fp{3};
                    parfor i = 1: obj.numTrials
                        trialsLogical(i) = ~any( abs( sRstruct(i).(a).(b).(c) - value ) > tolerance );
                    end
                case 4
                    a = fp{1}; b = fp{2}; c = fp{3}; d = fp{4};
                    parfor i = 1: obj.numTrials
                        trialsLogical(i) = ~any( abs( sRstruct(i).(a).(b).(c).(d) - value ) > tolerance );
                    end
                case 5
                     a = fp{1}; b = fp{2}; c = fp{3}; d = fp{4}; e = fp{5};
                    parfor i = 1: obj.numTrials
                        trialsLogical(i) = ~any( abs( sRstruct(i).(a).(b).(c).(d).(e) - value ) > tolerance );
                    end
                otherwise % don't parfor
                    fprintf('[%s:TrialwiseCompare] Cannot parallelize because %s is more than 5 nested fields deep and I havent hardcoded this far.\n',...
                        mfilename, field);
                    dotfield = ['.' field ];
                    compareFunc = eval(['@(x) abs( sR(x)' dotfield ' - value) > tolerance']);                    
                    for i =  1 : obj.numTrials
                        trialsLogical( i ) = ~any( compareFunc(  i  ) );
                    end
            end
            
           
        end %function trialInds = FindSavetag(obj, savetag)
        
        function cellOut = TrialwiseEval( obj, command, noOutput ) %#ok<INUSD>
           % USAGE: cellOut = TrialwiseEval( command )
           % EXAMPLE: contDatNumSamples = [TrialwiseEval( myTrials, 'size( obj.contDat{trial_i}.raw.dat, 2' );
           % INPUTS:
           %     command     string that is evaluated within a for trials_i = ... end loop.
           %     noOutput    (optional) if there's anything as this argument, won't try to return anything into cellOut
           % OUTPUTS:
           %     cellOut     cell array with same length as obj.numTrials; each cell contains the output of
           %                 of <command> when called on the corresponding trial.
           %
           % A handy recursive evaluation function. Loops through every trial of this Robject
           % and calls the command specified. The output of this command is stored in cellOut{trial_i}
           % Note: "trial_i" is a special keyword in command, in that this function loops through every trial
           % of Robject using trial_i as the
           if nargin < 3
               noOutput = false;
           else
               noOutput = true;
           end
           
           if noOutput
               cellOut = [];
               for trial_i = 1 : obj.numTrials
                   eval( command );
               end
           else               
               cellOut = cell( obj.numTrials, 1 );
               for trial_i = 1 : obj.numTrials
                   cellOut{trial_i} = eval( command );
               end
           end %if noOutput
        end %function cellOut = TrialwiseEval( obj, command, noOutput )
        
        %*********************************************************
        %                   Self-Evaluation Methods 
        %*********************************************************
        function trialsLogical = IdentifyBizarreTrials( obj )            
            % A data cleanup method; will go through and return logical indices 
            % that are true for trials which 
            % have indicators that I've found to indicate a trial with some flaw
            % in how the data is recorded. As I find more bugs, this method will
            % be expanded. So far it removes trials that exhibit:
            %    CHECK 1.) Length of timeCerebusStart is substantially more than trialLength (i.e. more than
            %              100 samples (at 1kHz) longer)
            % NOTE: This method is fairly slow, so it's best to run it after other paring down has already happened.
            trialsLogical = false( obj.numTrials, 1 );
            for trial_i = 1 : obj.numTrials
                
                % CHECK 1
                if length( obj.sR(trial_i).timeCerebusStart ) > obj.sR(trial_i).trialLength + 100
                    if verboseGlobal
                        fprintf('[%s: IdentifyBizarreTrials] Marking trial %i for failing Check #1\n', mfilename, trial_i)
                    end
                    trialsLogical(trial_i) = true;                    
                end                
                
            end %for trial_i = 1 : obj.numTrials
            
        end
       
        function trialsLogical = TrialsWithLongBlinkouts( obj, maxAllowableBlinkoutSamples )
            % returns logical indices for all trials that have more than <maxAllowableBlinkoutSamples> 
            % in the hand position.
            
            % CONSTANTS
            NO_MARKER_SEEN = -1;
            
            % Default Parameters
            if nargin < 2
                maxAllowableBlinkoutSamples = 400;
            end            
                      
            trialsLogical = false( obj.numTrials, 1);
            
            R = obj.sR;
            parfor trial_i = 1 : obj.numTrials
                % process blinkOuts                
                blinkOut = find( R(trial_i).numMarkers == NO_MARKER_SEEN );
                
                contigBlinkOut = 0;
                for j = 1 : length(blinkOut)-1
                    if (blinkOut(j+1) - blinkOut(j)) == 1
                        contigBlinkOut = contigBlinkOut + 1;
                    else
                        contigBlinkOut = 0;
                    end
                    if contigBlinkOut > maxAllowableBlinkoutSamples

                        trialsLogical(trial_i) = true;
                    end
                end %for j = 1 : length(blinkOut)-1                
                
            end %parfor trial_i = 1 : obj.numTrials
        end %function trialsLogical = TrialsWithLongBlinkouts( obj, maxAllowableBlinkoutSamples )
            
        %*********************************************************
        %              Object Modification Methods
        %*********************************************************
        function newobj = SubsetRobject(obj, inds)
           % returns a new Robject which is a subset of trials from the original 
           % obj. <inds> can also be logical vector.
           
           % I want this method to be very forgiving, so if a logical indexing 
           % (or even non-logical but only 1s and 0s inde
           if islogical( inds ) % convert from logical to index selection if necessary
               if length( inds ) == obj.numTrials
                   inds = find( inds );
               else
                   error('[%s] Logical indices were provided, but length of the vector didn''t match length of the input Robject', mfilename)
               end              
           end %if islogical(inds)
           
                    
           % Initially create a new Robject as a clone of the current one
           newobj = obj;
           
           % Most importantly, it's .sR is the specified subset of the
           % original Robject, and its .contDat
           newobj.sR = obj.sR(inds);
           
           % Copy over appropriate .contDat
           if ~isempty( obj.contDat )
               newobj.contDat = obj.contDat(inds);
           end %if ~isempty( obj.contDat )
           
           % Add the indices to create this subset of trials to the end of 
           % the list in the .subsetInds
           newobj.subsetInds{end+1} = inds;

        end %function newobj = SubsetRobject(obj, inds)
                
        function newobj = cat( obj, varargin )
        % Combines several Robjects into one longer Robject containing all of the trials
        % Note that combining Robjects gets rid of a lot of the source information,
        % i.e. .origin, .subsetInds, .arraySource are all thrown out.
            if length(varargin) == 1
                error('Concatenating Robjects requires horizontal concat, due to some weird bug in the vertcat handling on MATLAB''s part')
            end
            

            newobj = Robject;
            newobj.origin = 'combined from multiple Robjects';
            for i = 1 : length( varargin )
                newobj.sR = [newobj.sR varargin{i}.sR];
                newobj.contDat = [newobj.contDat varargin{i}.contDat];         
            end %for i = 1 : length( varargin )
            
        end
        
        % All concatenation (vertical or horizontal) is really the same
        function newobj = horzcat(  varargin ) 
            newobj = varargin{1}.cat( varargin{:} );
        end
        function newobj = vertcat( varargin )
            newobj = varargin{1}.cat( varargin{:} );
        end
        
        %*********************************************************
        %             Neural Data Import Methods
        %*********************************************************
        function obj = GetLinkedContDat( obj, alignto, alignparam )     
            % INPUTS:
            %   alignTo   (optional) specify where t=0 (in the trial) data
            %             is aligned to. Options are:
            %                'target_onset' 
            %                'movement'   
            %              Defaults to 'target_onset' if no argument is provided.     
            %   alignparam can be used to pass parameterd to the alignment mode.
            %        .kinematicsType   can be either 'cursor' or 'hand'; determines
            %                          whether the handPos or cursorPos is used.
            % Gets a ContDatObject with the continuous neural data that
            % corresponds to each trial. Don't forget that Robject isn't
            % a handle object, so call myTrials = GetLinkedContDat( myTrials).
            
            % CONSTANT PARAMETERS
            bufferSecs = 1; % grab this many seconds of data on each side of a trial
            NSPSAMPLERATE = 30000;
            MAXALLOWEDNSPTIME = 10^9; % gtw this and I assume its a corrupted value
            MINALLOWEDNSPTIME = 0; % lte this and I assume it's a corrupted value
            MAXCHANSPERARRAY = 96; % channelID for channel 1 on second array thus becomes 1 + MAXCHANSPERARRAY
            % DEFAULT ARGUMENTS
            if nargin < 2
                alignto = 'target_onset';
            end
            if nargin < 3
                alignparam = [];
            end
            fprintf( '[%s: GetLinkedContDat] Will align data to %s\n', mfilename, alignto );
            
            
            % See if there's a second array
            numArrays = length( obj.arraySource );
            % Note to self: fields like timeCerebusStart2 exist no matter what.
        
            
            
            % All this is repeated for each array; I'll collapse it onto
            % one variable (which might have 96 or 192 channels) later to
            % make things simpler.
            for array_i = 1 : numArrays
                
                % STEP 1:
                % Compute the start and end cb time for the neural data I'm
                % interested in for these trials.
   
                % the field name changes depending on which array it is
                myStartFieldName = 'timeCerebusStart';
                myEndFieldName   = 'timeCerebusEnd';
                if array_i > 1
                    myStartFieldName = [myStartFieldName mat2str( array_i )];
                    myEndFieldName = [myEndFieldName mat2str( array_i )];
                end
                
                startCbTimes = [obj.sR(:).(myStartFieldName)];
                endCbTimes = [obj.sR(:).(myEndFieldName)];
                
                % I've noticed in at least one file (Jenkins M1 20110809-114244-001.ns3)
                % that there is some corruption in the R struct timeCerebusEnd, manifesting
                % as zero values or very high values. The very high values make the maxCbTime
                % exceedingly high so it appears that no file contains the data I'm looking for.
                % To get around this, I make NaN any value that is above 10^9, which is an arbitrary
                % threshold implying an NSP running for over 9 hours, which seems exceedingly unlikely
                % in the rigC regime (but may happen for freely moving monkeys!) Note that these values might
                % not be at the start or end of the trial and so *hopefully* will not affect extracting data
                % especially since I now allow myself to look at the second (or second-to-last) timestamp
                % when finding individual trial myNSPstartT myNSPendT if the first attempt returns a corrupted value.
                % However, if it fails on the adjascent timestamp I will throw an error. Note that this check 
                % is subject to the accuracy of my constant max/min values (defined at top of the function), and I have
                % little confidence that these prevent false negatives.
                endCbTimes(endCbTimes >= MAXALLOWEDNSPTIME) = NaN;
                
                
                minCbTime = min( startCbTimes ) / NSPSAMPLERATE; % divide by 30ksps to convert to seconds
                maxCbTime = max( endCbTimes ) / NSPSAMPLERATE;
                
                % STEP 2:
                % Check which .nsx files contain the neural data I'm
                % interested in by comparing the minCbTime and maxCbTime I
                % want with the TimeStart and TimeEnd in each file. 
                if ~isempty( obj.arraySource{array_i}.dir ) % If it's empty then I assume this array doesn't exist
                    fileList = subdir( [obj.arraySource{array_i}.dir '*.' obj.arraySource{array_i}.extension] );
                    
                   
                    foundMatchingNSX = false; % If it finds two matching files, that both have the data I'm looking for,
                                              % it will throw an error. The specific data sought should only exist in one file.
                    
                    for file_i = 1 : length( fileList )
                        fprintf('[GetLinkedContData] File: %s... ', fileList(file_i).name)
                        NSX = NSX_open( fileList(file_i).name ); % open the file
                        fprintf(' OPEN... ');
                        [NSXdata NSXtime] = NSX_read( NSX );
                        fprintf('READ\n')
                           
                        if (min( NSXtime ) <= minCbTime) && (max( NSXtime ) >= maxCbTime ) 
                            % Match; this .nsx file contains the cb timestamps of interest 
                         
                            % STEP 3:
                            % Now let's make sure that the chronos
                            % counters for these trials that the R struct believes it sent
                            % match the chronos counters in the .nev file
                            % corresponding to this .nsx file.
                            
                            % Read the corresponding .nev file
                            myNEVfile = [fileList(file_i).name(1:end-3) 'nev'];
                            fprintf('[GetLinkedContData] File: %s... ', myNEVfile')
                            [~, stimulus, ~] = nev2MatSpikesOnly( myNEVfile );
                            fprintf('READ\n');
                            
                            % now find the groups of four packets that
                            % correspond to a chronos timestamp at both the
                            % start and end of the file. I rely on the
                            % timestamp difference between these four
                            % packets being very very small.
                            % Start of file chronos packet
                            for i = 1 : 10 
                                if diff( stimulus(i:i+3,1) ) < 1e-2 
                                    startChronosPackets = stimulus(i:i+3,3);
                                    break
                                end
                            end %for i = 1 : 10 
                            
                            % End of file chronos packet
                            for i = size(stimulus,1)-3 : -1 : size(stimulus,1)-10
                                if diff( stimulus(i:i+3,1) ) < 1e-2
                                    endChronosPackets = stimulus(i:i+3,3);
                                    break
                                end
                            end %for i = size(stimulus,1)-3 : -1 : size(stimulus,1)-10
                             
                            NEVstartCounter = chronosPacketsToCounter( startChronosPackets );
                            NEVendCounter = chronosPacketsToCounter ( endChronosPackets );
                            
                            RstartCounter = min( [obj.sR.startCounter] );
                            RendCounter   = max( [obj.sR.endCounter] );
                            
                            if (RstartCounter > NEVstartCounter) && (RendCounter < NEVendCounter) % Chronos counters match!                              
                               if foundMatchingNSX == true % Not good, should be false 
                                   error('[GetLinkedContDat] Warning, a previous .nsx file already matched the sought timestamps, but so does %s, Check this...', myNEVfile)
                               else
                                   foundMatchingNSX = true;
                               end %if foundMatchingNSX == true
                               
                               
                               % STEP 4: 
                               % Here's the key operation. Go through each trial, and pull out its data
                               % data!
                               for trial_i = 1 : obj.numTrials                           
                                   candNSPendT = obj.sR(trial_i).(myEndFieldName)(end);
                                   if candNSPendT >= MAXALLOWEDNSPTIME
                                       candNSPendT = obj.sR(trial_i).(myEndFieldName)(end-1);
                                       fprintf(2, '[GetLinkedContDat] Trial %i had corrupted NSPendT, using second-to-last timestamp...\n', trial_i)                                    
                                       if candNSPendT >= MAXALLOWEDNSPTIME
                                           error( '[GetLinkedContDat] Trial %i had corrupted NSPendT for last and second-to-last timestamp; I''m giving up!')
                                       end
                                   end
                                   myNSPendT   = candNSPendT/ NSPSAMPLERATE;
                                   % There is occasional corruption of this timestamp; to protect against this,
                                   % I'm going to check if mynspEndT is corrupted, and if so use a previous value
                                   
                                   % -----------------------------------------------------------------------
                                   %    Grabbing data with different kinds of alignment happens here
                                   % -----------------------------------------------------------------------
                                   % I will start pulling data from myNSPstartT-bufferSecs, which should be the start
                                   % of the trial minus the extra data (for filtering, etc). There is also a different
                                   % variable, myNSPzeroT
                                   % which corresponds to which continuous data sample is marked t=0s; this is very useful
                                   % later for aligning the continuous data with, for example, trial start (so same as 
                                   % myNSPstartT) or movement start.
                                   
                                   
                                   % Depending on the sort of alignment I'm looking for, I make myNSPstartT different. Thus,
                                   % the t=0 of the resulting continuous data corresponds to this alignment.
                                   % Recacloll, however there may be sampels with timestamp of t<0 due to the bufferSecs
                                   
                                   myNSPstartT = obj.sR(trial_i).(myStartFieldName)(1);
                                   if myNSPstartT <= MINALLOWEDNSPTIME
                                       myNSPstartT = obj.sR(trial_i).(myStartFieldName)(2);
                                       fprintf(2, '[GetLinkedContDat] Trial %i had corrupted myNSPstartT, using second timestamp...\n', trial_i)
                                       if myNSPstartT <= MINALLOWEDNSPTIME
                                           error( '[GetLinkedContDat] Trial %i had corrupted myNSPstartT for second and first timestamp; I''m giving up!')
                                       end
                                   end % if myNSPstartT <= MINALLOWEDNSPTIME
                                   myNSPstartT = myNSPstartT / NSPSAMPLERATE;
                                   
                                   switch alignto
                                       case 'trial_start' % the start of the trial as recorded in the R struct. This aligns the continual neural
                                           % data with the millisecond-resolution R struct data (cursorPos, bin crossing counts, etc.)
                                           myNSPzeroT = myNSPstartT;
                                           
                                       case 'target_onset' % when the target appears on screen
                                           myNSPzeroT = obj.sR(trial_i).(myStartFieldName)(obj.sR(trial_i).timeTargetOn);
                                           if myNSPzeroT <= MINALLOWEDNSPTIME
                                               myNSPzeroT = obj.sR(trial_i).(myStartFieldName)(obj.sR(trial_i).timeTargetOn+1);
                                               fprintf(2, '[GetLinkedContDat] Trial %i had corrupted myNSPzeroT, using next timestamp...\n', trial_i)
                                               if myNSPzeroT <= MINALLOWEDNSPTIME
                                                    error( '[GetLinkedContDat] Trial %i had corrupted myNSPzeroT for both intended and subsequent timestamp; I''m giving up!')
                                               end
                                           end % if myNSPzeroT <= MINALLOWEDNSPTIME
                                           myNSPzeroT = myNSPzeroT / NSPSAMPLERATE;
                                           
                                           
                                           
                                       case 'movement'  % Find the start of movement. 
                                           % User specifies whether to use hand or cursor position for trial data alignment
                                           switch alignparam.kinematicsType 
                                               case 'hand'
                                                   % First, I should clean up my hand positions in case there are Polaris blinkouts
                                                   [myhandpos, replacedMask] = interpolateOverPolarisBlinkout( obj.sR(trial_i).handPos );
                                                   if nnz( replacedMask ) > 0 && verboseGlobal
                                                       fprintf('[%s:GetLinkedContDat] Note: interpolated over %i blink-out samples in position of trial %i before calculating movement onset time\n',...
                                                           mfilename, nnz( replacedMask ), trial_i)
                                                   end
                                                   vel = RpositionToVelocity( myhandpos );
                                               case 'cursor'
                                                   vel = RpositionToVelocity( obj.sR(trial_i).cursorPos );                                                   
                                           end % switch alignparam.kinematicsType
                                           
                                           [startOfMovSample, forwardCrossIdx] = StartOfMovement( vel, [1 2], alignparam.threshold, false );
                                           if ((startOfMovSample - forwardCrossIdx) > 20) && verboseGlobal
                                              fprintf('[%s:GetLinkedContDat] Warning: When movement-aligning trial %i, startOfMovSample was %i and forwardCrossIdx was %i!\n', ...
                                                  mfilename, trial_i, startOfMovSample, forwardCrossIdx)
                                           end
                                           if strcmp( alignparam.kinematicsType, 'hand' )
                                               if any( replacedMask(:,startOfMovSample) ) && verboseGlobal
                                                   fprintf('[%s:GetLinkedContDat] Warning: When movement-aligning trial %i, startOfMovSample %i was during a Polaris blinkout interpolated position\n', ...
                                                       mfilename, trial_i, startOfMovSample )
                                               end
                                           end
                                           
                                           myNSPzeroT = obj.sR(trial_i).(myStartFieldName)(startOfMovSample);
                                           if myNSPzeroT <= MINALLOWEDNSPTIME
                                               myNSPzeroT = obj.sR(trial_i).(myStartFieldName)(startOfMovSample+1);
                                               fprintf(2, '[GetLinkedContDat] Trial %i had corrupted myNSPzeroT, using next timestamp...\n', trial_i)
                                               if myNSPzeroT <= MINALLOWEDNSPTIME
                                                    error( '[GetLinkedContDat] Trial %i had corrupted myNSPzeroT for both intended and subsequent timestamp; I''m giving up!')
                                               end
                                           end % if myNSPzeroT <= MINALLOWEDNSPTIME
                                           myNSPzeroT = myNSPzeroT / NSPSAMPLERATE;
                                           
                                           
                                           
                                       case 'movement3d' % uses z position to calculate start of movement as well as x and y
                                           % Find the start of movement.
                                           % User specifies whether to use hand or cursor position for trial data alignment
                                           switch alignparam.kinematicsType
                                               case 'hand'
                                                   % First, I should clean up my hand positions in case there are Polaris blinkouts
                                                   [myhandpos, replacedMask] = interpolateOverPolarisBlinkout( obj.sR(trial_i).handPos );
                                                   if nnz( replacedMask ) > 0 && verboseGlobal
                                                       fprintf('[%s:GetLinkedContDat] Note: interpolated over %i blink-out samples in position of trial %i before calculating movement onset time\n',...
                                                           mfilename, nnz( replacedMask ), trial_i)
                                                   end
                                                   vel = RpositionToVelocity( myhandpos );
                                               case 'cursor'
                                                   vel = RpositionToVelocity( obj.sR(trial_i).cursorPos );
                                           end % switch alignparam.kinematicsType
                                           [startOfMovSample, forwardCrossIdx] = StartOfMovement( vel, [1 2 3], alignparam.threshold, false );
                                           if ((startOfMovSample - forwardCrossIdx) > 20) && verboseGlobal
                                               fprintf('[%s:GetLinkedContDat] Warning: When movement-aligning trial %i, startOfMovSample was %i and forwardCrossIdx was %i!\n', ...
                                                   mfilename, trial_i, startOfMovSample, forwardCrossIdx)
                                           end
                                           if strcmp( alignparam.kinematicsType, 'hand' )
                                               if any( replacedMask(:,startOfMovSample) ) && verboseGlobal
                                                   fprintf('[%s:GetLinkedContDat] Warning: When movement-aligning trial %i, startOfMovSample %i was during a Polaris blinkout interpolated position\n', ...
                                                       mfilename, trial_i, startOfMovSample )
                                               end
                                           end
                                           
                                           myNSPzeroT = obj.sR(trial_i).(myStartFieldName)(startOfMovSample);
                                           if myNSPzeroT <= MINALLOWEDNSPTIME
                                               myNSPzeroT = obj.sR(trial_i).(myStartFieldName)(startOfMovSample+1);
                                               fprintf(2, '[GetLinkedContDat] Trial %i had corrupted myNSPzeroT, using next timestamp...\n', trial_i)
                                               if myNSPzeroT <= MINALLOWEDNSPTIME
                                                   error( '[GetLinkedContDat] Trial %i had corrupted myNSPzeroT for both intended and subsequent timestamp; I''m giving up!')
                                               end
                                           end % if myNSPstartT <= MINALLOWEDNSPTIME
                                           myNSPzeroT = myNSPzeroT / NSPSAMPLERATE;
                                   end %switch alignto
                                   
                                   
                                   % Now account for the bufferSecs on either side so I have enough to do 
                                   % filtering later.
                                   bufferSecs = bufferSecs - rem( bufferSecs, NSX.Period ); % makes sure adding/subtracting bufferSecs won't bring me to a
                                        % time point that doesn't line up with a tic in NSXtime                                   
                                   
                                   myNSPstartT = myNSPstartT - bufferSecs;
                                   myNSPendT   = myNSPendT  + bufferSecs;
                                   
                                   % Create or append to the contDatObject with this data, and fill in various support fields
                                   if length( obj.contDat ) < trial_i  % Creating a new contDat object
                                       obj.contDat{trial_i} = contDatObject( 'bufferSecs', bufferSecs, 'channelID', NSX.Channel_ID); % make object with channelID, bufferSec fields         
                                       obj.contDat{trial_i}.arraySource{array_i} = obj.arraySource{array_i}; % add this array to the arraySource
                                       obj.contDat{trial_i}.raw.rate = 1/NSX.Period; % add .raw.rate
                                       obj.contDat{trial_i}.alignTo = alignto;
                                       
                                       
                                       obj.contDat{trial_i}.channelArray = array_i .* ones( length(NSX.Channel_ID), 1 ); % add channelArray
                                       % I'm going to find the closest timestamp in NSXtime to what I'm looking for, since the exact timestamps might not be there.
                                       [val, startInd] = min( abs( NSXtime - myNSPstartT ) );
                                       if val > 1e-3
                                           error('Could not find myNSPstartT in NSXtime to sufficient accuracy')
                                       end
                                       [val, endInd] = min( abs( NSXtime - myNSPendT ) );
                                       if val > 1e-3
                                           error('Could not find myNSPendT in NSXtime to sufficient accuracy')
                                       end                         
                                       obj.contDat{trial_i}.raw.dat = NSXdata(:, startInd : endInd );
                                       
                                       % add the .t field for this trial.
                                       % The below offset is critical, as it does the actual alignment specified in <alignto>. I start with the first data sample being time = 0s, and then
                                       % subtract the difference between myNSPzeroT and myNSPstartT, so now the data sample corresponding to myNSPzeroT has a corresponding .t = 0
                                       toffset = myNSPzeroT - myNSPstartT;
                                       obj.contDat{trial_i}.raw.t = ( (0:size( obj.contDat{trial_i}.raw.dat, 2 )-1 ) / obj.contDat{trial_i}.raw.rate ) - toffset ;
                                       
                                       
                                   else % at least one electrode array worth of data already exists; I'll need to append to it.
                                       obj.contDat{trial_i}.channelID = [obj.contDat{trial_i}.channelID ; NSX.Channel_ID + MAXCHANSPERARRAY*(array_i-1)];
                                       obj.contDat{trial_i}.arraySource{array_i} = obj.arraySource{array_i}; 
                                       obj.contDat{trial_i}.channelArray = [obj.contDat{trial_i}.channelArray ; array_i .* ones( length(NSX.Channel_ID), 1 )];
                                       
                                                                           
                                       % I'm going to find the closest timestamp in NSXtime to what I'm looking for, since the exact timestamps might not be there.                                                                         
                                       [val, startInd] = min( abs( NSXtime - myNSPstartT ) );
                                       if val > 1e-3
                                           error('Could not find myNSPstartT in NSXtime to sufficient accuracy')
                                       end
                                       [val, endInd] = min( abs( NSXtime - myNSPendT ) );
                                       if val > 1e-3
                                           error('Could not find myNSPendT in NSXtime to sufficient accuracy')
                                       end                
                                       
                                       % Now combine the data. Note that sometimes each array's data is a few samples off in length (due to tiny clock drifts
                                       % I'm guessing. If the new data is too long, shorten it, and if it's too short, shorten the existing data. All changes happen in the
                                       % end buffer zone and shouldn't affect analyses
                                       myDat = NSXdata(:, startInd : endInd  );
                                       if size( myDat, 2 ) > size( obj.contDat{trial_i}.raw.dat, 2 )
                                          myDat = myDat(:, 1 :  size( obj.contDat{trial_i}.raw.dat, 2 ) );                                         
                                       end
                                       if size( myDat, 2 ) < size( obj.contDat{trial_i}.raw.dat, 2 )
                                           obj.contDat{trial_i}.raw.dat = obj.contDat{trial_i}.raw.dat(:, 1 : size( myDat,2 ) );
                                           % also shorten obj.contDat{trial_i}.raw.t to match
                                           obj.contDat{trial_i}.raw.t = obj.contDat{trial_i}.raw.t(1:size( myDat, 2 ) );
                                       end
                                           
                                       obj.contDat{trial_i}.raw.dat = [obj.contDat{trial_i}.raw.dat ; myDat];

                                   end %if... else... length( obj.contDat ) < trial_i 
                               end %for trial_i = 1 : obj.numTrials
      
                               fprintf('[GetLinkedContData] Pulled in %i trials of data from %i channels\n', obj.numTrials, size(NSXdata,1) )
  
                            end %if (RstartCounter > NEVstartCounter) && (RendCounter < NEVendCounter)
                        end %if (min( NSXtime ) <= minCbTime) && (max( NSXtime ) >= maxCbTime )
                    end %or file_i = 1 : length( fileList )
                end %if ~isempty( arraySource{array_i}.dir )
            end %for array_i = 1 : numArrays
        end %function obj = GetLinkedContDat( obj )
        
        function obj = RemoveElec( obj, elecNums )
           % removes these (presumably bad) electrodes from the raw data of every
           % trial in this Robject. NOTE: This method should be called before 
           % any derivative features (such as LFP bands) are generated, or those
           % will still have the features built from the bad channel
           % Note that the numbers in <elecNums> should be the actual number of the electrode,
           % as reported in .channelID, and not just an index.
           
           % TODO: When I start using spike data, this method should be updated
           % to remove those channels as well.
           % SDS 8/23/2011: I haven't been doing this, but I it's still removing
           % channels when I prepare the training data T struct. In fact, if I fix 
           % this now it would break that part of TrajectoryReconstruction, so that'll
           % be a to-do item.
           if verboseGlobal
               fprintf('[%s:RemoveElec] Removing elec %s\n', mfilename, mat2str( elecNums ) );
           end
           
           for trial_i = 1 : obj.numTrials
               % find which index of the data corresponds to these channels
               [~, inds, ~] = intersect( obj.contDat{trial_i}.channelID, elecNums );
               obj.contDat{trial_i}.raw.dat(inds,:) = [];
               obj.contDat{trial_i}.channelID(inds) = [];
               obj.contDat{trial_i}.channelArray(inds) = [];
           end %for trial_i = 1 : obj.numTrials
        end
        
        %*********************************************************
        %             Continuous Neural Data Manipulation
        %*********************************************************
        function obj = ComputeBandPower( obj, bandName, fpass, movingwin, sourceSignal )
            % Adds a field <bandName> to the Robject which is the bandpass power
            % between frequencies specified in <fpass>, using the moving window
            % specified in <movingwin>. Uses Chronux package..
            % 
            %   sourceSignal    from which signal to generate the band power. Defaults to 'raw'.
            
            % Input processing and defaults
            if nargin < 2 || isempty( bandName )
                error('[%s:ComputeBandPower] no band name entered.', mfilename)
            end
            
            
            
            % Default parameters for various band names
            switch bandName
                
                % These are in my new formatting to allow automatic parsing
                % that this is a band power feature
                case 'lfpPow_45to300'
                    fpass = [35 300];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_63to200'
                    fpass = [63 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_63to100'
                    fpass = [63 100];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_45to100'
                    fpass = [45 100];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_45to200'
                    fpass = [45 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                    
                case 'lfpPow_10to35_50ms'
                    fpass = [10 35];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                  
                case 'lfpPow_10to100_50ms'
                    fpass = [10 100];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                    
                case 'lfpPow_50to200_50ms'
                    fpass = [50 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_55to200_50ms'
                    fpass = [55 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_60to200_50ms'
                    fpass = [60 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms    
                 case 'lfpPow_65to200_50ms'
                    fpass = [65 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms        
                case 'lfpPow_70to200_50ms'
                    fpass = [70 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms          
                case 'lfpPow_75to200_50ms'
                    fpass = [75 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms                
                 case 'lfpPow_80to200_50ms'
                    fpass = [80 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms      
                 case 'lfpPow_85to200_50ms'
                    fpass = [85 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms          
                case 'lfpPow_90to200_50ms'
                    fpass = [90 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms          
                 case 'lfpPow_95to200_50ms'
                    fpass = [95 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms             
                case 'lfpPow_100to200_50ms'
                    fpass = [100 200];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms      
                    
                case 'lfpPow_80to205_50ms'
                    fpass = [80 205];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to210_50ms'
                    fpass = [80 210];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to215_50ms'
                    fpass = [80 215];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to220_50ms'
                    fpass = [80 220];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to225_50ms'
                    fpass = [80 225];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to230_50ms'
                    fpass = [80 230];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to235_50ms'
                    fpass = [80 235];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to240_50ms'
                    fpass = [80 240];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to245_50ms'
                    fpass = [80 245];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to250_50ms'
                    fpass = [80 250];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to255_50ms'
                    fpass = [80 255];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to260_50ms'
                    fpass = [80 260];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to300_50ms'
                    fpass = [80 300];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to400_50ms'
                    fpass = [80 400];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_80to500_50ms'
                    fpass = [80 500];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_45to500_50ms'    
                    fpass = [45 500];
                    movingwin = [0.050 0.001]; % 50ms moving window slid every ms
                case 'lfpPow_45to200_50ms'
                    fpass = [45 200];
                    movingwin = [0.050 0.005]; % 50ms moving window slid every 5ms
                case 'lfpPow_40to200_50ms'
                    fpass = [40 200];
                    movingwin = [0.050 0.005]; % 50ms moving window slid every 5ms
                case 'lfpPow_35to200_50ms'
                    fpass = [35 200];
                    movingwin = [0.050 0.005]; % 50ms moving window slid every 5ms    
                case 'lfpPow_30to200_50ms'
                    fpass = [30 200];
                    movingwin = [0.050 0.005]; % 50ms moving window slid every 5ms       
                case 'lfpPow_25to200_50ms'
                    fpass = [25 200];
                    movingwin = [0.050 0.005]; % 50ms moving window slid every 5ms 
                case 'lfpPow_45to100_50ms'
                    fpass = [45 100];
                    movingwin = [0.050 0.005]; % 50ms moving window slid every 5ms
                    
                    
                    
                    
                case 'lfpPow_45to200_100ms'
                    fpass = [45 200];
                    movingwin = [0.100 0.005]; % 100ms moving window slid every 5ms
                    
                case 'lfpPow_4to13_50ms'
                    fpass = [4 13];
                    movingwin = [0.050 0.005]; % 50ms moving window slid every 5ms
                    
                
                % NOTE: These are defunct. From now one use the lfpPow_LOWtoHIGH
                % convention
                case 'beta'
                    fpass = [15 30];
                    movingwin = [0.500 0.005]; % 500 ms moving window slid every 5ms
                case 'gamma_low'
                    fpass = [30 45];
                    movingwin = [0.500 0.005]; % 500 ms moving window slid every 5ms
                case 'gamma_high'
                    fpass = [45 100];
                    movingwin = [0.100 0.005]; % 100ms moving window slid every 5ms
                case 'gamma_high_50ms'
                    fpass = [45 100];
                    movingwin = [0.050 0.005]; % 50ms moving window slid every 5ms
                case 'gamma_62up_50ms'
                    fpass = [62 100];
                    movingwin = [0.050 0.005]; % 50ms moving window slid every 5ms
                case 'gamma_high_300ms'
                    fpass = [45 100];
                    movingwin = [0.300 0.005]; % 300ms moving window slid every 5ms
                case 'gamma_high_500ms'
                    fpass = [45 100];
                    movingwin = [0.500 0.005]; % 300ms moving window slid every 5ms
                case 'above35'
                    fpass = [35 100];
                    movingwin = [0.100 0.005]; % 100ms moving window slid every 5ms
                    
                    
                otherwise
                    if nargin <= 3 || isempty( fpass)
                        error('[%s:ComputeBandPower] <bandName> %s does not have default fpass; you must provide a bandName', mfilename, bandName)
                    end
                    if nargin < 4
                        movingwin = [0.500 0.005]; % 500 ms moving window slid every 5ms
                    end
            end
            
            if nargin < 5
                sourceSignal = 'raw';
            end
             
            
            % Loop through each contDatObject of this Robject and add a property
            % called <name> which will have the filtered continuous signal
            numTrials = obj.numTrials; % for parfor
            localContDat = obj.contDat; % for parfor
%             for trial_i = 1 : numTrials;% DEV
            parfor trial_i = 1 : numTrials;
                if verboseGlobal
                   fprintf('[%s:ComputeBandPower] Generating %s band from %s with fpass %s for trial %i/%i\n', ...
                       mfilename, bandName, sourceSignal, mat2str( fpass ), trial_i, numTrials )
                end
                localContDat{trial_i} = AddFilteredBand( localContDat{trial_i}, bandName, fpass, movingwin, sourceSignal );

            end %parfor trial_i = 1 : obj.numTrials
            obj.contDat = localContDat; % otherwise changes stay local
            
            
        end %function obj = ComputeBandPower( obj, bandName, fpass, movingwin, sourceSignal )
        
        function obj = FilterAllTrialsContData( obj, sourceSignal, b, a, filterfunc, newSignalName )
            %*********************************************************
            %           Filter Continuous Data
            %*********************************************************
            % Creates a new signal that is stored in a new property of this Robject, which is a 
            % filtered version of a different, already-existing signal (e.g. high-pass from raw signal).
            % USAGE:
            %    Robject = Robject.FilterAllTrialsContData( sourceSignal, b, a, filterfunc, newSignalName )
            % INPUTS:
            %    sourceSignal     name of the source signal. Its .dat field should be chans x samples
            %    b                filter coefficient numerators (the standard MATLAB filtering b)
            %    a                filter coefficient denominators (the standard MATLAB filtering a)
            %    filterfunc       function handle, e.g. 'filtfilt' or 'filter'
            %    newSignalName    a new property with this name will be created to store the new signal
            % OUTPUTS:
            %    obj       updated Robject. Since these are pass-by-value objects, you must use this output or the modificaitons
            %              will be lost.
            
            
            if verboseGlobal
                fprintf('[%s:FilterAllTrialsContData] Generating %s signal by filtering %s signal.\n', ...
                    mfilename, newSignalName, sourceSignal)
            end
            
            % Loop through each contDatObject of this Robject and add a property
            % called <name> which will have the filtered continuous signal
            numTrials = obj.numTrials; % for parfor
            localContDat = obj.contDat;
            parfor trial_i = 1 : numTrials
                localContDat{trial_i} = FilterContData( localContDat{trial_i}, sourceSignal, b, a, filterfunc, newSignalName );  
            end %parfor trial_i = 1 : numTrials   
            obj.contDat = localContDat; %otherwise changes don't leave scope of this method
        end %function obj = FilterContData( obj, bandName, b, a, filterfunc )
                
        function obj = LinTransformAllTrialContDat( obj, sourceSignal, transMat, newSignalName)
            %*********************************************************
            %              Linear Transformations of Data
            %*********************************************************
            % Creates a new signal that is stored in a new property of this contDatObject, which is a linear transformation
            % of a different, already-existing signal (e.g. PCA from raw signal).
            %
            % USAGE:
            %    Robject = Robject.LinTransformAllTrialContDat( sourceSignal, transMat, newSignalName )
            % INPUTS:
            %    sourceSignal     name of the source signal. Its .dat field should be chans x samples
            %    transMat         this is the matrix that transforms the sourceSignal. It should be chans x k
            %                     where k is the dimensionality of the new signal.
            %    newSignalName    a new property with this name will be created to store the new signal
            % OUTPUTS:
            %    obj       updated Robject. Since these are pass-by-value objects, you must use this output or the modificaitons
            %              will be lost.
            
            if verboseGlobal
                fprintf('[%s:LinTransformAllTrialContDat] Generating %s signal with dimensionality %i from %s signal.\n', ...
                    mfilename, newSignalName, size( transMat, 2), sourceSignal )
            end
            
            % Loop through each contDatObject of this Robject and add a property
            % called <name> which will have the filtered continuous signal
            for trial_i = 1 : obj.numTrials
                AddLinTransformedSignal( obj.contDat{trial_i}, sourceSignal, transMat, newSignalName);      
            end %for trial_i = 1 : obj.numTrials
        end
        
        function allDat = ConcatenatedTrialData( obj, feature, startT, endT, chanInds )
            % ConcatenatedTrialData method of Robject. Returns a concatenated matrix of data coming from all of the trials in
            % the Robject.
            % USAGE: 
            % INPUTS:
            %   feature  string specifying which data type (e.g. 'raw' ) to grab
            %   startT   beginning timestamp of data to grab from. If empty ([]) will start from earliest eavailable data.
            %   endT     end timestamp of data to grab. If empty ([]) will grab up to the last available data.
            %  (chanInds) (optional) vector of the indices of in contDat.(feature).dat that you want. By default will grab all the channels. 
            % OUTPUTS:
            %   allDat   large matrix of dimensions chans x samples containing all of the requested data.
            
            % ARGUMENT PROCESSING
            
            if nargin < 5 || isempty( chanInds )
                % Use all channels. I assume the first trial has same data dimension as all the other trials; if not
                % there are bigger problems.
                chanInds = 1 : size( obj.contDat{1}.(feature).dat, 1 );
            end
            
            % Get data type of the data; I'll return the same type
            samp = obj.contDat{1}.(feature).dat(1,1);
            sampwhos = whos('samp');
            
            % First go through each trial and record the start and end index in the data for that trial. 
            % This will be used to preallocate allDat before filling it in.
            startInd = zeros( obj.numTrials, 1 );
            endInd   = zeros( obj.numTrials, 1 );
            for trial_i = 1 : obj.numTrials
                % compute start index
                if isempty( startT )
                    startInd(trial_i) = 1;
                else
                    [val, ind] = min( abs( obj.contDat{trial_i}.(feature).t - startT  ) );
                    if abs( obj.contDat{trial_i}.(feature).t(ind) - startT ) > 0.001 % if more than 1 ms difference between sought and delivered time, warn
                        fprintf( '[%s:ConcatenatedTrialData] Warning. For trial %i, seeking startT = %f, but closest timestamp found was %f\n',...
                            mfilename, trial_i, startT, val );
                    end
                    startInd(trial_i) = ind;
                end
                
                % Compute end index
                if isempty( endT )
                    endInd(trial_i) = size( obj.contDat{trial_i}.(feature).t, 2);
                else
                    [val, ind] = min( abs( obj.contDat{trial_i}.(feature).t - endT  ) );
                    if abs( val - endT ) > 0.001 % if more than 1 ms difference between sought and delivered time, warn
                        fprintf( '[%s:ConcatenatedTrialData] Warning. For trial %i, seeking startT = %f, but closest timestamp found was %f\n',...
                            mfilename, trial_i, endT, val );
                    end
                    endInd(trial_i) = ind;
                end
            end %for trial_i = 1 : obj.numTrials
          
            % Now go back through all of the trials and pull out the data I want
            
            numSamples = endInd - startInd + 1;
            allDatStartInd  = [1 ; cumsum( numSamples ) + 1];
            allDatEndInd = cumsum( numSamples );
            command = ['allDat = ' sampwhos.class '( zeros( length( chanInds ), sum( numSamples ) ) );'];
            eval( command );
            for trial_i = 1 : obj.numTrials;
                allDat(:,allDatStartInd(trial_i):allDatEndInd(trial_i)) = obj.contDat{trial_i}.(feature).dat( chanInds, startInd(trial_i):endInd(trial_i)); 
            end 
            
        end % function allDat = ConcatenatedTrialData( obj, feature, startT, endT, chanInds )
        
end %methods

end %classdef

