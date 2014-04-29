function [ didHWInit, HW ] = InitializeHardware( HW )
%INITIALIZEHARDWARE Initializes hardware (screen, keyboard, media, etc.)
%   Also does some checks on the runtime environment (mostly PTB stuff)
%   By convention, the function that calls InitializeHardware and receives
%       didHWInit == true (and **ONLY** that function) must call
%       CleanupHardware() afterwards - even if there is a crash!
%   Do *NOT* call CleanupHardware "just in case" - it won't work and
%       may be difficult to debug!
%   Template code:
%     [didHWInit HW] = InitializeHardware(HW);
%     caughtException = [];
%     try
%         % **** Your Code Here ****
%     catch e
%         caughtException = e;
%     end
%     if didHWInit
%         HW = CleanupHardware(HW);
%     end
%     if ~isempty(caughtException)
%         rethrow(caughtException);
%     end
%   If you forget to call CleanupHardware, press Ctrl-C until MATLAB starts
%       to listen to the keyboard again, and then run 'clear screen'
    

    radtodeg = @(rad) rad*180/pi;

    assert(nargin >= 1, 'InitializeHardware:NoParameter', ...
        'Need a hardware parameter struct, but none passed in!');
    assert(nargout >= 1, 'InitializeHardware:HWNotSaved', ...
        ['Hardware parameter from InitializeHardware is not being' ...
        ' saved, but it almost certainly should replace the old HW!']);
    
    % attempt to minimize chance of garbage collection happening
    % at an arbitrary bad time
    % HACK presumes that InitializeHardware is called only when
    %   it is expected that something slow might happen
    java.lang.System.runFinalization();
    java.lang.System.gc();
    
    if isfield(HW, 'initialized') && HW.initialized
        didHWInit = false;
    else
        % Psychometric Toolbox (PTB) 3 (or better?) must be installed
        assert(exist('SetupPsychToolbox', 'file')>0);

        % KLUDGE If PsychJava isn't in the classpath, fix it.
        % (probably forgot to SetupPsychtoolbox on a non-network machine)
        % PsychJavaTrouble;

        AssertOpenGL;

        Screen('Preference', 'SkipSyncTests', 1);

        HW.white = WhiteIndex(HW.screenNum); % depends on datatype
        HW.fps=Screen('FrameRate',HW.screenNum)/2;
        %if HW.stereoMode == 1 % halved for alternate-frame stereo
        %    HW.fps = HW.fps / 2;
        %end
        
        [HW, HW.winPtr, HW.screenRect] = ScreenCustomStereo(...
            HW, 'OpenWindow', HW.screenNum, ...
            0, ... doesn't matter, background filled later
            [], [], [], ...
            HW.stereoMode);
        
        HW = ScreenCustomStereo(HW, 'BlendFunction', HW.winPtr, ...
            GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        monWidthPx = HW.screenRect(3)-HW.screenRect(1);
        monWidthDeg = radtodeg(2*atan(HW.monWidth/HW.viewDist/2));
        HW.ppd = monWidthPx / monWidthDeg; % avg pixels per º visual angle
        
        % Tell MATLAB to not read keystrokes into command window
        ListenChar(2);

        % Initialize audio players
        InitializePsychSound;
        HW.rightSoundHandle = InitSound(HW.rightSound);
        HW.wrongSoundHandle = InitSound(HW.wrongSound);
        HW.failSoundHandle = InitSound(HW.failSound);

        % Set random number generator to our re-seeded one
        RandStream.setGlobalStream(HW.randStream);
        
        % Set default size and position of plots
        set(0, 'DefaultFigurePosition', HW.defaultFigureRect);

        didHWInit = true;
        HW.initialized = true;

        WaitSecs(HW.initPause); % Wait until hardware settles down
    end
end

function pahandle = InitSound(soundData)
    nrchannels = size(soundData.data,2);
    freq = soundData.fs;
    pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
    PsychPortAudio('FillBuffer', pahandle, soundData.data');
end
