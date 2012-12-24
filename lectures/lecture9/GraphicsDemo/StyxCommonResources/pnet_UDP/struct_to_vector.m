function out = struct_to_vector(input, prescribed_vector_length)
% The function converts a data structure into a mx1 vector of doubles.
% Call the corresponding method vector_to_struct on the output from
% this function to recover the original structure.
%
%Input: input - the structure
%       prescribed_vector_length (optional input) [scalar] - if this value is entered, then the output
%         vector will be padded with zeros such that the length of the output is 'prescribed_vector_length'
%         in length. The reason for this input is it appears simulink is expecting the vector being passed
%         from a function to always be the same length during a simulation. As the field names or number of fields
%         change, strings lengths change, or array/cell sizes of a structure are changed, the length of the output vector
%        required to parse it would change accordingly. In this instance, use this input to force the length to be equal to 
%         'prescribed_vector_length' in all cases. If only numeric values within a structure change between calls,
%         the output vector length would remain the same, and there would be no need to use this input. In any 
%         case, the value of 'prescribed_vector_length' must be larger then the length of the vector required 
%         to parse the structure or an error occurs.
%         
%
%
%
%Output: vector (mx1) of doubles
%
% Ver 1.0, Eric Olsen, JHU/APL 10/16/02
% Current version supports structures (1x1, with arbitrary number of fields) made up of numeric
% arrays (arbitrary dimensions), strings, cells (arbitrary dimensions), and other 
% structures (1x1, with arbitrary number of fields). Cells may contain other cells, structures(1x1),
% arrays and strings.
%
%Limitiation: does not support higher dimensioned structures, however, if an array of structures was
%desired (matlab constrains the field names of each structure to be the same in this case), a field
%which was a cell of structures could be used as an alternative.
%

%Algorithm:
%The structure is recursively parsed to generate a mx1 vector of doubles. The names of the fields of each structure
%are identified, and each field is parsed to extract the data contained therein.
%
%The following data types are identified by a code: field names, strings, cells, and numeric arrays. There is a
%code,END_STRUCT_FIELDS, tagged to the end of the data corresponding to the last field of a structure being parsed. As each
%field is parsed, a code and the associated data are appended to the output vector. The codes are used to reconstruct
%the original structure from the vector output.
%
%A field name is identified by the following numeric sequence:
%   [FIELD_NAME_CODE (scalar) , # of characters in field name (scalar, f), ascii value of each character in the name(fx1), subcode]
%A numeric array, A, is identified by the following subcode:
%   [NUMERIC_ARRAY_CODE (scalar), # of dimensions (scalar value of d), dimensions of array (dx1), array values parsed as A(:)]
%A string, S, is identified by the following subcode:
%   [STRING_CODE (scalar), # of characters in S (scalar, f), ascii value of each character in the string (fx1)]
%A cell, C, is identified by the following subcode:
%   [CELL_CODE  (scalar), # of dimensions (scalar value, d), dimensions of cell (dx1), subcodes corresponding to cell parsed
%                                                                                      as C(:)                              ]


out=get_code(input)';

if(nargin ==2)
  m=length(out);
  if(m > prescribed_vector_length)
     error('must allocate greater vector size in struct_to_vector');
  else
    out=[out;zeros(prescribed_vector_length-m,1)];
  end;
end;
  
function out = get_code(input)
out=[];

%parsing codes
FIELD_NAME_CODE = 1000;      %code for field name
NUMERIC_ARRAY_CODE = 2000;   %code for array 
STRING_CODE = 3000;          %code for string
CELL_CODE = 4000;            %code for cell 
END_STRUCT_FIELDS = 5000;    %code to indicate the fields of the current structure being parsed are done.

if(isstruct(input)) %parse a structure
  names = fieldnames(input); 
  for i = 1:length(names) %parse the fields of the structure
    out = [out, FIELD_NAME_CODE length(double(names{i})) double(names{i}) get_code(eval(['input.',names{i}]))];
  end;  
    out = [out,END_STRUCT_FIELDS];
elseif(iscell(input)) %parse a cell
    out=[CELL_CODE length(size(input)) size(input)]; %cell info
    cell_column=input(:);  %put into column   
    for i=1:length(cell_column) %parse the elements of the cell
      out=[out,get_code(eval(['input{',num2str(i),'}']))];
    end;   
elseif(ischar(input)) %parse a string
   out=[STRING_CODE length(double(input)) double(input)];
else  %parse a numeric array   
   out = [NUMERIC_ARRAY_CODE length(size(input)) size(input) input(:)'];
end;
    