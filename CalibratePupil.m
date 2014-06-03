function [ HW ] = CalibratePupil( HW, plexonServer )
%CALIBRATEPUPIL Summary of this function goes here
%   Detailed explanation goes here

LPT_Stimulus_Trigger = 4;
LPT_Stimulus_End = 1;

% Generic parameter structure that is used as a starting point for others
Pempty = struct();
Pempty.eyesToDraw = [0 1];
Pempty.outerRadiusDeg = 0;
Pempty.innerRadiusDeg = 0;
Pempty.bgLuminance = 0.1;
Pempty.stimLuminance = Pempty.bgLuminance; % just to be sure
Pempty.fixWidthDeg = 0.5;
Pempty.fixLineWidthPx = 3;

% Nothing-but-fixation screen parameters
Pfix = Pempty;
Pfix.fixColor = HW.white * 0.5;

% Bright screen for pupil calibration
PbrightCalib = Pempty;
PbrightCalib.bgLuminance = 227.6/227.6;
PbrightCalib.fixColor = HW.white * 0.5;

% Dark screen for pupil calibration
PdarkCalib = Pempty;
PdarkCalib.bgLuminance = 0;
PdarkCalib.fixColor = HW.white * 0.03;

% Data file:
%  Object measured (see below)
%  Brightness of display (-1 if not applicable)
%  Size measured
%  Plexon trigger time for synchro (-1 if not applicable)
% Objects to measure:
%   1: Limbus-to-limbus distance, i.e. corneal diameter (actual)
%   2: Bright stimulus, limbus on Eyelink screen
%   3: Bright stimulus, pupil on Eyelink screen
%   4: Dark stimulus, limbus on Eyelink screen
%   5: Dark stimulus, pupil on Eyelink screen
dataColumns = {'ObjectMeasured', 'Brightness', 'sizeMeasured', 'PlexonTimestamp'};
sessionName = input('Session name - pupil calibration (Subjectcode+experimentInitial):', 's');
datafile = DataFile(DataFile.defaultPath(sessionName), dataColumns);

realLimbDiam = input('1) Enter subject''s actual limbus diameter (mm)...');
datafile.append([1, -1, realLimbDiam, -1]);

% Draw fixation screen and Wait for subject to be ready
HW = DrawAnnulus(HW, Pfix);

fprintf('Ensure subject is viewing screen properly,\n');
[~] = input('then start Plexon data collection and press Enter...','s');

PL_GetTS(plexonServer); % Erase previous timestamps

% Display bright stimulus
HW = DrawAnnulus(HW, PbrightCalib);
[~] = input('Displaying bright stimulus; press Enter when steady measurements have been taken...', 's');
LPTTrigger(LPT_Stimulus_Trigger);
pause(0.1);
[~,triggerTS,~,~] = GetEventsPlexon(plexonServer); % read plexon's timestamp value
limDiamBright = input('2) Enter subject''s on-screen limbus diameter (mm)...');
datafile.append([2, PbrightCalib.bgLuminance, limDiamBright, triggerTS]);
pupDiamBright = input('3) Enter subject''s on-screen pupil diameter (mm)...');
datafile.append([3, PbrightCalib.bgLuminance, pupDiamBright, triggerTS]);

% Display dark stimulus
HW = DrawAnnulus(HW, PdarkCalib);
[~] = input('Displaying dark stimulus; press Enter when steady measurements have been taken...', 's');
LPTTrigger(LPT_Stimulus_Trigger);
pause(0.1);
[~,triggerTS,~,~] = GetEventsPlexon(plexonServer);
limDiamDark = input('4) Enter subject''s on-screen limbus diameter (mm)...');
datafile.append([4, PdarkCalib.bgLuminance, limDiamDark, triggerTS]);
pupDiamDark = input('5) Enter subject''s on-screen pupil diameter (mm)...');
datafile.append([5, PdarkCalib.bgLuminance, pupDiamDark, triggerTS]);

% Reset plexon state
LPTTrigger(LPT_Stimulus_End);
PL_GetTS(plexonServer); % erase existing timestamps

[~] = input('Stop Plexon data collection and press Enter...','s');

end

