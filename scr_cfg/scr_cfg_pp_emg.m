function [cfg] = scr_cfg_pp_emg
% function [cfg] = scr_cfg_pp_emg
%
% Matlabbatch menu for data preprocessing
%__________________________________________________________________________
% PsPM 3.1
% (C) 2016 Tobias Moser (University of Zurich)

% $Id$
% $Rev$

%% Data preprocessing
cfg        = cfg_repeat;
cfg.name   = 'Startle EMG';
cfg.tag    = 'pp_emg';
cfg.values = {scr_cfg_find_sounds};
cfg.forcestruct = true;
cfg.help   = {'Help: EMG preprocessing'};