function scr_init
% SCR_INIT initializes SCR by determining the path and loading settings
% into the main workspace
%__________________________________________________________________________
% PsPM 3.0
% (C) 2009-2015 Dominik R Bach (WTCN, UZH)

% $Id$
% $Rev$

clc

% License & user output
% -------------------------------------------------------------------------
fid = fopen('scr_msg.txt');
msg = textscan(fid, '%s', 'Delimiter', '$');
fclose(fid);
clear fid
for n = 1:numel(msg{1})
    fprintf('%s\n', msg{1}{n});
end;

fprintf('PsPM: loading defaults ... \n');


% check various settings
% -------------------------------------------------------------------------
global settings
p=path;
fs = filesep;

% check if subfolders are already in path
% -------------------------------------------------------------------------
% get subfolders
current_path = fileparts(mfilename('fullpath'));
folder_content = dir(current_path);
is_folder = [folder_content(:).isdir];
subfolders = {folder_content(is_folder).name}';
subfolders(ismember(subfolders, {'.','..'})) = [];

subfolders = regexprep(subfolders, '(.*)', ...
    [regexptranslate('escape', [current_path, filesep]) , '$1']);

sp = textscan(path,'%s','delimiter',pathsep);
mem = ~ismember(subfolders, sp{1});
if numel(subfolders(mem)) == 0
    % loaded subdirs which may cause trouble
    warning(['All subdirectories of the main directory are loaded into the ', ...
        'MATLAB search path. This is not necessary and may even cause ', ...
        'trouble during runtime. It is recommended to only add the path of', ...
        ' the main directory to the search path.']);
end

% -------------------------------------------------------------------------

% check Matlab version
v=version;verr=0;
if str2num(v(1:3))<7.1
    verr=1;
    errmsg=sprintf('You are running PsPM on a Matlab version (%s) under which it has not been tested.\nSPM 8 functions will be automatically added to you path but may not run. 1st level GLM may not run.\nIf you encounter any other error, please contact the developers.', v);
    warning(errmsg);
elseif str2num(v(1:3)) >= 8.4
    errmsg=sprintf('You are using Matlab version 2014b or later. Review display of non-linear models using VBA may not work.');
    warning(errmsg);
end

% check toolbox functions
signal = license('checkout','signal_toolbox');
if ~signal
    errmsg='Signal processing toolbox not installed. Some filters might not be implemented.';
    warning(errmsg);
end;

% check whether scralyze is on the path
pth = fileparts(which('pspm'));
if isempty(strfind(p, pth))
    scrpath=1;
    addpath(pth);
else
    scrpath=0;
end;
pth = [pth, fs];

% check whether SPM 8 is already on path
dummy=which('spm');
if ~isempty (dummy)
    try
        if strcmpi(spm('Ver'), 'spm8b')||strcmpi(spm('Ver'), 'spm8')
            addspm=0;
        else
            addspm=1;
        end;
    catch
        addspm=1;
    end;
else
    addspm=1;
end;
if addspm
    addpath([pth, fs, 'SPM']);
    spmpath=1;
else
    spmpath=0;
end;

% check whether matlabbatch is already on path
dummy=which('cfg_ui');
if isempty (dummy)
    addpath([pth, fs, 'matlabbatch']);
    matlabbatchpath=1;
else
    if ~isempty(strfind(dummy, 'spm8\matlabbatch\cfg_ui.m'))
        if strcmp(questdlg(sprintf(['Matlabbatch from SPM and its config folder are currently on your MATLAB search path.\n\n' ...
                'Do you want to remove these folders temporarily from your MATLAB search path in order to avoid potentioal ' ...
                'issues with matlabbatch from PsPM?']), ...
                'Matlabbatch', ...
                'Yes', 'No', 'No'), 'Yes')
            [matlabbatch_dir,~,~] = fileparts(dummy);
            rmpath(matlabbatch_dir);
            dummy=which('spm_cfg');
            if ~isempty (dummy)
                [config_dir,~,~] = fileparts(dummy);
                rmpath(config_dir);
            end
            addpath([pth, fs, 'matlabbatch']);
            matlabbatchpath=1;
        else
            matlabbatchpath=0;
        end
    else
        matlabbatchpath=0;
    end
