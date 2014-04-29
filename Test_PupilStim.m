e = []; %caught exception
[~, ~, HW] = Parameters();
[didHWInit, HW] = InitializeHardware(HW);

iters = 10;
pauseTime = 2;

stimLuminance = 160;
bgLuminance = 128;
outerRadius = 4 * HW.ppd;
innerRadius = 2 * HW.ppd;
[bgColorVal, bgLuminance] = LumToColor(HW, bgLuminance);
try
    for i=1:iters
        %% Single frame of stimulus
        screenSize = HW.screenRect([3 4]) - HW.screenRect([1 2]);
        screenCenter = 0.5*(HW.screenRect([1 2]) + HW.screenRect([3 4]));
        
        for eye = [0 1]
            HW = ScreenCustomStereo(...
                    HW, 'SelectStereoDrawBuffer', HW.winPtr, eye);
            Screen('FillRect', HW.winPtr, bgColorVal);
            
            if eye == mod(i,2)
                Screen('gluDisk', HW.winPtr, stimLuminance, ...
                    screenCenter(1), screenCenter(2), outerRadius);
                Screen('gluDisk', HW.winPtr, bgColorVal, ...
                    screenCenter(1), screenCenter(2), innerRadius);
            end
        end
        
        HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);
        % End single frame
        
        pause(pauseTime);
        
        [ ~, ~, keyCode ] = KbCheck;
        if keyCode(KbName('ESC'));
            break;
        end
    end
catch e
end
if didHWInit
    HW = CleanupHardware(HW);
end
if ~isempty(e)
    rethrow(e);
end
