function [sts, data] = pspm_get_ppg(import)
% ● Description
%   pspm_get_ppg is a common function for importing PPG data
% ● Format
%   [sts, data]= pspm_get_ppg(import)
% ● Arguments
%   import.data: column vector of waveform data
%     import.sr: sample rate
% ● History
%   Introduced in PsPM 3.0
%   Written in 2015 by Tobias Moser (University of Zurich)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
% assign respiratory data
data.data = import.data(:);
% add header
data.header.channeltype = 'ppg';
data.header.units = import.units;
data.header.sr = import.sr;
% check status
sts = 1;
