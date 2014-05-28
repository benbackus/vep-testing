function [ HW ] = HardwareParameters()
%HARDWAREPARAMETERS Load hardware information into a structure.
%   These include: user interface, OpenGL, and OS & MATLAB environment, etc
%   See inline comments for details.
%   HW: Hardware parameter structure

    % Projector ('1424'), plasma ('1424plasma'), or stereoscope
    % ('1402chatnoir'), etc.
    HW.room = '1419';
    HW.screenNum = 2; % see Screen('Screens?')
    
    % HW.monWidth: width of entire viewable screen (cm)
    %   (Will later be multiplied by the fraction used, if stereoscope)
    % HW.viewDist: viewing distance (cm)
    knownRoom = false;
    switch lower(HW.room)
        case '1419'
            switch HW.screenNum
                case 1 % Control screen
                    HW.useStereoscope = true;
                case 2 % Experiment monitor
                    HW.monWidth = 38.5;
                    HW.viewDist = 68.5;
                    HW.useStereoscope = true;
                    knownRoom = true;
            end
        case '1424'
            switch HW.screenNum
                case 1 % Projector
                    HW.monWidth	= 239.6;
                    HW.viewDist	= 150;
                    HW.useStereoscope = false;
                    knownRoom = true;
                case 2 % CRT (dev/console) screen
                    HW.monWidth = 39;
                    HW.viewDist	= 60;
                    HW.useStereoscope = false;
                    knownRoom = true;
            end
        case '1424plasma'
            switch HW.screenNum
                case 1 % Dev screen
                    HW.monWidth = 50;
                    HW.viewDist	= 60;
                    HW.useStereoscope = true;
                    knownRoom = true;
                case 2 % Plasma screen
                    HW.monWidth	= 91.4; % FIXME approx?
                    HW.viewDist	= 145; % FIXME approx
                    HW.useStereoscope = true;
                    knownRoom = true;
            end
        case '1414'
            switch HW.screenNum
                case 1 % CRT screen - for some reason reverse of Windows
                    HW.monWidth	= 49.5; % FIXME approx?
                    HW.viewDist	= 90; % FIXME approx
                    HW.useStereoscope = true;
                    knownRoom = true;
                case 2 % Dev screen
                    HW.monWidth = 30;
                    HW.viewDist	= 70;
                    HW.useStereoscope = true;
                    knownRoom = true;
            end
        case '1402'
            switch HW.screenNum
                case 1 % Alienware 2310 (production) 120Hz LCD display
                    HW.monWidth = 51;
                    HW.viewDist = 110;
                    HW.useStereoscope = true;
                    knownRoom = true;
                case 2 % hp 1530 (development/console) LCD display
                    HW.monWidth = 30;
                    HW.viewDist = 75;
                    HW.useStereoscope = false;
                    knownRoom = true;
            end
        case '1402chatnoir'
            HW.monWidth = 51;
            HW.viewDist = 110;
            HW.useStereoscope = true;
            knownRoom = true;
        case 'benoffice'
            switch HW.screenNum
                case 1 % Dev screen
                    HW.monWidth = 50;
                    HW.viewDist	= 60;
                    HW.useStereoscope = true;
                    knownRoom = true;
                case 2 % Display screen
                    HW.monWidth	= 91.4; % FIXME approx?
                    HW.viewDist	= 145; % FIXME approx
                    HW.useStereoscope = true;
                    knownRoom = true;
            end
    end
    if ~knownRoom
        warning('Parameters:BadDefault', ...
            ['Unknown room / monitor - '...
            ' Using default monitor width and distance!']);
        HW.monWidth = 50;
        HW.viewDist = 100;
        HW.useStereoscope = true;
    end
    
    % HW.stereoMode: see Screen('OpenWindow?'), 1 = OpenGL stereo
    % HW.stereoTexWidth and HW.stereoTexOffset:
    %   Horizontal distances, as proportion of screen (|x|<1) or in pixels
    %   See ScreenCustomStereo
    if HW.useStereoscope
        % Uses ScreenCustomStereo
        HW.stereoMode = 0;
        HW.stereoTexWidth = 7.75/16.0; % This is for the projector room scope
        HW.stereoTexOffset = [-4.125/16.0, 4.125/16.0];
        HW.monWidth = HW.monWidth * HW.stereoTexWidth;
    else
        HW.stereoMode = 1;
        % Disable custom stereo with special parameter values
        HW.stereoTexOffset = [];
        HW.stereoTexWidth = 1.0;
    end
    
    HW.initPause = 0.5;	% pause length (in s) after initialization
    
    % Color calibration
    
    % HW.lumChannelContrib
    %	Est. [R, G, B] contribution to total luminance for grayscale steps
    %	(calibrations used for bit-stealing)
    %   Blue pixel contribs are often very uncertain (consistant w/ 0) :(
    % HW.lumCalib:
    %   Two-column table [raw, luminance]
    %   Will normalize max luminance to 1 at end of switch block
    switch lower(HW.room)
        case '1424'
            HW.lumCalib = importdata('media/lumCalib 1424 2012-07-21.mat');
            HW.lumChannelContrib = [.2456 .7293 .0251];
        case '1402'
            HW.lumCalib = importdata('media/lumCalib 1402 2012-07-21.mat');
            HW.lumChannelContrib = [.1616 .7739 .0645];
        case '1402chatnoir'
            HW.lumCalib = ...
                importdata('media/lumCalib 1402chatnoir 2012-10-24.mat');
            HW.lumChannelContrib = [.2846 .5949 .1204];
        case '1419'
            HW.lumCalib = ...
                importdata('media/lumCalib 1419 2014-05-27.mat');
            HW.lumChannelContrib = [0.185506 0.743230 0.071263];
        otherwise
            warning('Parameters:NoColorCalib', ...
                'No default color calibration data! Loading gamma = 2.0');
            testLums = [0:10:250, 255]';
            testVolts = (testLums ./ 255).^2;
            HW.lumCalib = [testLums, testVolts];
            HW.lumChannelContrib = [.2 .7 .1];
    end
    HW.lumCalib(:,2) = HW.lumCalib(:,2) / max(HW.lumCalib(:,2));
    
    % Use PsychImaging(..., 'DisplayColorCorrection', 'LookupTable')?
    % TODO when using stereoscope, this value is currently ignored
    HW.usePTBPerPxCorrection = true;
    
    % User interface keys
    % TODO use KbName('UnifyKeyNames');
    if IsWin
        %{
        HW.upKey	= 'up';
        HW.downKey	= 'down';
        %}
        HW.upKey	= '8';
        HW.downKey	= '2';
        HW.leftKey	= '4';
        HW.rightKey	= '6';
        HW.haltKey	= 'x';
    elseif IsOSX
        HW.upKey = 'UpArrow';
        HW.downKey = 'DownArrow';
        HW.leftKey = 'LeftArrow'; % FIXME check whether l/r are right
        HW.rightKey = 'RightArrow';
        HW.haltKey = 'x';
    end
    HW.validKeys = {HW.upKey HW.downKey HW.leftKey HW.rightKey HW.haltKey};
    
    % Feedback sounds:
    % sounds for right and wrong answers (may be the same sound)
    HW.rightSound = importdata('media/Windows Balloon (Quirky) 3.wav');
    HW.wrongSound = ...
        importdata('media/Windows Critical Stop (Quirky) 2.wav');
    % sound for bad response, ex. hit an invalid key
    HW.failSound = importdata('media/Windows Hardware Fail.wav');
    
    % Store random number generator
    HW.randSeed = now();
    HW.randStream = RandStream('mt19937ar', 'Seed', HW.randSeed);
    
    % Default window position and size for MATLAB plots and figures
    HW.defaultFigureRect = [50 100 1024-100 768-200];
    
    HW.initialized = false; % not yet initialized
end
