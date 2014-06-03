function [ HW ] = DrawAnnulus( HW, P )
%DRAWANNULUS Summary of this function goes here
%   Detailed explanation goes here
% eyesToDraw, stimLuminance, bgLuminance, innerRadiusDeg, outerRadiusDeg

screenCenter = 0.5*(HW.screenRect([1 2]) + HW.screenRect([3 4]));

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

if isfield(P, 'fixColor')
    DrawFixationMark(HW, P.fixColor, P.fixWidthDeg, P.fixLineWidthPx);
end

HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);

end

