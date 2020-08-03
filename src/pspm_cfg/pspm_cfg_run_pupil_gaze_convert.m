function [out] = pspm_cfg_run_pupil_gaze_convert(job)

% $Id$
% $Rev$

channel_action = job.channel_action;
fn = job.datafile{1};

options = struct('channel_action', channel_action);
if (isfield(job.conversion, 'degree2sps'))
  % do degree to sps conversion
  [sts, out] = pspm_convert_visangle2sps(fn, options);

elseif (isfield(job.conversion, 'distance2sps'))
  args = job.conversion.distance2sps;
  [sts, out] = pspm_convert_pupil_gaze_distance(fn, 'sps', args.from, args.width, args.height, args.screen_distance, options);

elseif (isfield(job.conversion, 'distance2degree'))
  args = job.conversion.distance2degree;
  [ sts, out ] = pspm_convert_pupil_gaze_distance(fn, 'degree', args.from, args.width, args.height, args.screen_distance, options);
end


out = 1;