end;

% check whether scr_cfg is already on path
dummy=which('scr_cfg');
if isempty (dummy)
    addpath([pth, fs, 'scr_cfg']);
    scrcfgpath=1;
else
    scrcfgpath=0;
end

% add VBA because this is used in various functions
addpath([pth, 'VBA']);
addpath([pth, 'VBA', fs, 'subfunctions']);
addpath([pth, 'VBA', fs, 'stats&plots']);


% -------------------------------------------------------------------------
%  allowed channel types
% -------------------------------------------------------------------------
% DEVELOPERS NOTES: in order to implement new channel types
% to defaults.import.channeltypes. If direct import is allowed, create the
% associated scr_get_xxx import function. See first channel type (SCR) for
% explanations.
% ------------------------------------------------------------------------
% These are the allowed chantypes in a data file (checked by scr_load_data)
defaults.chantypes(1) = ...
    struct('type', 'scr', ...        % short name for internal purposes
    'description', 'SCR', ...    % for display purposes
    'import', @scr_get_scr, ...  % import function
    'data', 'wave');             % data type

defaults.chantypes(2) = ...
    struct('type', 'ecg', ...
    'description', 'ECG', ...
    'import', @scr_get_ecg, ...
    'data', 'wave');

defaults.chantypes(3) = ...
    struct('type', 'hr', ...
    'description', 'Heart rate', ...
    'import', @scr_get_hr, ...
    'data', 'wave');

defaults.chantypes(4) = ...
    struct('type', 'hp', ...
    'description', 'Heart period', ...
    'import', @scr_get_hp, ...
    'data', 'wave');

defaults.chantypes(5) = ...
    struct('type', 'hb', ...
    'description', 'Heart beat', ...
    'import', @scr_get_hb, ...
    'data', 'events');

defaults.chantypes(6) = ...
    struct('type', 'resp', ...
    'description', 'Respiration', ...
    'import', @scr_get_resp, ...
    'data', 'wave');

defaults.chantypes(7) = ...
    struct('type', 'rr', ...
    'description', 'Respiration rate', ...
    'import', @none, ...
    'data', 'wave');

defaults.chantypes(8) = ...
    struct('type', 'rp', ...
    'description', 'Respiration period', ...
    'import', @none, ...
    'data', 'wave');

defaults.chantypes(9) = ...
    struct('type', 'ra', ...
    'description', 'Respiration amplitude', ...
    'import', @none, ...
    'data', 'wave');

defaults.chantypes(10) = ...
    struct('type', 'RLL', ...
    'description', 'Respiration line length', ...
    'import', @none, ...
    'data', 'wave');

defaults.chantypes(11) = ...
    struct('type', 'rs', ...
    'description', 'Respiration time stamp', ...
    'import', @none, ...
    'data', 'events');

defaults.chantypes(12) = ...
    struct('type', 'pupil', ...
    'description', 'Pupil size', ...
    'import', @scr_get_pupil, ...
    'data', 'wave');

defaults.chantypes(13) = ...
    struct('type', 'emg', ...
    'description', 'EMG', ...
    'import', @scr_get_emg, ...
    'data', 'wave');

defaults.chantypes(14) = ...
    struct('type', 'emg_proc', ...
    'description', 'EMG preprocessed', ...
    'import', @none, ...
    'data', 'wave');

defaults.chantypes(15) = ...
    struct('type', 'custom', ...
    'description', 'Custom', ...
    'import', @scr_get_custom, ...
    'data', 'wave');

defaults.chantypes(16) = ...
    struct('type', 'marker', ...
    'description', 'Marker', ...
    'import', @scr_get_marker, ...
    'data', 'events');

