function [ HW ] = DrawAnnulus( HW, P )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% eyesToDraw, stimLuminance, bgLuminance, innerRadius, outerRadius

%screenSize = HW.screenRect([3 4]) - HW.screenRect([1 2]);
screenCenter = 0.5*(HW.screenRect([1 2]) + HW.screenRect([3 4]));

% [bgColorVal, ~, HW] = LumToColor(HW, P.bgLuminance);
% [stimColorVal, ~, HW] = LumToColor(HW, P.stimLuminance);
bgColorVal = HW.white * P.bgLuminance;
stimColorVal = HW.white * P.stimLuminance;

for eye = [0 1]
    HW = ScreenCustomStereo(...
        HW, 'SelectStereoDrawBuffer', HW.winPtr, eye);
    Screen('FillRect', HW.winPtr, bgColorVal);
    
    if any(eye == P.eyesToDraw)
        Screen('gluDisk', HW.winPtr, stimColorVal, ...
            screenCenter(1), screenCenter(2), P.outerRadiusDeg * HW.ppd);
        Screen('gluDisk', HW.winPtr, bgColorVal, ...
            screenCenter(1), screenCenter(2), P.innerRadiusDeg * HW.ppd);
    end
end

HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);

end

