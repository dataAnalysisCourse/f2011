Basically the idea is if you define a function with variable input arguments

    function foo(bar, varargin)

    def.paramName1 = 1;
    def.paramName2 = 2;

    assignargs(def, varargin);

    fprintf('paramName1 = %d, paramName2 = %d\n', paramName1, paramName2);


Then if you call this function like:

	foo(bar, 'paramName1', 20);

and you'll get this output:

	paramName1 = 20, paramName2 = 2

Basically, assignargs looks at the list of extra arguments you pass in and looks for pairs of string/value pairs, much like the set() or plot() commands take their extra inputs. It then assigns into the calling workspace (i.e. the workspace of foo) values for each variable that it encounters in this name/value pair list -or- in the struct of default values (def) that it receives. So in this example, you'll end up with two variables, paramName1 which will receive the overriding value of 20 that you passed in, and paramName2 which takes the default value of 2.

There are a few other things you can do as well. First, if you don't want to have the variables assigned directly into your workspace, you can use structargs instead. Same thing, except you call it like:

	def = structargs(def, varargin);

and instead of writing variables into your workspace, it will just return a struct that looks just like def except with values overridden and additional values added.

Rather than passing in extra parameters in string/value pairs, you can also pass them in using a struct too if you provide this struct as the first extra argument. You can also use string/value pairs after this struct input as well, with the named string/value pairs having the final overriding power.

	params.paramName2 = 5;
	foo(bar, params, 'paramName1', 20);

I use these two features to pass arguments to nested functions. If I call another function nestedFunction inside of foo(), then I can send in overriding parameters from the command line that are meaningful inside nestedFunction as well, as long as I have foo work like this:

	function foo(bar, varargin)

	def.paramName1 = 1;
	def.paramName2 = 2;

	def = assignargs(def, varargin);

	nestedFunction(bar, def);

and if nestedFunction looks like:

	function nestedFunction(bar, varargin)

	def.plotType = 'awesome';
	assignargs(def, varargin);

	if(strcmp(plotType, 'awesome'))
		error('Get better data if you want your plots to be awesome!');
	end

then I can call foo like this:

	foo(bar, 'paramName1', 10, 'plotType', 'awesome');

What's going on here is that I'm assigning paramName1, paramName2 into the workspace using assignargs, but I'm also overriding/adding values to def (in the way that structargs works, assignargs actually does both if ask for the return value), and then passing def as an extra argument to nestedFunction. Then nestedFunction internally calls assignargs and work the same way. This enables you to override default parameters "deep" into your plotting utilities without too much effort.

Lastly, if you don't like assembling your default values into a def struct to pass into assignargs/structargs, you can have these functions pull their "defaults" from the set of variables that exist in the caller's workspace. You can accomplish this simply by omitting the first argument to assignargs/structargs, like this:

	function nestedFunction(arg1, varargin)

	message = 'default message';
	assignargs(varargin);

	fprintf('Message: %s\n', message);

	end

