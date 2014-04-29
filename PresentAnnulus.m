function [ ] = PresentAnnulus( contrastText )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

if nargin < 1 
    contrastText = '';
end

presentPairs = 10; % Number of pairs of presentations

Porig = struct();
Porig.bgLuminance = 0.1; % TODO specify in absolute Cd/m^2 units
Porig.outerRadiusDeg = 2;
Porig.innerRadiusDeg = 1;

e = []; %caught exception
HW = HardwareParameters();
[didHWInit, HW] = InitializeHardware(HW);

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
                case {'f', 'full', 'flash'}
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
            P.outerRadiusDeg = 100;
            P.innerRadiusDeg = 0;
        else
            P.stimLuminance = P.bgLuminance * (1.0 + contrast);
        end

        if ~exitFlag
                for presCount = 1:presentPairs
                    for eyeToPresent = [0 1]
                        P.eyesToDraw = eyeToPresent;
                        
                        pause(.3);
                        HW = DrawAnnulus(HW, P);
                        pause(.1);
                        HW = DrawAnnulus(HW, Pempty);
                        pause(2.0);
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