defaults.chantypes(17) = ...
    struct('type', 'snd', ...
    'description', 'Sound channel', ...
    'import', @scr_get_sound, ...
    'data', 'wave');

defaults.chantypes(18) = ...
    struct('type', 'ppu', ...
    'description', 'Pulse oxymeter', ...
    'import', @none, ...
    'data', 'wave');

defaults.chantypes(19) = ...
    struct('type', 'gaze_x_l', ...
    'description', 'Gaze x left', ...
    'import', @scr_get_gaze_x_l, ...
    'data', 'wave');

defaults.chantypes(20) = ...
    struct('type', 'gaze_y_l', ...
    'description', 'Gaze y left', ...
    'import', @scr_get_gaze_y_l, ...
    'data', 'wave');

defaults.chantypes(21) = ...
    struct('type', 'gaze_x_r', ...
    'description', 'Gaze x right', ...
    'import', @scr_get_gaze_x_r, ...
    'data', 'wave');

defaults.chantypes(22) = ...
    struct('type', 'gaze_y_r', ...
    'description', 'Gaze y right', ...
    'import', @scr_get_gaze_y_r, ...
    'data', 'wave');

defaults.chantypes(23) = ...
    struct('type', 'pupil_r', ...
    'description', 'Pupil right', ...
    'import', @scr_get_pupil_r, ...
    'data', 'wave');

defaults.chantypes(24) = ...
    struct('type', 'pupil_l', ...
    'description', 'Pupil left', ...
    'import', @scr_get_pupil_l, ...
    'data', 'wave');

defaults.chantypes(25) = ...
    struct('type', 'blink_r', ...
    'description', 'Blink right', ...
    'import', @scr_get_blink_r, ...
    'data', 'wave');

defaults.chantypes(26) = ...
    struct('type', 'blink_l', ...
    'description', 'Blink left', ...
    'import', @scr_get_blink_l, ...
    'data', 'wave');

defaults.chantypes(27) = ...
    struct('type', 'pupil_missing_l', ...
    'description', 'Pupil data missing/interpolated left', ...
    'import', @none, ...
    'data', 'wave');

defaults.chantypes(28) = ...
    struct('type', 'pupil_missing_r', ...
    'description', 'Pupil data missing/interpolated right', ...
    'import', @none, ...
    'data', 'wave');


for k = 1:numel(defaults.chantypes)
    if strcmpi(func2str(defaults.chantypes(k).import), 'none')
        indx(k) = 0;
    else
        indx(k) = 1;
    end;
end;
    
defaults.importchantypes = defaults.chantypes(indx==1);

% -------------------------------------------------------------------------
%  general import settings
% -------------------------------------------------------------------------
% DEVELOPERS NOTES: in order to implement new datatype import, add a field
% to defaults.import.datatypes and create the associated scr_get_xxx
% function. See first datatype (CED spike) for explanations.
% -------------------------------------------------------------------------

% Cambridge Electronic Design (CED) Spike files
% ---------------------------------------------
defaults.import.datatypes(1) = ...
    struct('short', 'spike', ...  % short name for internal purposes
    'long', 'CED Spike (.smr)', ...      % long name for GUI
    'ext', 'smr', ...             % data file extension
    'funct', @scr_get_spike, ...  % import function
    'chantypes', {{defaults.importchantypes.type}}, ...  % allowed channel types
    'chandescription', 'channel', ... % description of channels for GUI
    'multioption', 1, ...         % allow import of multiple channels for GUI
    'searchoption', 1, ...        % allow channel name search for GUI
    'automarker', 0, ...          % marker not stored in separate channel
    'autosr', 1, ...              % sample rate automatically assigned
    'help', '');                  % helptext from structure gui

