% Allows user to visually draw a response kernel
xLim = [0    .25];
yLim = [-.4   .4];

figh = figure;
axh = axes( 'XLim', xLim, 'YLim', yLim)
hold on;

key = 1;

i = 1;
clear('kernel');
while key == 1
    [x y key] = ginput(1);
    kernel.x(i) = x;
    kernel.y(i) = y;
    scatter( x, y, 'o', 'SizeData', 16);
    i = i + 1;
end


%% 
% Generates a vector u which is based off of the drawn kernel, but evenly 
% spaced at the 1ms level.
t = xLim(1) : 0.001 : xLim(2);
u = zeros( numel(t), 1 );
for i = 1 : numel(t);
    myT = t(i);
    [~, ind] = min( abs( myT - kernel.x ) );
    u(i) = kernel.y( ind );
end

%% Save this vector with speciied name
myName = 'OFFkernel';
save( myName, 'u' )