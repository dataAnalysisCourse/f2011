classdef Director < handle
    % The Director is a special object which is used by some states to
    % determine which of their nextStateChoices they should call next; this
    % means that the states such as Target_Acquired_State don't need to do
    % any planning/keep a list of targets; rather they all ask this one
    % central object which state to go to next. Although for now Director
    % pregenerates the list of targets and just feeds requesters the next one,
    % I envision for other games the Director can be modified to dynamically 
    % generate the next target (e.g. based on which participant is having
    % trouble with), or allow the operator to make changes on the fly.
    
    % It sends back as a nextState one of the <nextStateIndices>, and for
    % the regular center-out game the order is in 'sequences' which are
    % permuted orders of all of the <nextStateIndices>. Thus, the if there
    % are 4 possible targets, all 4 must be used as targets before any can
    % be repeated. <numSequences> determines how many of these sequences to
    % send out. 
    
    % Note: I've chosen to not give this Director actual states which it
    % can feed back as the nextStateChoice when requested. Rather, it
    % abstractly spits out nextStateChoice *indices*, so e.g
    % target5_acquired_st will request its next state from Director, and
    % Director will say back '3'. This requires all the served game states to
    % number their nextStateChoices the same. The advantage of this method
    % is that it's a.) faster (sending back integers rather than state
    % handle strings to be used in NextState methods) and easier to work
    % with when there are many possible next states; you just feed the
    % Director constructor the possible next State choice index numbers
    % (e.g. [1 3 4 5]) and it will do the pseudorandomization with these
    % and feed them back. Note that if each served state needs different
    % rules/has varying numbers of possible other states, then this will
    % have to be changed considerably to accomodate this. 
    
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        maxNumSequences
        nextStateIndices     % vector of the nextState indices that form a complete sequence.
        currentIndexInSequence = 1 % what element in the currentSequence I will serve next
        currentSequence      % the sequence of states that's currently being served
                             % up, one at a time with each request from
                             % GetNextStateIndex
        sequencesDone = -1;  % how many sequences have already been run through. 
                             % When it hits numSequences, no more is sent.
                             % Starts at -1 because goes up to 1 at first
                             % call, due to the way i've coded it up
                             % (oblivates a special first time case)
                             % back. DEV: Will send out the "finish" state,
                             % whatever that eventually is, in this case.
        terminateStateIndex  % will be passed out when maxNumSequences reached; presumably
                             % this leads to the end of game state.
    end
 
    
    
    % *****************************************************
    %                       EVENTS
    % *****************************************************
    
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        % CONSTRUCTOR
        function obj = Director( varargin )
            %takes property-value pairs. 
            for i = 1: 2 : length(varargin)
                obj.(varargin{i}) = varargin{i+1};
            end        
            obj.currentIndexInSequence = length( obj.nextStateIndices )+1; % so that at first pass it starts new sequence 
        end % constructor    
        
        function nextStateIndex = GetNextStateIndex(obj, callingObj )
            % Returns the next single choice of index from nextStateIndex
            % according to the random perumation done. When a whole
            % permuted sequence is exhausted, a new one is generated.
            
            % I get callingObj because in future versions I might use this
            % to determine what to feed out (i.e. I have different rules
            % for different calling states).
            if obj.currentIndexInSequence > length( obj.nextStateIndices )
               % time to make a new sequence 
               obj.sequencesDone = obj.sequencesDone + 1;
               if obj.sequencesDone < obj.maxNumSequences 
                   obj.currentSequence = obj.nextStateIndices( randperm( length(obj.nextStateIndices) ) );
                   obj.currentIndexInSequence = 1;
               else % max number of random target sequences reached; this part of the game is over
                   nextStateIndex = obj.terminateStateIndex;
                   return
               end %if obj.sequencesDone < obj.maxNumSequences                 
            end %obj.numLeftInSequence == 0
            
            nextStateIndex = obj.currentSequence(obj.currentIndexInSequence);
            obj.currentIndexInSequence = obj.currentIndexInSequence + 1;
            
        end %obj = GetNextStateIndex(obj, callingObj )
        
        
        
    end % methods (Access = public)


    
end %classdef