% Matlab files
% ------------
defaults.import.datatypes(2) = ...
    struct('short', 'mat', ...
    'long', 'Matlab', ...
    'ext', 'mat', ...
    'funct', @scr_get_mat, ...
    'chantypes', {{defaults.importchantypes.type}}, ...
    'chandescription', 'cell/column', ...
    'multioption', 1, ...
    'searchoption', 0, ...
    'automarker', 0, ...
    'autosr', 0, ...
    'help', ['Each input file must contain a variable called data that ', ...
    'is either a cell array of column vectors, or a ', ...
    'data points ? channels matrix. At the moment, no import of event ', ...
    'markers is possible. Data structures containing timestamps cannot be ', ...
    'imported at the moment; rather, PsPM will ask you for a sample rate.']);

% Text files
% ----------
defaults.import.datatypes(3) = ...
    struct('short', 'txt', ...
    'long', 'Text', ...
    'ext', 'txt', ...
    'funct', @scr_get_txt, ...
    'chantypes', {{defaults.importchantypes(strcmpi('wave',{defaults.importchantypes.data})).type}}, ...  %all wave channels
    'chandescription', 'column', ...
    'multioption', 1, ...
    'searchoption', 1, ...
    'automarker', 0, ...
    'autosr', 0, ...
    'help', ['Text files can only contain numbers ', ...
    '(i.e. no header lines with channel names) and one data column per ', ...
    'channel. Make sure you use the decimal point (i.e. not decimal ', ...
    'comma as used in some non-English speaking countries). At the moment, ', ...
    'no import of event markers is possible']);

% Biopac Acknowledge up to version 3.9.0
% --------------------------------------
defaults.import.datatypes(4) = ...
    struct('short', 'acq', ...
    'long', 'Biopac Acqknowledge 3.9.0 or lower (.acq)', ...
    'ext', 'acq', ...
    'funct', @scr_get_acq, ...
    'chantypes', {{defaults.importchantypes.type}}, ...
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 1, ...
    'automarker', 0, ...
    'autosr', 1, ...
    'help', '');

% exported Biopac Acqknowledge (tested on version 4.2.0)
% -----------------------------------------------------
defaults.import.datatypes(5) = ...
    struct('short', 'acqmat', ...
    'long', 'matlab-exported Biopac Acqknowledge 4.0 or higher', ...
    'ext', 'mat', ...
    'funct', @scr_get_acqmat, ...
    'chantypes', {{defaults.importchantypes.type}}, ...
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 1, ...
    'automarker', 0, ...
    'autosr', 1, ...
    'help', '');

% exported ADInstruments Labchart up to 7.1
% -----------------------------------------------------
defaults.import.datatypes(6) = ...
    struct('short', 'labchartmat_ext', ...
    'long', 'matlab-exported ADInstruments LabChart 7.1 or lower', ...
    'ext', 'mat', ...
    'funct', @scr_get_labchartmat_ext, ...
    'chantypes', {{defaults.importchantypes(~strcmpi('hb',{defaults.importchantypes.type})).type}}, ...  %all except hb
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 1, ...
    'automarker', 1, ...
    'autosr', 1, ...
    'help', ['Export data to matlab format (plugin for the LabChart ', ...
    'software, available from www.adinstruments.com)']);

% exported ADInstruments Labchart 7.2 or higher
% -----------------------------------------------------
defaults.import.datatypes(7) = ...
    struct('short', 'labchartmat_in', ...
    'long', 'matlab-exported ADInstruments LabChart 7.2 or higher', ...
    'ext', 'mat', ...
    'funct', @scr_get_labchartmat_in, ...
    'chantypes', {{defaults.importchantypes(~strcmpi('hb',{defaults.importchantypes.type})).type}}, ...
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 0, ...
    'automarker', 1, ...
    'autosr', 1, ...
    'help', '');

% VarioPort
% -----------------------------------------------------
defaults.import.datatypes(8) = ...
    struct('short', 'vario', ...
    'long', 'VarioPort (.vdp)', ...
    'ext', 'vpd', ...
    'funct', @scr_get_vario, ...
    'chantypes', {{defaults.importchantypes(~strcmpi('hb',{defaults.importchantypes.type})).type}}, ...
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 1, ...
    'automarker', 1, ...
    'autosr', 1, ...
    'help', '');

