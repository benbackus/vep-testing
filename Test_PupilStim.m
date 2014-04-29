e = []; %caught exception
HW = HardwareParameters();
[didHWInit, HW] = InitializeHardware(HW);

iters = 10;
pauseTime = 0.5;

P = struct();
P.stimLuminance = .8;
P.bgLuminance = .4;
P.outerRadiusDeg = 2;
P.innerRadiusDeg = 1;
try
    for i=1:iters
        %% Single frame of stimulus
        P.eyesToDraw = mod(i, 2);
        HW = DrawAnnulus(HW, P);
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
