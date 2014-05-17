function [ ] = PresentAnnulus( contrastText )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

if nargin < 1 
    contrastText = '';
end

presentPairs = 10; % Number of pairs of presentations

Porig = struct();
Porig.bgLuminance = 0.01; % TODO specify in absolute Cd/m^2 units
Porig.outerRadiusDeg = 2;
Porig.innerRadiusDeg = 1;

e = []; %caught exception
HW = HardwareParameters();
[didHWInit, HW] = InitializeHardware(HW);
server = PL_InitClient(0);

LPTSetup();
LPT_Stimulus_Trigger = 4;
LPT_Stimulus_End= 1;

exitFlag = false;

try
    while ~exitFlag
        % Ask for the contrast (or exit)
        contrast = [];
        while isempty(contrast)
            switch lower(contrastText)
                case {'l', 'low'}
                    contrast = 0.3;
                case {'m', 'medium'}
                    contrast = 0.6;
                case {'h', 'high'}
                    contrast = 1.8;
                case {'f', 'ff', 'full', 'flash'}
                    contrast = Inf;
                case {'x', 'exit'}
                    exitFlag = true;
                    contrast = 0;
            end
            if (isempty(contrast))
                contrastText = input('Which contrast? (or "x" to exit): ', 's');
            end
        end

        % Calculate stimulus parameters
        P = Porig;
        Pempty = P;
        Pempty.stimLuminance = Pempty.bgLuminance;
        Pempty.eyesToDraw = [0 1];
        if isinf(contrast)
            % Full field flash
            P.stimLuminance = 1.0;
            P.outerRadiusDeg = 170;
            P.innerRadiusDeg = 0;
        else
            P.stimLuminance = P.bgLuminance * (1.0 + contrast);
        end

        if ~exitFlag
            PL_GetTS(server); % erase existing timestamps
            for presCount = 1:presentPairs
                for eyeToPresent = [0 1]
                    needToPresent = true; % whether to present (again)
                    while needToPresent
                        P.eyesToDraw = eyeToPresent;

                        LPTTrigger(LPT_Stimulus_Trigger);
                        go_ts = []; GetEventsPlexon(server);
                        fprintf('%s', 'Waiting for go...');
                        while isempty(go_ts)
                            [~,~,go_ts,~]=GetEventsPlexon(server);
                            pause(1e-2); % prevent 100% CPU usage
                        end
                        fprintf('%s\n', 'Going now!');
                        pause(.3);
                        HW = DrawAnnulus(HW, P);
                        pause(.1);
                        HW = DrawAnnulus(HW, Pempty);
                        pause(1.0);
                        LPTTrigger(LPT_Stimulus_End);
                        
                        % Check for blinks
                        [~,~,~,stop_ts]=GetEventsPlexon(server);
                        needToPresent = ~isempty(stop_ts);
                        if needToPresent
                            fprintf('%s\n', 'Blink detected!');
                        end
                    end
                end
            end
        end
        contrastText = ''; % Reset for next contrast
    end
catch e
end

if didHWInit
    HW = CleanupHardware(HW); %#ok<NASGU>
end
if ~isempty(e)
    rethrow(e);
end

end

