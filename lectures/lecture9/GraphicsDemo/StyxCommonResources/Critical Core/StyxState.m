% This is the prototype class for a Styx Game Environment state.
classdef StyxState < handle
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)
        nextStateChoices          % has the descriptiveNames and handles of other states this one can go to
        descriptiveName = 'NoNameSet' % a string which will be useful to identify a StyxState during debugging or 
                                  % when generating automatic plots of nextStateChoices webs.
        logger_h                  % StyxLogger handle; a StyxState uses this object to log everything that it
                                  % or the objects it creates does.
    end %properties (Access = public)
    properties (Access = protected)
        
        
    end %properties (Access = protected)
    properties (GetAccess = public, SetAccess = protected)
        trueState = false;
    end %properties (GetAccess = public, SetAccess = protected)
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)
        
        % CONSTRUCTOR   
        function obj = StyxState( varargin )
            % The base constructor CAN take no arguments, and all subclasses
            % should call it with any varargins they might have.
            % StyxStateMapper needs to have each state
            % capable of being called with no argument for it to be able to
            % make a state transition diagram.
            
            %create the initial nextStateChoices; while the subclasses will
            %likely overwrite this, this helps establish the proper syntax
            obj.nextStateChoices{1} = struct('name', cell(1), 'handle', cell(1));
            
            
            % Note: I don't do property-value pair constructing here
            % (rather, I leave it to the InitializeState method of the
            % subclass) because not all properties might be present in
            % StyxState (e.g. subclass-specific properties). Thus, each
            % substate should have a property-values pair constructor.
            
            if ~isempty(varargin)
                obj = obj.InitializeState( varargin{1} ); % since the varargins got packed into 1 by the subclass consturctor
            else
                obj = obj.InitializeState( ); 
                % I do this become otherwise a 0x0 varargin (when no 
                % optional arguments used) becomes a 1x1 cell containing []
                % in the InitializeState. So I either check for emptiness
                % here or there, and it yields more consistent and easy use
                % of property-value pairs in state InitializeState methods
                % to just do it here.
            end
        end %function obj = StyxState( )
        
        function obj = FalseToTrue( obj )
            % Transitions the state from being false to true. The actual
            % implementation is done in a subclass FalseToTrueImplement
            % method, but this wrapper checks the assertion the the state
            % was previously false. It also changes the actual
            % obj.trueState, and logs the state transition.
            if obj.trueState ~= false
                % Forces user to be sure that a state is false before
                % calling FalseToTrue. By throwing an error if this is
                % wrong, state logic bugs can be caught.
                error('FalseToTrue: Assumption that state is already false is invalid. Check your state logic')
            else
                obj.trueState = true;
                % LOGGING
                Log( obj.logger_h, obj, 'STATE', 'trueState', obj.trueState );
                FalseToTrueImplement( obj );
            end            
        end % function obj = FalseToTrue( obj )
        
        function obj = TrueToFalse( obj )
            % Transitions the state from being false to true. The actual
            % implementation is done in a subclass TrueToFalseImplement
            % method, but this wrapper checks the assertion the the state
            % was previously true. It also changes the actual
            % obj.trueState, and logs the state transition.
            if obj.trueState ~= true
                % Forces user to be sure that a state is false before
                % calling FalseToTrue. By throwing an error if this is
                % wrong, state logic bugs can be caught.
                error('TrueToFalse: Assumption that state is already true is invalid. Check your state logic')
            else
                obj.trueState = false;
                % LOGGING
                Log( obj.logger_h, obj, 'STATE', 'trueState', obj.trueState );
                TrueToFalseImplement( obj );
            end
        end % function obj = FalseToTrue( obj )
            
        function obj = SetNextStateChoice( obj, index, next_st)
            % a convenience function that sets the object's
            % obj.nextStateChoices{index} to be the state(s) specified by the
            % next_st 
            if length( index ) ~= length( next_st )
                error('length of <index> and <next_st> argument must be the same')
            end
                
            % Support array or single-pair inputs
            if iscell(index)                 
                for arg_i = 1 : length(index)
                    if ~isobject( next_st{arg_i} )
                        error('the next_st specified is not a valid object.')
                    else
                        obj.nextStateChoices{index{arg_i}}.handle = next_st{arg_i};
                        obj.nextStateChoices{index{arg_i}}.name = next_st{arg_i}.descriptiveName;
                    end
                end %for i = 1 : length(index)
            else %if iscell(index)
                if ~isobject( next_st )
                    error('the next_st specified is not a valid object.')
                else
                    obj.nextStateChoices{index}.handle = next_st;
                    obj.nextStateChoices{index}.name = next_st.descriptiveName;
                end
            end %if iscell(index)
            
        end
        
        
        function obj = NextState( obj, nextSt )
            % this method is given one or more indices (in a vector) into the object's
            % nextStateChoices field (which have a .name and .handle of another
            % state) and will (in this order) call the calling state's
            % TrueToFalse method and then call the FalseToTrue methods of
            % all of the called states (in the order they appear.) 
            %
            % Note that the next state to move to is specified by an
            % positive integer (e.g. 2) which is used to select
            % obj.NextStateChoices{ i }. You don't need to call
            % obj.NextStateChoices{i} directly.
            % 
            if isempty( nextSt )
                error('NextState was not given at least one nextStateChoices entry.')
            end
            
            TrueToFalse( obj );
            
            % Call the next state
            % case 1: input is text string, eg. {'state1_st', 'state2_st'}
            % To deal with this I loop through and convert these strings to
            % the appropriate numerical index of the handles in
            % obj.nextStateChoices.
            if ischar( nextSt )
                nextSt = {nextSt}; % makes next loop work for single-input
            end
            if iscellstr( nextSt )
                nextStNumeric = zeros( length( nextSt ),1 );
                for i = 1 : length( obj.nextStateChoices )
                    nextStNumeric( strcmp( obj.nextStateChoices{i}.name, nextSt ) ) = i;
                    % if you get error
%                       "??? The left hand side is initialized and has an empty  range of indices
%                        However, the right hand side returned one or more results"                    
%                     It's because you you entered a string of a state description that couldn't
%                     be found in this state nextStateChoices. I didn't
%                     make a catch for this since it'd slow things down.
                end %for i = 1 : length( nextSt )
                nextSt = nextStNumeric;
                
            end %if iscellstr( nextSt )
            
           % Case 2: input is numeric nextStateChoices indices, e.g
           % {1, 2, 3}. No conversion necessary, so operate straight
           % on the numbers. Note that this code is run regardless since
           % the above conditionals just remake the input to numeric format
           for i = 1 : length( nextSt )
               % fprintf('NextState called: ---> %s\n', obj.nextStateChoices{nextSt(i)}.name) % DEV
               FalseToTrue( obj.nextStateChoices{nextSt(i)}.handle );
           end
        end %function obj = NextState( obj, nextSt )
            
        
        
    end % methods (Access = public)
    
    
    
    
    % ---------------------------------------------------
    %                   ABSTRACT METHODS
    % ---------------------------------------------------
    % I use abstract methods to enforce certain methods that all Styx
    % states must have implemented.
    methods (Abstract)
        % InitializeState is a pseudo constructor, with the advantage
        % of it being able to be called from without to "reset" this
        % state. Note that since each subclass will have its own
        % InitializeSta
        InitializeState( obj, varargin )
        
        % Describes what happens when the state toggles from False to True
        FalseToTrueImplement( obj )
        
        % Describes what happens when the state toggles from True to False
        TrueToFalseImplement( obj )
        
    end % methods (Abstract)

    
end %classdef