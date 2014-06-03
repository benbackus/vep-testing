function DrawFixationMark(HW, color, fixWidthDeg, fixLineWidthPx)
fixWidthPx = fixWidthDeg * HW.ppd;
presCenter = 0.5*(HW.screenRect([1 2]) + HW.screenRect([3 4]));

for eye = [0 1]
    HW = ScreenCustomStereo(...
        HW, 'SelectStereoDrawBuffer', HW.winPtr, eye);

    % Choose direction of nonius lines
    if eye == 0
        noniusDir = -1;
    else
        noniusDir = 1;
    end
    
    % Draw the Nonius Lines
    Screen('DrawLine', HW.winPtr, ...
        color, presCenter(1), presCenter(2)+noniusDir*0.75*fixWidthPx,  ...
        presCenter(1), presCenter(2)+noniusDir*1.5*fixWidthPx, fixLineWidthPx);
    Screen('DrawLine', HW.winPtr, ...
        color, presCenter(1)+noniusDir*0.75*fixWidthPx, presCenter(2),  ...
        presCenter(1)+noniusDir*1.5*fixWidthPx, presCenter(2), fixLineWidthPx);
    
    % Draw the fixation box itself
    Screen('FrameRect', HW.winPtr, color, ...
        [presCenter-0.5*fixWidthPx, presCenter+0.5*fixWidthPx], ...
        fixLineWidthPx);
end
end
