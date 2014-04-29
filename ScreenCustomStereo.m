function [ HW, varargout ] = ScreenCustomStereo( HW, screenFunc, varargin )
%SCREENCUSTOMSTEREO Abstraction wrapper for stereoscopes
%   Replacements for the following Screen functions:
%     'OpenWindow'
%     'BlendFunction'
%     'MakeTexture'
%     'SelectStereoDrawBuffer'
%     'DrawingFinished' (simply ignored)
%     'Flip'
%     'Close'
%   example:
%     Screen('Flip', HW.winPtr)
%    ... becomes ...
%     HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr)
%   All other Screen calls must always use HW.winPtr for all draws
%
%   Requires two new HW parameters:
%       HW.stereoTexWidth
%           Scalar specifying width of both left and right textures.
%           If less than 1, interpreted as a proportion of the screen
%           width.  It gets converted to pixels during OpenWindow, and is
%           returned in the new HW.
%           Similarly, Inf is interpreted as full screen.
%           If greater than 1, this is interpreted as pixels.
%           Defaults to full screen.
%       HW.stereoTexOffset = [left, right]
%           Horizontal offset of each texture's center, from the center of
%           the screen.
%           If both parameters are less than an absolute value of 1,
%           this is interpreted as a proportion of the screen width.
%           It gets converted to pixels during OpenWindow, and is returned
%           in the new HW.
%           If stereoMode == 0, defaults to [-1/4, 1/4]
%           Defaults to [0,0] otherwise
%   Also requires:
%       HW.screenNum
%       HW.stereoMode
%   
%   See Test_ScreenCustomStereo for example and demo code

global alreadyWarnedDrawingFinished

% TODO if no stereoscope, skip all this?  test overhead of this function...

