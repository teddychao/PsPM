function [sts, data] = pspm_get_saccade_l(import)
% ● Description
%   pspm_get_saccade_l is a common function for importing eyelink data
%   (saccade_l data)
% ● Format
%   [sts, data] = pspm_get_saccade_l(import)
% ● Arguments
%    import:
%     .data: column vector of waveform data
%       .sr: sample rate
%    .units:
% ● History
%   Introduced in PsPM 4.0.2
%   Written in 2018 by Laure Ciernik
%   Maintained in 2022 by Teddy Chao (UCL)

% initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
% assign pupil data
data.data = import.data(:);
% add header
data.header.channeltype = 'saccade_l';
data.header.units = import.units;
data.header.sr = import.sr;
% check status
sts = 1;
end