% exported Biograph Infiniti
% -----------------------------------------------------
defaults.import.datatypes(9) = ...
    struct('short', 'biograph', ...
    'long', 'text-exported Biograph Infiniti', ...
    'ext', 'txt', ...
    'funct', @scr_get_biograph, ...
    'chantypes', {{'scr', 'hb', 'resp'}}, ...
    'chandescription', 'channel', ...
    'multioption', 0, ...
    'searchoption', 0, ...
    'automarker', 0, ...
    'autosr', 1, ...
    'help', ['Export data to text format, both "Export Channel Data" and ', ...
    '"Export Interval Data" are supported; a header is required']);

% exported MindMedia Biotrace
% -----------------------------------------------------
defaults.import.datatypes(10) = ...
    struct('short', 'biotrace', ...
    'long', 'text-exported MindMedia Biotrace', ...
    'ext', 'txt', ...
    'funct', @scr_get_biotrace, ...
    'chantypes', {{defaults.importchantypes(~strcmpi('hb',{defaults.importchantypes.type})).type}}, ...
    'chandescription', 'channel', ...
    'multioption', 0, ...
    'searchoption', 0, ...
    'automarker', 1, ...
    'autosr', 1, ...
    'help', '');

% Brain Vision
% -----------------------------------------------------
defaults.import.datatypes(11) = ...
    struct('short', 'brainvision', ...
    'long', 'BrainVision (.eeg)', ...
    'ext', 'eeg', ...
    'funct', @scr_get_brainvis, ...
    'chantypes', {{defaults.chantypes(~strcmpi('hb',{defaults.chantypes.type})).type}}, ...
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 1, ...
    'automarker', 1, ...
    'autosr', 1, ...
    'help', '');

% Dataq Windaq (e. g. provided by Coulbourn Instruments)
% -----------------------------------------------------
defaults.import.datatypes(12) = ...
    struct('short', 'windaq', ...
    'long', 'DATAQ Windaq (.wdq) (read with ActiveX-Lib)', ...
    'ext', 'wdq', ...
    'funct', @scr_get_wdq, ...
    'chantypes', {{defaults.importchantypes.type}}, ...
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 0, ...
    'automarker', 0, ...
    'autosr', 1, ...
    'help', ['Requires an ActiveX Plugin provided by the manufacturer ', ...
    'and contained in the subfolder Import/wdq for your convenience. ', ...
    'This plugin only runs under 32 bit Matlab on Windows. ']);

% Dataq Windaq (PsPM Version)
% -----------------------------------------------------
defaults.import.datatypes(13) = ...
    struct('short', 'windaq_n', ...
    'long', 'DATAQ Windaq (.wdq)', ...
    'ext', 'wdq', ...
    'funct', @scr_get_wdq_n, ...
    'chantypes', {{defaults.importchantypes.type}}, ...
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 0, ...
    'automarker', 0, ...
    'autosr', 1, ...
    'help', ['Windaq import written by the PsPM team. It is platform ', ...
    'independent, thus has no requirements for ActiveX Plugins, Windows ', ...
    'or 32bit Matlab. Imports the original acquisition files files. ', ...
    'Up to now the import has been tested with files of the following ', ...
    'type: Unpacked, no Hi-Res data, no Multiplexer files. ', ...
    'A warning will be produced if the imported data-type fits one of the ', ...
    'yet untested cases. If this is the case try to use the import provided ', ...
    'by the manufacturer (see above).']);

% Noldus Observer XT compatible .txt files
% -----------------------------------------------------
defaults.import.datatypes(14) = ...
    struct('short', 'observer', ...
    'long', 'Noldus Observer XT compatible text file', ...
    'ext', 'any', ...
    'funct', @scr_get_obs, ...
    'chantypes', {{defaults.importchantypes.type}}, ...
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 1, ...
    'automarker', 0, ...
    'autosr', 1, ...
    'help', '');