% Temporary(?) override: just pass-through for regular stereo
if HW.stereoMode == 1 ...
        && (~isfield(HW, 'stereoTexOffset') ...
            || isempty(HW.stereoTexOffset) ...
            || isempty(find(HW.stereoTexOffset ~= 0, 1)))
    % Only take control if we need to use per-pixel correction
    if strcmpi(screenFunc, 'OpenWindow') && HW.usePTBPerPxCorrection
        PsychImaging('PrepareConfiguration');
        PsychImaging('AddTask', 'FinalFormatting', ...
            'DisplayColorCorrection',...
            ...'SimpleGamma');
            'LookupTable');
        PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');
        PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');
        [HW.winPtr, HW.screenRect] = PsychImaging('OpenWindow', ...
                                      HW.screenNum, ...
                                      0, ... doesn't matter
                                      [], [], [], ...
                                      HW.stereoMode);
        %info = Screen('GetWindowInfo', HW.realWinPtr)
        table = LumToColor(HW, ((0:1023)./1023.0)'); % TODO 1023 hardcoded?
        table = table * 1/255; % HACK
        %PsychColorCorrection('SetEncodingGamma', HW.winPtr, 2.0);
        PsychColorCorrection('SetLookupTable', HW.winPtr, table); 
        Screen('BlendFunction', HW.winPtr, ...
                GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        varargout{1} = HW.winPtr;
        varargout{2} = HW.screenRect;
    else
        % FIXME autodetected size of varargout often ends up wrong; why??
        % Would like to write:
        %   varargout{:} = Screen(screenFunc, varargin{:})
        % Error recieved:
        %   Output argument "varargout{2}" (and maybe others)
        %   not assigned during call to "...ScreenCustomStereo".
        if nargout > 1
            varargout = cell(1, nargout-1);
            [varargout{:}] = Screen(screenFunc, varargin{:});
        else
            varargout = {};
            Screen(screenFunc, varargin{:});
        end
    end
    return % skip rest of function
end

% Stereo Draw Buffer IDs:
%   when interfacing with Screen, Screen uses 0 (left) or 1 (right)
%   but this code uses 1 and 2 wherever possible

if strcmpi(screenFunc, 'OpenWindow')
    % Create windows for left and right eyes, and hide "real" window ptr
    % (the offscreen windows are called "textures" in the code)
    % TODO don't color-correct per-pixel when ~HW.usePTBPerPxCorrection
%     [HW.realWinPtr,HW.realRect] = Screen('OpenWindow', HW.screenNum, ...
%                                   0, ... doesn't matter
%                                   [], [], [], ...
%                                   HW.stereoMode);
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection',...
        ...'SimpleGamma');
        'LookupTable');
    PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');
    PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');
    [HW.realWinPtr,HW.realRect] = PsychImaging('OpenWindow', ...
                                  HW.screenNum, ...
                                  0, ... doesn't matter
                                  [], [], [], ...
                                  HW.stereoMode);
    %info = Screen('GetWindowInfo', HW.realWinPtr)
    table = LumToColor(HW, ((0:1023)./1023.0)'); % TODO 1023 ok hardcoded?
    table = table * 1/255; % HACK
    %PsychColorCorrection('SetEncodingGamma', HW.realWinPtr, 2.0);
    PsychColorCorrection('SetLookupTable', HW.realWinPtr, table); 
    Screen('BlendFunction', HW.realWinPtr, ...
            GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    width = (HW.realRect(3)-HW.realRect(1));
    % Process parameters
    if ~isfield(HW, 'stereoTexWidth') || isempty(HW.stereoTexWidth)
        HW.stereoTexWidth = Inf; % full screen
    end
    assert(isscalar(HW.stereoTexWidth), 'SCS:BadParameter', ...
        'HW.stereoTexWidth must be a scalar.');
    assert(HW.stereoTexWidth >= 0, 'SCS:BadParameter',...
        'HW.stereoTexWidth should not be negative!');
    if all(HW.stereoTexWidth <= 1)
        HW.stereoTexWidth = width*HW.stereoTexWidth;
    elseif all(isInf(HW.stereoTexWidth))
        HW.stereoTexWidth = width;
    end
    if ~isfield(HW, 'stereoTexOffset') || isempty(HW.stereoTexOffset)
        if HW.stereoMode == 0
            HW.stereoTexOffset = [-1/4, 1/4];
        else
            HW.stereoTexOffset = [0,0];
        end
    end
    if all(abs(HW.stereoTexOffset) <= 1)
        HW.stereoTexOffset = width*HW.stereoTexOffset;
    end
    % Construct textures
    HW.texturePtrs = cell(1,2);
    HW.textureRects = cell(1,2); % actual texture sizes, just in case
    virtualTexRect = HW.realRect;
    virtualTexRect(3) = HW.stereoTexWidth;
    for textureIdx=[1,2]
        [HW.texturePtrs{textureIdx} HW.textureRects{textureIdx}] = ...
            Screen('OpenOffscreenWindow',HW.realWinPtr,[],virtualTexRect);
        %info = Screen('GetWindowInfo', HW.texturePtrs{textureIdx})
    end
    assert(~any(HW.textureRects{1} ~= HW.textureRects{2}), ...
        'SCS:Misallocation', ['Could not allocate same-sized offscreen'...
        ' windows!']);
    HW.currentStereoBuffer = ...
        1+Screen('SelectStereoDrawBuffer', HW.realWinPtr); % usu'ly invalid
    HW.winPtr = -1; % intentionally invalid; must select draw buffer first
    HW.screenRect = HW.textureRects{1};
    varargout = {HW.winPtr, HW.screenRect};
elseif strcmpi(screenFunc, 'BlendFunction')
    if (varargin{1} == HW.winPtr)
        varargout = cell(1,3);
        % apply this for both of the offscreen windows, not the main one
        for ptr = [HW.texturePtrs{:}]
            [varargout{:}] = Screen('BlendFunction', ptr, varargin{2:end});
        end
    else
        % Doesn't seem to be related to us
        varargout{:} = Screen(screenFunc, varargin{:});
    end
elseif strcmpi(screenFunc, 'MakeTexture')
    if (varargin{1} == HW.winPtr)
        varargout{:} = Screen('MakeTexture', HW.realWinPtr, ...
            varargin{2:end});
    else
        % Doesn't seem to be related to us
        varargout{:} = Screen(screenFunc, varargin{:});
    end
elseif strcmpi(screenFunc, 'SelectStereoDrawBuffer')
    % Original Screen specification:
    % currentbuffer =
    %   Screen('SelectStereoDrawBuffer', windowPtr[, bufferid][, param1]);
    if (varargin{1} == HW.winPtr)
        if (length(varargin) > 1) && ~isempty(varargin{2})
            desiredBufferIdx = varargin{2}+1; % convert
            %disp(['Selected buffer ' num2str(desiredBufferIdx)])
            if desiredBufferIdx ~= HW.currentStereoBuffer
                HW.currentStereoBuffer = desiredBufferIdx;
                HW.winPtr = HW.texturePtrs{HW.currentStereoBuffer};
            end
        end
        varargout = HW.currentStereoBuffer-1;
    else
        % Doesn't seem to be related to us
        varargout{:} = Screen(screenFunc, varargin{:});
    end
elseif strcmpi(screenFunc, 'DrawingFinished')
    % Simply ignored, since we still need to draw our offscreen windows
    varargout = 0;
    if isempty(alreadyWarnedDrawingFinished)
        warning('ScreenCustomStereo:DrawingFinished', ...
            ['DrawingFinished not implemented!'...
            ' Calling this will not improve performance.']);
        alreadyWarnedDrawingFinished = true;
    end
elseif strcmpi(screenFunc, 'Flip')
    if varargin{1} == HW.winPtr
        % Draw both offscreen windows, then flip the real window
        % clear irrelevant areas to black
        Screen('FillRect', HW.realWinPtr, 0);
        for textureIdx=[1,2]
            % FIXME w/ OpenGL stereo, glitches after right eye of 1st frame
%             disp(['Before copy ' num2str(textureIdx) ', left eye...'])
%             image(Screen('GetImage', HW.texturePtrs{1}));
%             pause
%             disp(['Before copy ' num2str(textureIdx) ', right eye...'])
%             image(Screen('GetImage', HW.texturePtrs{2}));
%             pause
            if HW.stereoMode > 0
                Screen('SelectStereoDrawBuffer', ...
                    HW.realWinPtr, textureIdx-1);
            end
            [intersect, srcRect, destRect] = CalcRects(HW, textureIdx);
            assert(intersect, 'ScreenCustomStereo:NoOverlap', ...
                'There is no room on the screen for the displays!')
            Screen('CopyWindow', ...
                HW.texturePtrs{textureIdx}, HW.realWinPtr, ...
                srcRect, destRect);
%             disp(['Copied ' num2str(HW.texturePtrs{textureIdx}) ...
%                 '(' num2str(srcRect) ')' ...
%                 ' to ' num2str(HW.realWinPtr) ...
%                 '(' num2str(destRect) ')'])
%             disp(['After copy ' num2str(textureIdx) ', left eye...'])
%             image(Screen('GetImage', HW.texturePtrs{1}));
%             pause
%             disp(['After copy ' num2str(textureIdx) ', right eye...'])
%             image(Screen('GetImage', HW.texturePtrs{2}));
%             pause
        end
%         disp('Pause before flip...')
%         pause
        %Screen('FillRect', HW.realWinPtr, 21.9, [0 0 200 300]);  %FIXME test
        varargout{:} = Screen('Flip', HW.realWinPtr, varargin{2:end});
        % DEBUG
%         for textureIdx=[1,2]
%             Screen('Close', HW.texturePtrs{textureIdx});
%             [HW.texturePtrs{textureIdx} HW.textureRects{textureIdx}] = ...
%                 Screen('OpenOffscreenWindow', HW.realWinPtr);
%             Screen('BlendFunction', HW.texturePtrs{textureIdx}, ...
%                    GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
%         end
    else
        % Doesn't seem to be related to us
        varargout{:} = Screen(screenFunc, varargin{:});
    end
elseif strcmpi(screenFunc, 'Close')
    % Delete both textures and close the real window
    if varargin{1} == HW.winPtr
        Screen('Close', HW.texturePtrs{1});
        Screen('Close', HW.texturePtrs{2});
        Screen('Close', HW.realWinPtr);
    end
else
    varargout{:} = Screen(screenFunc, varargin{:});
end

end

function [intersect, sourceRect, targRect] = CalcRects(HW, currentEye)
    % Finds the intersection between texture and screen and
    % returns the coordinates of that area in both the coords of the
    % texture (sourceRect) and the coords of the screen (targRect)
    offset = [HW.stereoTexOffset(currentEye) 0];
    targetBasis = HW.textureRects{currentEye};
    targetSize = targetBasis([3,4]) - targetBasis([1,2]);
    screenBasis = HW.realRect;
    targCenterInScreen = ...
        0.5 .* [ sum(screenBasis([1,3])) sum(screenBasis([2,4]))] + offset;
    targTopLeftInScreen = targCenterInScreen - 0.5*targetSize;
    targBotRightInScreen = targCenterInScreen + 0.5*targetSize;
    targInScreen = [targTopLeftInScreen, targBotRightInScreen];
    intersect = RectsIntersect(screenBasis, targInScreen);
    if intersect
        targRect = ...
            [max(screenBasis([1,2]), targInScreen([1,2])),...
             min(screenBasis([3,4]), targInScreen([3,4]))];
        sourceRect = targRect - targInScreen([1,2,1,2]);
    else
        targRect = [];
        sourceRect = [];
    end
%     FIXME Assumes same-sized source and destination
%     targRect = HW.screenRect;
%     sourceRect = HW.textureRects{currentEye};
%     %disp(sourceRect - [offset offset])
%     %disp(targRect + [offset offset])
%     sourceRect([1,3]) = max(sourceRect(1), min(sourceRect(3), ...
%         sourceRect([1,3]) - offset(1)));
%     sourceRect([2,4]) = max(sourceRect(2), min(sourceRect(4), ...
%         sourceRect([2,4]) - offset(2)));
%     targRect([1,3]) = max(targRect(1), min(targRect(3), ...
%         targRect([1,3]) + offset(1)));
%     targRect([2,4]) = max(targRect(2), min(targRect(4), ...
%         targRect([2,4]) + offset(2)));
end

function result = RectsIntersect(a, b)
    % rects do NOT intersect iff non-overlapping intervals in x or y axis
    result = ~(...
        (a(3) < b(1)) || ...
        (b(3) < a(1)) || ...
        (a(4) < b(2)) || ...
        (b(4) < a(2)) ...
        );
end
