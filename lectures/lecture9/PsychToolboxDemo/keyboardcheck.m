beep;
% pause(2);

WaitSecs(0.1); % so if called from commandline it won't pick up the previous enter.
[secs, keyCode] = KbWait;

% [keyIsDown, secs, keyCode] = KbCheck; 

keyInt = find(keyCode);

if keyInt==KbName('space')
    try
        fprintf('Starting stimuli after WaitForRec\n')
        WaitForRec;
    catch exception
        fprintf('Tried and failed to call WaitForRec\n')
    end
else
    fprintf('Starting stimuli without WaitForRec\n')
end