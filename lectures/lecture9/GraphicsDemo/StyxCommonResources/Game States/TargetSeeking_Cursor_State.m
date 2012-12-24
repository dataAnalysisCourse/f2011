classdef TargetSeeking_Cursor_State < StyxState
    % When this state is made true, the cursor is drawn at its starting
    % location. Its behavior is then controlled by a timer. It listens to
    % the IAmActive and IAmInactive events of all of the Targets to which
    % it has been linked and keeps track a FIFO queue of active targets
    % towards which it will move. Its movement is controlled by a velocity
    % function which moves towards the target at a speed which is a 
    % function of its distance to the target; it records its start
    % location when it first "locks on" so this can be used to yield a
    % velocity trajectory. How often movement happens is controlled a .rate
    % property
    % 
    % This state also sends the cursor position out via the gameUDP
    % StyxUDPCommunicator object whose handle it was given.
    %
    % Initialization:
    %         * needs to be given the handle of the cursor in its cursor_h
    %         property.
    %
    % *****************************************************
    %                       PROPERTIES
    % *****************************************************
    properties (Access = public)       
        targetQueue = cell(10,1) % whenever a Target_Active_State becomes true, the handle
                              % of its linked Target object is added to
                              % this queue; whenever a Target_Active_State
                              % becomes false, its Target object handle is
                              % removed. This property is used by the class
                              % to keep track of all the targets, in order,
                              % that it needs to get to.
                              % I preallocate 100 for speed but if it grows
                              % beyond this the extra resizing should be
                              % negligble, besides how often will we be 100
                              % targets behind?        
        
        timeToTarget = 3;     % How many seconds it should take to get to 
                              % the target; the path is computed whenever a
                              % new target appears. Note that the current 
                              % method doesn't suppport moving targets (but
                              % then again those wouldn't be chased with a
                              % cosine function anyway)        
	    packetID = 11;        % Identifies the sent UDP position packets to the receiver.
    end %properties (Access = public)
	properties (GetAccess = public, SetAccess = private)
		rate = 15;       % how many times per second to move the cursor 
                              % towards its target
                              % 62.5 is closest within 1ms to 60hz
                              % 31.25 yields 32ms timer time
                              % recommend 50

							  % (performance is becoming an issue..)
        startLocation;        % Records the location of the start for the
                              % current trajectory; can be used as part of
                              % calculation for instantenous speed (e.g. to
                              % make a cosine velocity function)
		speedProfile          % stores its velocity profile (each element of vector)
                              % is speed for a given step. Generated
                              % whenever there is a new target.
        currentStep           % which step it's on of the speedProfile          
                              
        totalTargetsSought = 0; % running count of how many total targets i've gone towards
        oldTotalTargetsSought = 0; % same as totalTargets but updated in the timer callback.
        % this is used to check if the target has
        % changed (I do it with this extra variable since
        % comparing actual objects takes longer, and
        % since I don't want to keep a "totalQueue"
        % which could grow large in a long task with
        % frequent target changes.
		
		
	end %properties (GetAccess = public, SetAccess = private)
    properties (Access = private)
        gameUDP               % StyxUDPcommunicator object handle that this
                              % state uses to send velocity out.
        cursor_h
        timer_h % a timer object fires at the frequency that the cursor moves
                % and moves cursor towards currently sought target.
        
        inQueue = 0; % used to index to end of a preallocated cell array of targets
                     % that can be queued up to be sought. 
		UDPsendEveryNsteps = 1     % For computational efficiency, the updated cursor
		                           % position can be UDP sent out every N
		                           % steps. Make sure this is still
		                           % happening more often than the receiver
		                           % needs to use this information!
		                     
		UDPsendCounter = 0         % counter for above			 
                   
         % Note: I don't track the handles of the listeners because they
         % need to be on even when the state is false, so targets selected
         % before target tracking are still added to the target queue. 
    end %properties (Access = private)
    
    % *****************************************************
    %                       METHODS
    % *****************************************************
    methods (Access = public)        
        function obj = TargetSeeking_Cursor_State( varargin )
            % Note that StyxState immediately calls InitializeState method
            % after the constructor.
            obj = obj@StyxState(varargin);
        end %function obj =  Pause_State ( )
        
        function obj = InitializeState( obj, varargin )
            % InitializeState is a pseudo constructor, with the advantage
            % of it being able to be called from without to "reset" this
            % state.
            propAndValues = varargin{1}; % unpack property-value pairs
            for i = 1: 2 : length(propAndValues)
                obj.(propAndValues{i}) = propAndValues{i+1};
            end 
            obj.timer_h = timer(...
                'TimerFcn', { @obj.TS_C_S_TimerFcn },  ...
                'BusyMode', 'drop', 'TasksToExecute', Inf, ...
                'ExecutionMode', 'fixedRate', 'Period', 1/obj.rate , ...
                'StartDelay', 1/obj.rate, ...
                'Name', 'targetSeekingCursorTimer');

		end %function obj = InitializeState()
		
		function obj = FalseToTrueImplement( obj )
			% start the timer which generates the motion
			start( obj.timer_h );
		end
		
		function obj = TrueToFalseImplement( obj )
			stop( obj.timer_h );
		end
		
		function obj = LinkToTargetActiveState( obj, TargetActiveStateObj, eventName )
			% this method will create a listener for this state to the
			% Target_Active_State whose handle is TargetActiveStateObj for the
			% event of the name specified by string eventName. Note that the name of the
			% callback is contained inside and links to a private method
			addlistener( TargetActiveStateObj, ...
				eventName, @obj.TargetStateActiveOrInactiveEvtCallback );
		end %function obj = LinkToTargetActiveState( obj, TargetActiveStateObj, eventName )
		
		% DESTRUCTOR
		function delete(obj)
			stop(  obj.timer_h )
			delete( obj.timer_h )
		end %function delete(obj)
		
	end %methods (Access = public)
	
	methods (Access = private)
		function obj = TargetStateActiveOrInactiveEvtCallback( obj, eventSrc, eventData )
			% If the event-generating Target_Active_State's target is
			% active:
			% check the assetion that it's not already in the queue
			% (this would indicate state logic issue since it should've
			% been removed before when the state was false.)
			% If it's not in the queue, add it to the end.
			% If the event-generating Target_Active_State's target is
			% inactive: remove it from the queue. If its not on there, also
			% generate an error since this breaks my assertion for this
			% game that it should've be added to this queue before being
			% removed.
			%
			% Also stops the timer if there are no targets in the queue and
			% restarts it when there is once again a target in the queue.
			%             if eventData.active == true
			if eventSrc.trueState % the target just became active target since its Target_Active_State is true
% 				% assertion check DEV
% 				for i = 1 : obj.inQueue
% 					if obj.targetQueue{i} == eventSrc.target_h
% 						error('Why am I adding a Target to the targetQueue when it is already there? This failed assertion suggests a bug')
% 					end
% 				end %for i = 1 : length(obj.targetQueue) % END DEV
				
				if obj.inQueue == 0
					obj.totalTargetsSought = obj.totalTargetsSought + 1; %
				end
				obj.inQueue = obj.inQueue + 1;
				obj.targetQueue{obj.inQueue} = eventSrc.target_h;
				% If the state is true and the timer is stopped (which
				% happens when no active targets to save CPU cycles)
				% there's now a target in the queue so
				% start the timer.
				if obj.trueState == true && strcmp( obj.timer_h.Running, 'off')
					start( obj.timer_h )
				end
				
			elseif eventSrc.trueState == false
				for i = 1 : obj.inQueue
					if obj.targetQueue{i} == eventSrc.target_h
						% if it's in slot 1 of the queue, that means this
						% was the current target. Thus, there is now a new
						% target sought(which might be null), and so the
						% obj.totalTargetsSought should be incremented. If
						% it's not in slot 1, then a target was made
						% inactive before we ever got to go for it, and we
						% remove it from the list like nothing's happened..
						if i == 1 && obj.inQueue > 1 % new target will be at queue top
							obj.totalTargetsSought = obj.totalTargetsSought + 1;
						end
						% excise this target from the list
						obj.targetQueue(i:end-1) = obj.targetQueue(i+1:end);
						obj.targetQueue{end} = [];
						obj.inQueue = obj.inQueue - 1;
						
						% if there are no targets in queue we can stop the
						% timer until another target enters queue
						if obj.inQueue <= 0
							stop( obj.timer_h )
						end
						
						
						return % once we find which target to delete, we're done
					end
					% if it reaches here, it didn't find the target_h in
					% the queue, which violates my assetion
					error('Why couldn''t I find a Target that became inactive in the targetQueue when it should have been there? This failed assertion suggests a bug')
				end %for i = 1 : length(obj.targetQueue)
			end
			
			
		end % function obj = TargetStateActiveOrInactiveEvtCallback( obj, eventSrc, eventData )
		
		function TS_C_S_TimerFcn( obj, timerObj, event )
			% This is the timer function for this state's internal timer
			% object. When the state is true, the timer is running. Much of
			% the work of the function actually happens here: the Cursor is
			% moved towards the current target.
			
			currTarget = obj.targetQueue{1}; % whichever is at top of queue is sought
			if isempty(currTarget)
				% no active target; nothing to do, so return
				%                return % Removed SDS 4/13/2010 because with send UDP not
				%                every cycle possible I want to make sure that we send end
				%                position.
				inst_velocity = [ 0 0 0 ]; % if no active target in queue, just stay put
			else % there's a target active, so figure out how to go towards it.				
				% What to do if I just switched to a new target to go after
				if obj.totalTargetsSought ~= obj.oldTotalTargetsSought % if true then this is new
					obj.oldTotalTargetsSought =  obj.totalTargetsSought;
					% update the start location with the current Cursor location
					obj.startLocation = obj.cursor_h.xyz;
					% precompute the velocity profile
					totalDist = sqrt( (obj.startLocation - currTarget.xyz)*(obj.startLocation - currTarget.xyz)' );
					t = 1/obj.rate: 1/obj.rate : obj.timeToTarget;
					v = sin(pi*t/obj.timeToTarget);
					obj.speedProfile = v .* totalDist / sum(v);
					obj.speedProfile([1 end]) = 0; % else roundoff error will add up as we wait at endpoint
					obj.currentStep = 0;
				end
				
				% geometry time!
				diff_vector = currTarget.xyz - obj.cursor_h.xyz;
				if any( diff_vector ) % the else condition takes care of divide by zero that would happen when target is right on cursor.
					unit_vector =  diff_vector/sqrt(diff_vector*diff_vector');
				else
					unit_vector = [0 0 0];
				end
				
				obj.currentStep = min( obj.currentStep + 1, length( obj.speedProfile ) ); % if we reach end of movement, use last (zero) value
				inst_speed = obj.speedProfile(obj.currentStep);
				
				inst_velocity = inst_speed .* unit_vector;
			end % else if isempty(currTarget)
			% now move the cursor
			SetXYZ( obj.cursor_h, obj.cursor_h.xyz + inst_velocity );
% 			
%            % and send out the new xyz over UDP. Format is:
%            % | PacketID | timestamp | cursor x | cursor y | cursor z | cursor click | ... 
%            % NOTE: These lines aren't reached when the cursor isn't moving
%            % due to the return in the top if statement of this timer
%            % function. If that's a problem, change this.
% 		   obj.UDPsendCounter = obj.UDPsendCounter + 1;
% 		   if obj.UDPsendCounter >= obj.UDPsendEveryNsteps %I might not UDP send my movements every step.
% 			   sendPacket = zeros(1,64); % The convention is to send 64 double packets
% 			   sendPacket(1:6) = [obj.packetID datenum(clock) obj.cursor_h.xyz 0]; % packetID 11
% 			   StyxSendUDP( obj.gameUDP, sendPacket )
% 			   obj.UDPsendCounter = 0;
% 		   end

           
        end %TS_C_S_TimerFcn( obj, timerObj, event )
    
    end %methods (Access = public)        
        
end %classdef
