% try running this: demo(5, 'paramName1', 10, 'message', 'hello world!')

function demo(arg1, varargin)

def.paramName1 = 1;
def.paramName2 = 2;

def = assignargs(def, varargin);

fprintf('arg1 = %s, paramName1 = %d, paramName2 = %d\n', mat2str(arg1), paramName1, paramName2);

nestedFunction(arg1, def);

end

function nestedFunction(arg1, varargin)

% this function demos the other method of using assignargs/structargs
% in that it uses all variables defined in the current workspace rather 
% than requiring defaults to be grouped into a struct

message = 'default message';
assignargs(varargin);

fprintf('Message: %s\n', message);

end
