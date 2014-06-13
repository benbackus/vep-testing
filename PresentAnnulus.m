function [ ] = PresentAnnulus( contrastText )
%PRESENTANNULUS Summary of this function goes here
%   Detailed explanation goes here

if nargin < 1 
    contrastText = '';
end

presentPairs = 10; % Number of pairs of presentations

% Stimulus parameters
Porig = struct();
Porig.bgLuminance = 6.2/227.6; % TODO specify in absolute Cd/m^2 units
Porig.outerRadiusDeg = 2;
Porig.innerRadiusDeg = 1;
Porig.fixColor = 255 * 0.3 * 6.2/227.6;
Porig.fixWidthDeg = 0.5;
Porig.fixLineWidthPx = 3;

Pempty = Porig;
Pempty.eyesToDraw = [0 1];
Pempty.outerRadiusDeg = 0;
Pempty.innerRadiusDeg = 0;
Pempty.stimLuminance = Pempty.bgLuminance; % just to be sure

e = []; %caught exception
HW = HardwareParameters();
[didHWInit, HW] = InitializeHardware(HW);
server = PL_InitClient(0);

LPTSetup();
LPT_Stimulus_Trigger = 4;
LPT_Stimulus_End = 1;

exitFlag = false;

try
    % Calibrate pupil
    CalibratePupil(HW, server);
    
    % Five-minute countdown
    breakLength = 5*60;
    updateLength = 10;
    for time = breakLength:-updateLength:0
        fprintf('Time remaining: %is\n', time);
        pause(updateLength);
    end

    % Open data file for responses to task
    dataColumns = {'pairCount', 'WhichEye', 'plexonGoTime', 'Contrast', 'BlinkDetected'};
    sessionName = [];
    while length(sessionName) < 2
        sessionName = input('Session name - main pupil experiment (Subjectcode+experimentInitial):', 's');
        if length(sessionName) < 2
            fprintf('Session name too short!\n');
        end
    end
    datafile = DataFile(DataFile.defaultPath(sessionName), dataColumns);
    
    [~] = input('Start Plexon data collection and press Enter...','s');
    
    while ~exitFlag
        % Show blank for now...
        HW = DrawAnnulus(HW, Pempty);
        
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
                contrastText = input('Which contrast (l, m, h, f)? (or "x" to exit): ', 's');
            end
        end

        % Calculate stimulus parameters
        P = Porig;
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
                % whether we should present entire stimulus pair (again),
                % ex. because of a blink, etc.
                presentPair = true;
                while presentPair
                    presentPair = false;
                    for eyeToPresent = [0 1]
                        P.eyesToDraw = eyeToPresent;
                        
                        % Wait for subject to be ready...
                        LPTTrigger(LPT_Stimulus_Trigger);
                        go_ts = []; GetEventsPlexon(server);
                        lrStr = ['l' 'r'];
                        fprintf('Waiting for go (#%i-%s)...', ...
                            presCount, lrStr(eyeToPresent+1));
                        while isempty(go_ts)
                            [~,~,go_ts,~]=GetEventsPlexon(server);
                            pause(1e-2); % prevent 100% CPU usage
                        end
                        
                        % Present stimulus for this eye
                        fprintf('Going now!\n');
                        pause(.3);
                        HW = DrawAnnulus(HW, P);
                        pause(.1);
                        HW = DrawAnnulus(HW, Pempty);
                        pause(1.0);
                        LPTTrigger(LPT_Stimulus_End);
                        
                        % Check for blinks, just up to this point
                        [~,~,~,stop_ts]=GetEventsPlexon(server);
                        blinkDetected = ~isempty(stop_ts);
                        
                        % Write to data file
                        % (timestamp, contrast, eye, whether blink was detected)
                        datafile.append([presCount, eyeToPresent, go_ts, contrast, blinkDetected]);
                        
                        if blinkDetected
                            presentPair = true;
                            fprintf('Blink detected!\n');
                            break; % Redo entire pair
                        end
                        
                        % Not delaying before next trial here - Plexon
                        % machine controls delay before it will send next
                        % 'go' signal
                        %pause(0.0);
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

