% contDatObject CLASS
% 
% Continuous neural data is stored and manipulated (filtered, etc) in this
% object. Has methods for generating derivative signals, for example
% frequency power band. 
% A single trial's data is contained in one contDatObject.
%
% NOTE: This is very much a work in progress.
% 
% SDS April 29 2011

classdef contDatObject < dynamicprops  % use dynamic props so that frequency bands can be added at will
    
    
    %*********************************************************
    %                       PROPERTIES
    %*********************************************************
    properties
        arraySource;     % When the Robject is created, this should be filled out with
                         % the .dir and .extension for finding the
                         % continuous neural data for this Robject.
                         % Example: 
                         %   arraySource{1}.dir = '/net/data/JenkinsC/rawdata/2011-04-19/cerebus/M1/';
                         %   arraySource{1}.extension = 'ns3';
        raw = struct( 'dat', [],'rate', [], 't', [] )   % neural data as it originally comes in from the .nsx files. 
                         % I add 't' which is the seconds of each sample from the start of the trial (can be negative if there is a bufferSecs)
                         % IMPORTANT: remember to modify '.t' when you also modify '.dat'        
                         
        channelID        % usually 1 through 96, but could be different if some channels aren't being recorded. Pulled out of the NSX header.
                         % note that this only applies to signals that arise from one electrode (so not e.g. PCA signal).
        channelArray     % index into arraySource of which array each channel came from
        bufferSecs       % this many seconds have been added on the start and end of the trial
        alignTo          % records alignment to the matching R struct data of this continuous neural data.
    end % public properties
        
    % DEPENDENT PROPERTIES
    properties (Dependent = true, SetAccess = private)
        numChans
    end % dependent properties
    
    
    
    
    methods   
        %                   CONSTRUCTOR
        function obj = contDatObject( varargin )
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
        function numChans = get.numChans( obj )
           numChans = length( obj.channelID );
        end
        
       

        %*********************************************************
        %                 Filtering Methods
        %*********************************************************
        function obj = AddFilteredBand( obj, bandName, fpass, movingwin, sourceSignal )
        % Adds a new signal which is the bandpass power. Uses chronux multitaper
        % methods.
        % INPUTS:
        %    bandName    name of the new signal
        %    fpass       [lowHz highHz] vector describing the band.
        %    movingwin   2x1 vector describing the width and step size of the sliding window
        %                containing the data that is filtered and rectified/integrated to get
        %                a sample point of the new power signal.
        %    sourceSignal     name of the source signal. Its .dat field should be chans x samples
            if ~isproperty( obj, sourceSignal ) || isempty( obj.(sourceSignal).dat )
                error('[%s: AddFilteredBand] <sourceSignal> %s does not exist or is empty.', ...
                    mfilename, sourceSignal )
            end
        
            if isproperty( obj, bandName );
                obj.(bandName) = [];
                fprintf('[%s: AddFilteredBand] Warning: contDatObject already has a property ''%s''. Overwriting it.. this may not be what you intended!\n', mfilename, bandName)
            else
                P = addprop( obj, bandName );
            end

            
            % build params structure for filtering
            params.movingwin = movingwin; 
            params.Fs = obj.(sourceSignal).rate;
            params.fpass = fpass;

              
            % band-pass filter the data, square it, then integrate across the window
            order = 3;
            cutoff = params.fpass; %Hz
            [b, a] = butter( order,  cutoff*(2*pi), 'bandpass', 's' );
            [b, a] = bilinear(b, a, params.Fs); % goes from analog filter to a digital filter
            bandpassed = filter( b, a, double( obj.(sourceSignal).dat' ) )'; % transpose inside because samples must be in columns!
            signalPower = bandpassed.^2; % My initial approach.           
            
            % bin according to movingwin; this in effect integrates.
            binStartInd = 1 : params.movingwin(2)*params.Fs : size(signalPower,2)-params.movingwin(1)*params.Fs ;
            binEndInd = binStartInd + params.movingwin(1)*params.Fs - 1;
            
            windowAvg = zeros( obj.numChans, length(binStartInd) ); % will put binned neural data here            
            for window_i = 1 : length( binStartInd )
                % average across samples in the window 
                windowAvg(:,window_i) = mean( signalPower(:,binStartInd(window_i):binEndInd(window_i)), 2 );                 
            end %for window_i = 1 : length( binStartInd )
            % the timestamp of the window is the END of that window
            windowT = obj.(sourceSignal).t(binEndInd);
            
            % Since filtering is crazy at the ends, let's remove 500ms from each end so that I don't
            % accidentally try to use this data later
            clipBins = 0.500 / params.movingwin(2);
            windowAvg = windowAvg(:,clipBins+1:end-clipBins);
            windowT = windowT(clipBins+1:end-clipBins);
            
            obj.(bandName).rate = 1/movingwin(2);
            obj.(bandName).dat = windowAvg;
            obj.(bandName).params = params;     
            % time since whenever the trial alignment in getContDat was set to be
            %; note that these are the ENDS of the windows 
            % It was center until 7/21/2011
            obj.(bandName).t = windowT;
          
        end %function obj = AddFilteredBand( obj, bandName, fpass, movingwin )
            
        function obj = FilterContData( obj, sourceSignal, b, a, filterfunc, newSignalName )  
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
            %              I've added a .(newSignalName) structure contianing a .dat, .params, .rate, and .t fields
            if isproperty( obj, newSignalName );
                obj.(newSignalName) = [];
                fprintf('[%s: FilterContData] Warning: contDatObject already has a property ''%s''. Overwriting it.. this may not be what you intended!\n', ...
                    mfilename, newSignalName)
            else
                P = addprop( obj, newSignalName );
            end
            
            obj.(newSignalName).dat = (filterfunc(b, a, double( obj.(sourceSignal).dat' )))'; % needs to be a double I think
             
            % Note the double transpose so things stay ch x sample                
            obj.(newSignalName).t = obj.(sourceSignal).t; % t=0 being whatever the trial alignment used in getContDat was set to be
            obj.(newSignalName).rate = obj.(sourceSignal).rate;

            % Also store the filter parameters used to generate this data.
            obj.(newSignalName).params.b = b;    
            obj.(newSignalName).params.a = a;   
            obj.(newSignalName).params.filterfunc = filterfunc;
            

            
        end %obj = FilterContData( obj, sourceSignal, b, a, filterfunc, newSignalName )  
        
   
        
        
        function obj = AddLinTransformedSignal( obj, sourceSignal, transMat, newSignalName)
            %*********************************************************
            %              Linear Transformations of Data
            %*********************************************************
            % Creates a new signal that is stored in a new property of this contDatObject, which is a linear transformation
            % of a different, already-existing signal (e.g. PCA from raw signal).
            %
            % USAGE:
            %    contDatObj = contDatObj.AddLinTransformedSignal( sourceSignal, transMat, newSignalName )
            % INPUTS:
            %    sourceSignal     name of the source signal. Its .dat field should be chans x samples
            %    transMat         this is the matrix that transforms the sourceSignal. It should be chans x k
            %                     where k is the dimensionality of the new signal.
            %    newSignalName    a new property with this name will be created to store the new signal
            %    sourceSignal    from which signal to generate the band power. Typically would be 'raw'
            % OUTPUTS:
            %    obj       updated contDatObj. Since these are pass-by-value objects, you must use this output or the modificaitons
            %              will be lost.
            %
            % Confirm that the source signal exists and that the transMat is of the appropriate dimension
            if ~isproperty( obj, sourceSignal )
                error('[%s: AddLinTransformedSignal] <sourceSignal> %s does not exist in this contDatObject.',...
                    mfilename, sourceSignal)
            end    
            if size( obj.(sourceSignal).dat, 1 ) ~= size( transMat, 1 )
                error('[%s: AddLinTransformedSignal] Incompatible dimensions. <sourceSignal> has dimensionality %i but <transMat> has %i rows',...
                    mfilename, size( obj.(sourceSignal).dat, 1 ), size( transMat, 1 ) );
            end
                 
            % Create the new signal. Warn user if a signal of the same name already exists
            if isproperty( obj, newSignalName );
                obj.(newSignalName) = [];
                fprintf('[%s: AddLinTransformedSignal] Warning: contDatObject already has a property ''%s''. Overwriting it... this may not be what you intended!\n', ...
                    mfilename, newSignalName )
            else
                P = addprop( obj, newSignalName );
            end
            
            % Create the new signal as a transformation of the source signal. time and rate stay the same
            obj.(newSignalName).dat = transMat' * double( obj.(sourceSignal).dat );  % Need to convert source data to double 
            obj.(newSignalName).t = obj.(sourceSignal).t;
            obj.(newSignalName).rate = obj.(sourceSignal).rate;                         
        end %obj = AddLinTransformedSignal( obj, sourceSignal, transMat, newSignalName)
            
        %*********************************************************
        %                    Query Methods
        %*********************************************************
        function [samples seconds] = Duration( obj, signal )
            % USAGE: [samples seconds] = Duration( obj, signal )
            % EXAMPLE: [samps, secs] = Duration( myTrial.contDat, 'raw' )
            %
            % returns the duration both in number of samples and number of seconds
            % that this represents of the continuous data of source 'signal;
            keyboard
            
            % NOT IMPLEMENTED YET
            
            
        end %function [samples seconds] = Duration( obj, signal )
        
        function [dat t rate] = Snippet( obj, featureField, startT, endT )
            
            % INPUTS
            %     featureField   String which specifies which feature to use. 'raw' would, for example
            %                    pull out the raw continuous data voltages.
            %     startT         start time (in seconds) of the feature to grab from each trial. Uses the .(featureField).t field to match time to sample
            %     endT           end time (in seconds) of the feature to grab from each trial. Uses the .(featureField).t field to match time to sample
            % OUTPUTS:
            %     dat            the data matrix
            %     t              the timestamps attached to each sample [note: I created these when the data was built; it doesn't come straight from the .nsx files]
            %     rate           sample rate of this data.
            

            % Make sure the specified featureField exists
            if ~isproperty( obj, featureField)
                error('[%s] ''%s'' is not a property of this %s', mfilename, featureField, class( obj ) );
            end
            
            % compute startInd and endInd by converting from seconds to sample index in the data
            % using the .t field. I don't require exact numerical match, but rather look for the closest sample.
            % Will throw an error if more than 100ms off (I use such a big threshold because features like
            % beta power might have relatively sparse sampling           
            [~, startInd] = min( abs( obj.(featureField).t - startT ) );
            if abs( obj.(featureField).t(startInd) - startT ) > 0.005
                fprintf(2,'[%s:Snipper] Warning. startT was specified as %f, but closest matching obj.%s.t was %f. This might indicate a problem.\n',...
                    mfilename, startT, featureField, obj.(featureField).t(startInd)   )
            end
            [~, endInd] = min( abs( obj.(featureField).t - endT ) );
            if abs( obj.(featureField).t(endInd) - endT ) > 0.005
                fprintf(2,'[%s:Snipper] Warning. endT was specified as %f, but closest matching obj.%s.t was %f. This might indicate a problem.\n',...
                    mfilename, endT, featureField, obj.(featureField).t(endInd)   )
            end
            
            % Now return the sought data
            dat =  obj.(featureField).dat(:, startInd:endInd);
            t = obj.(featureField).t(startInd:endInd);
            rate = obj.(featureField).rate;         
        end
        
    end % methods
    
end