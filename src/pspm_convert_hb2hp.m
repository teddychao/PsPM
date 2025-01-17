function [sts, infos] = pspm_convert_hb2hp(fn, sr, channel, options)
% ● Description
%   pspm_convert_hb2hp transforms heart beat data into an interpolated heart
%   rate signal and adds this as an additional channel to the data file
% ● Format
%   sts = pspm_convert_hb2hp(fn, sr, channel, options)
% ● Arguments
%                 fn: data file name
%                 sr: new sample rate for heart period channel
%            channel: number of heart beat channel (optional, default:
%                     first heart beat channel); if empty (= 0 / [])
%                     will be set to default value
%   ┌────────options: optional arguments [struct]
%   ├.channel_action: ['add'/'replace', default as 'replace']
%   │                 Defines whether heart rate signal
%   │                 should be added or the corresponding preprocessed
%   │                 channel should be replaced.
%   ├─────────.limit: [struct]
%   │                 Specifies upper and lower limit for heart
%   │                 periods. If the limit is exceeded, the values will
%   │                 be ignored/removed and interpolated.
%   ├─────────.upper: [numeric]
%   │                 Specifies the upper limit of the
%   │                 heart periods in seconds. Default is 2.
%   └─────────.lower: [numeric]
%                     Specifies the lower limit of the
%                     heart periods in seconds. Default is 0.2.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

%% initialise & user output
sts = -1;
global settings;
if isempty(settings), pspm_init;
end
if ~exist('options','var')
  options = struct();
end
options = pspm_options(options, 'convert_hb2hp');
if options.invalid
  return
end

% check input
% -------------------------------------------------------------------------
if nargin < 1
  warning('ID:invalid_input','No input. Don''t know what to do.'); return;
elseif ~ischar(fn)
  warning('ID:invalid_input','Need file name string as first input.'); return;
elseif nargin < 2
  warning('ID:invalid_input','No sample rate given.'); return;
elseif ~isnumeric(sr)
  warning('ID:invalid_input','Sample rate needs to be numeric.'); return;
elseif nargin < 3 || isempty(channel) || (isnumeric(channel) && (channel == 0))
  channel = 'hb';
elseif ~isnumeric(channel) && ~strcmpi(channel, 'hb')
  warning('ID:invalid_input','Channel number must be numeric'); return;
end


% get data
% -------------------------------------------------------------------------
[nsts, dinfos, data] = pspm_load_data(fn, channel);
if nsts == -1
  warning('ID:invalid_input', 'call of pspm_load_data failed');
  return;
end
if numel(data) > 1
  fprintf('There is more than one heart beat channel in the data file. Only the first of these will be analysed.');
  data = data(1);
end

% interpolate
% -------------------------------------------------------------------------
hb  = data{1}.data;
ibi = diff(hb);
idx = find(ibi > options.limit.lower & ibi < options.limit.upper);
hp = 1000 * ibi; % in ms
newt = (1/sr):(1/sr):dinfos.duration;
try
  newhp = interp1(hb(idx+1), hp(idx), newt, 'linear' ,'extrap'); % assign hr to following heart beat
catch
  warning('ID:too_strict_limits', ['Interpolation failed because there wasn''t enough heartbeats within the ',...
    'required period limits. Filling the heart period channel with NaNs.']);
  newhp = NaN(1, size(newt, 2));
end


% save data
% -------------------------------------------------------------------------
newdata.data = newhp(:);
newdata.header.sr = sr;
newdata.header.units = 'ms';
newdata.header.chantype = 'hp';


o.msg.prefix = 'Heart beat converted to heart period and';
try
  [nsts,winfos] = pspm_write_channel(fn, newdata, options.channel_action, o);
  if nsts == -1, return;
  end
catch
  warning('ID:invalid_input', 'call of pspm_write_channel failed');
  return;
end
infos.channel = winfos.channel;
sts = 1;
return
