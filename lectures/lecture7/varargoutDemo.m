% NENS 230 Autumn 2011
% Demonstrates returning multiple outputs from a function, 
% using nargout to check how many outputs are expected by the caller,
% and varargout to let the function determine how many outputs to return.

function [out1, out2, varargout] = varargoutDemo()
    out1 = 'Defined Output 1';
    out2 = 'Defined Output 2';  % YOU MUST DEFINE ALL OUTPUTS! UNCOMMENT THIS

    % nargout tells you how many output arguments the calling function expects
    fprintf('This was called with %i output arguments expected\n', nargout)
    
    % If you are output a variable number of outputs, you set them using the
    % varargout{index} syntax.
    varargout{1} = 'Variable Output 1';
    varargout{2} = 'Variable Output 2';
    varargout{3} = 'Variable Output 3';
   

end %function