% NeuroScan
% -----------------------------------------------------
defaults.import.datatypes(15) = ...
    struct('short', 'cnt', ...
    'long', 'Neuroscan (.cnt)', ...
    'ext', 'cnt', ...
    'funct', @scr_get_cnt, ...
    'chantypes', {{defaults.importchantypes(~strcmpi('hb',{defaults.importchantypes.type})).type}}, ...
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 1, ...
    'automarker', 1, ...
    'autosr', 1, ...
    'help', '');

% BioSemi
% -----------------------------------------------------
defaults.import.datatypes(16) = ...
    struct('short', 'biosemi', ...
    'long', 'BioSemi (.bdf)', ...
    'ext', 'bdf', ...
    'funct', @scr_get_biosemi, ...
    'chantypes', {{defaults.importchantypes(~strcmpi('hb',{defaults.importchantypes.type})).type}}, ...
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 1, ...
    'automarker', 1, ...
    'autosr', 1, ...
    'help', '');

% Eyelink 1000 files
% ---------------------------------------------
defaults.import.datatypes(17) = ...
    struct('short', 'eyelink', ...
    'long', 'Eyelink 1000', ...
    'ext', 'asc', ...
    'funct', @scr_get_eyelink, ...
    'chantypes', {{'pupil_l','pupil_r', 'gaze_x_l', 'gaze_y_l', ...
        'gaze_x_r', 'gaze_y_r', 'blink_l', 'blink_r', 'marker', 'custom'}}, ...
    'chandescription', 'data column', ...
    'multioption', 1, ...
    'searchoption', 0, ...
    'automarker', 1, ...
    'autosr', 1, ...
    'help', '');

% European Data Format (EDF)
% -----------------------------------------------------
defaults.import.datatypes(18) = ...
    struct('short', 'edf', ...
    'long', 'European Data Format (.edf)', ...
    'ext', 'edf', ...
    'funct', @scr_get_edf, ...
    'chantypes', {{defaults.importchantypes.type}}, ...
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 1, ...
    'automarker', 0, ...
    'autosr', 1, ...
    'help', '');

% Philips Scanphyslog (.log)
% -----------------------------------------------------
defaults.import.datatypes(19) = ...
    struct('short', 'physlog', ...
    'long', 'Philips Scanphyslog (.log)', ...
    'ext', 'log', ...
    'funct', @scr_get_physlog, ...
    'chantypes', {{'ecg', 'ppu', 'resp', 'custom', 'marker'}}, ...
    'chandescription', 'channel', ...
    'multioption', 1, ...
    'searchoption', 0, ...
    'automarker', 0, ...
    'autosr', 1, ...
    'help', '');

%
% Default channel name for channel type search
% --------------------------------------------
defaults.import.channames.scr       = {'scr', 'scl', 'gsr', 'eda'};
defaults.import.channames.hr        = {'rate', 'hr'};
defaults.import.channames.hb        = {'beat', 'hb'};
defaults.import.channames.ecg       = {'ecg', 'ekg'};
defaults.import.channames.hp        = {'hp'};
defaults.import.channames.resp      = {'resp', 'breath'};
defaults.import.channames.pupil     = {'pupil', 'eye', 'track'};
defaults.import.channames.marker    = {'trig', 'mark', 'event', 'scanner'};
defaults.import.channames.sound     = {'sound'};
defaults.import.channames.custom    = {'custom'};

% Various import settings
% ----------------------
defaults.import.fileprefix = 'scr_';

defaults.import.rsr = 1000;                % minimum resampling rate for pulse data import
defaults.import.sr = 100;                  % final sampling rate for pulse data import

defaults.import.mat.sr_threshold = 1; %maximum value of the field '.sr' to which data is recognized as timestamps

% Preprocessing settings
% ----------------------
defaults.split.max_sn = 10; % split sessions: assume maximum 10 sessions
defaults.split.min_break_ratio = 3; % split sessions: assume inter marker intervals 3 times longer for breaks


