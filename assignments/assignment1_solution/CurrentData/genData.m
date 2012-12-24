% genData.m
% NENS 230 Autumn 2011   Assignment 1
% Written by Sergey Stavisky on 26 September 2011
%
% Generates fake waveforms that look rather like an action potential
% at a randomly timed interval from t=0s to t=7seconds
function genData

    myDir = which( mfilename );
    fSepIdx = strfind( myDir, filesep );
    myDir = myDir(1: fSepIdx(end) );
    R = 8e6; % Electrode resistance in ohms
    
    % stereotyped action-potential-like waveform
    for i = 1 : 5
        t{i} = (0.1:0.1:10)';
        v{i} = repmat(-65,length(t{i}),1);
        tSpikeStartInd = ceil(65*rand);
        v{i}(tSpikeStartInd:tSpikeStartInd+30) = v{i}(tSpikeStartInd:tSpikeStartInd+30)+[ (95+10*rand)*sinc(-1:.1:1) 30*sinc( 1.1:.1:2)]';
        v{i} = v{i} + 3*randn(length(v{i}),1); % add gaussian noise
        v{i}(1:5) = 100; % bad measurements at start of trace.
        v{i} = v{i}./1000; % go from mV to V
        current = ( v{i}/R )*1e9;  %; I = V/R;  This is in nA
%         subplot(5,1,i); plot(v{i}); % DEV
        thisIvar = sprintf('I_%i', i);
        thisTvar = sprintf('t_%i', i);
        eval( [thisTvar ' = t{i}+10*(i-1);'] );
        
        % t_1 is messed up
        if i == 1
            t_1 = t_1';
            t_1 = [t_1(1:50) 0 t_1(51:end)];
        end
        
        thisfile = sprintf('I_trace_segment%i', i);
        eval([thisIvar '=current;']);
        save( [myDir thisfile], thisIvar, thisTvar )
    end

end %function
