% NENS 230 Autumn 2011
% Demonstrates the use of multiple inputs and outputs in a function.

function [out1, out2, out3] = flexibleFunction( arg1, arg2, arg3, varargin )
    
    % Define outputs
    out1 = 1;
    out2 = 2;
    out3 = 3; 
    

    
    
    % nargin tells us how many input arguments were provided when this function
    % was called.
    fprintf('%i input arguments\n', nargin)
    
    % Report inputs. Note that I must use nargin to make this work 
    % regardless of what was input.
    if nargin >= 1 
        fprintf('Defined argument 1 is %s\n', mat2str( arg1 ) )
    else
        fprintf('Absolutely no arguments were provided!\n')
    end
    
    if nargin >= 2
        fprintf('Defined argument 2 is %s\n', mat2str( arg2 ) );
    end
    
    if nargin >= 3
        fprintf('Defined argument 3 is %s\n', mat2str( arg3 ) );
    end
    
    if nargin < 3 || isempty( arg3 )
        arg3 = 'defaultArg3';
        fprintf('No arg3 was provided, so I am giving it a default of %s\n', mat2str( arg3 ) )
    end
    
    % Now let's report what our variable arguments were
    numVariableArgs = max( [nargin-3  0] ); % sets zero as minimum.
    fprintf('There were %i variable arguments\n', numVariableArgs);
    for iArg = 1 : numVariableArgs
        fprintf('Variable Argument %i is %s\n', iArg, mat2str( varargin{iArg} ) );
    end
    
    % We can even use variable arguments combined with eval( ) function
    % to create a Parameter-Value Pair functionality for our function:
    for iArg = 1 : 2: numVariableArgs
       varName = varargin{iArg};
       if ischar( varName )    
           varValue = varargin{iArg+1};
           myCommand = sprintf('%s = %s',  varName, mat2str( varValue ) );
           eval( myCommand )
       end
    end
    
end %function