% other settings
% -------------------------------------------------------------------------
defaults.get_transfer_sr=100;            % resampling rate for automatic transfer function computation

% default modalities
% -------------------------------------------------------------------------
defaults.modalities = struct('glm', 'scr', ...
    'sf', 'scr', ...
    'dcm', 'scr');

% -------------------------------------------------------------------------
%  modality-specific GLM settings
% -------------------------------------------------------------------------
% DEVELOPERS NOTES: in order to implement new modalities, add a field
% to defaults.glm. See first modality (SCR) for explanations.
% -------------------------------------------------------------------------

defaults.glm(1) = ...                                              % GLM for SCR
    struct('modality', 'scr', ...                                  % modality name
    'modelspec', 'scr', ...                                        % model specification
    'cbf', struct('fhandle', @scr_bf_scrf, 'args', 1), ...  % default basis function/set
    'filter', struct('lpfreq', 5, 'lporder', 1,  ...        % default filter settings
    'hpfreq', 0.05, 'hporder', 1, 'down', 10, ...
    'direction', 'uni'), ...
    'default', 1);

defaults.glm(2) = ... % GLM for HP (evoked)
    struct('modality', 'hp', ...
    'modelspec', 'hp_e', ...
    'cbf', struct('fhandle', @scr_bf_hprf_e, 'args', 1), ...
    'filter', struct('lpfreq', 5, 'lporder', 6,  ...
    'hpfreq', NaN, 'hporder', 1, 'down', 10, ...
    'direction', 'uni'), ...
    'default', 0);

defaults.glm(3) = ... % GLM for HP (fear-conditioning)
    struct('modality', 'hp', ...
    'modelspec', 'hp_fc', ...
    'cbf', struct('fhandle', @scr_bf_hprf_fc, 'args', 1), ...
    'filter', struct('lpfreq', 0.5, 'lporder', 1,  ...
    'hpfreq', 0.015, 'hporder', 1, 'down', 10, ...
    'direction', 'bi'), ...
    'default', 0);

defaults.glm(4) = ... % GLM for RA (fear-conditioning)
    struct('modality', 'ra', ...
    'modelspec', 'ra_fc', ...
    'cbf', struct('fhandle', @scr_bf_rarf_fc, 'args', 1), ...
    'filter', struct('lpfreq', 0.75, 'lporder', 1,  ...
    'hpfreq', 0.04, 'hporder', 1, 'down', 10, ...
    'direction', 'bi'), ...
    'default', 0);



% -------------------------------------------------------------------------
%  DCM settings
% -------------------------------------------------------------------------
% DEVELOPERS NOTES: currently this is being used for DCM for SCR, and for
% SF analysis. Further modalities and models can be implemented.
% -------------------------------------------------------------------------
defaults.dcm{1} = ...
    struct('filter', struct('lpfreq', 5, 'lporder', 1,  ...        % DCM for SCR filter settings
    'hpfreq', 0.0159, 'hporder', 1, 'down', 10, ...
    'direction', 'bi'), ...
    'sigma_offset', 0.1);

defaults.dcm{2} = ...
    struct('filter', struct('lpfreq', 5, 'lporder', 1,  ...        % DCM for SF filter settings
    'hpfreq', 0.0159, 'hporder', 1, 'down', 10, ...
    'direction', 'uni'));


% -------------------------------------------------------------------------
%  FIRST LEVEL settings
% -------------------------------------------------------------------------
defaults.first = {'glm', 'sf', 'dcm'}; % allowed first level model types

% look for settings, otherwise set defaults
% -------------------------------------------------------------------------
if exist([pth, 'scr_settings.mat'])
    load([pth, 'scr_settings.mat']);
else
    settings=defaults;
end;

settings.path=pth;
settings.scrpath=scrpath;
settings.spmpath=spmpath;
settings.matlabbatchpath=matlabbatchpath;
settings.scrcfgpath=scrcfgpath;
settings.signal = signal;

return;
