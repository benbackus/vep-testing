function [ colors, actualLums, HW ] = LumToColor( HW, lums )
%LUMTOCOLOR Converts desired luminances to colors near (not purely) grey
%   Employs "bit-stealing"
%   HW: Hardware parameter structure; requires:
%       HW.lumChannelContrib
%       HW.lumCalib
%       HACK May contain data cached from a previous call to this function!
%           If HW.lumCalib changes, delete the following variables:
%               HW.lumToRawPP, HW.rawToLumPP
%           If HW.lumChannelContrib changes, delete:
%               HW.stealPP, HW.nearestLumPP
%   lums: Luminances desired, as column vector (grayscale only), max = 1.0
%
%   Output:
%       colors - values for display
%       actualLums - actual luminances for display, as column vector
%       HW - Hardware parameter structure with data cached (optional)
%{
    Test code, assumes gamma=2:
    HW.lumChannelContrib = [.2 .3 .1]; % [R, G, B] contribution to total
    HW.lumCalib = [0:10:250, 255]';
    HW.lumCalib = [HW.lumCalib (HW.lumCalib ./ 255).^2 ];
    HW.white = 255;
    [colors, actualLums, HW] = LumToColor(HW, (0.5:0.001:0.55)');
    colors
    actualLums
%}
    
    % cache piecewise polys (ppform; see ppval) for faster evaluation
    if ~exist('HW', 'var') || ~isfield(HW, 'stealPP') ...
            || isempty(HW.stealPP)
        
        [HW.stealPP HW.finalStepSizePP] = BuildBitStealTable(HW);
    end
    
    if ~exist('HW', 'var') || ~isfield(HW, 'lumToRawPP') ...
            || isempty(HW.lumToRawPP)
        
        HW.lumToRawPP = ...
            interp1(HW.lumCalib(:,2), HW.lumCalib(:,1), 'spline', 'pp');
        %plot(ppval(HW.lumToRawPP, 0:0.01:1));
        %TODO investigate using splines (spaps) or polyfit with log'thms
    end
    
    if ~exist('HW', 'var') || ~isfield(HW, 'rawToLumPP') ...
            || isempty(HW.rawToLumPP)
        
        HW.rawToLumPP = ...
            interp1(HW.lumCalib(:,1), HW.lumCalib(:,2), 'spline', 'pp');
        %plot(ppval(HW.rawToLumPP, 0:255));
    end
    
    % Get nearest raw "voltage" below luminance desired
    desiredRaws = ppval(HW.lumToRawPP, lums);
    flooredRaw = floor(desiredRaws);
    
    % Luminance range to work with
    flooredLums = ppval(HW.rawToLumPP, flooredRaw);
    ceilLums = ppval(HW.rawToLumPP, flooredRaw+1);
    
    % Steal bits from color channels to get closer to luminance
    stealStep = (lums - flooredLums) ./ (ceilLums - flooredLums);
    stealCols = ppval(HW.stealPP, stealStep);
    
    if isscalar(stealStep)
        stealCols = stealCols';
    end
    colors = [flooredRaw, flooredRaw, flooredRaw] + stealCols;
    
    colors = min(HW.white, max(0, colors)); % clamp to sane values
    
    actualLums = flooredLums + ...
        ppval(HW.finalStepSizePP, stealStep).*(ceilLums - flooredLums);
end

function [ stealPP, finalStepSizePP ] = BuildBitStealTable(HW)
% BUILDTABLE Builds piecewise polynomials describing steal bits to use
%   Actually, the "polynomials" are just nearest neighbor table lookups
    
    combos = size(6,1)^3;
    x = size(combos); % luminance increases, as proportion of L(v+1)-L(v)
    Y = zeros(combos,3); % voltage steps needed
    idx = 1;
    for i = 0:2 % red steps to explore
        for j = 0:1 % green steps to explore
            for k = 0:1 % blue steps to explore
                x(idx) = dot([i,j,k], HW.lumChannelContrib);
                Y(idx,:) = [i,j,k];
                idx = idx+1;
            end
        end
    end
    
    % Only consider values between this "voltage" step and the next
    valid = (x > 0) & (x < 1);
    x = x(valid);
    Y = Y(valid, :);
    
    % Filter duplicates (since interp1 can't handle them)
    % FIXME may bias which color channel gets boosted...?
    [x, uniqueIdxs] = unique(x);
    Y = Y(uniqueIdxs, :);
    
    stealPP = interp1(x, Y, 'nearest', 'pp');
    finalStepSizePP = interp1(x, x, 'nearest', 'pp');
end
