classdef pspm_combine_markerchannels_test < matlab.unittest.TestCase
  % ● Description
  %   Unittest class for the pspm_combine_markerchannels function
  % ● History
  %   Written in 2023 by Teddy Chao
  properties
    fn1 = 'DF_combine_markerchannels1';
    fn2 = 'DF_combine_markerchannels2';
    duration1 = 10;
  end
  properties (TestParameter)
  end
  methods (Test)
    function test_combine_basic(this)
      fn = pspm_find_free_fn(this.fn1, '.mat');
      channels{1}.chantype = 'scr';
      channels{2}.chantype = 'hb';
      channels{3}.chantype = 'marker';
      channels{4}.chantype = 'marker';
      pspm_testdata_gen(channels, this.duration1, fn);
      % test defaultly combining all marker channels
      sts = pspm_combine_markerchannels(fn);
      this.verifyTrue(sts == 1, 'the function run successfully');
      [sts_out, ~, ~, fstruct] = pspm_load_data(fn, 'none');
      this.verifyTrue(sts_out == 1, 'the processed file couldn''t be loaded');
      this.verifyTrue(fstruct.numofchan == numel(channels)+1, 'the output has a different size');
      % test combining all marker channels and replacing the original
      sts = pspm_combine_markerchannels(fn, struct('channel_action', 'replace'));
      this.verifyTrue(sts == 1, 'the function run successfully');
      [sts_out, ~, ~, fstruct] = pspm_load_data(fn, 'none');
      this.verifyTrue(sts_out == 1, 'the processed file couldn''t be loaded');
      this.verifyTrue(fstruct.numofchan == 3, 'the output has a different size');
      delete(fn)
    end
    function test_combine_specific_channel_numbers(this)
      fn = pspm_find_free_fn(this.fn1, '.mat');
      channels{1}.chantype = 'scr';
      channels{2}.chantype = 'hb';
      channels{3}.chantype = 'marker';
      channels{4}.chantype = 'marker';
      channels{5}.chantype = 'marker';
      channels{6}.chantype = 'marker';
      channels{7}.chantype = 'marker';
      channels{8}.chantype = 'marker';
      channels{9}.chantype = 'marker';
      pspm_testdata_gen(channels, this.duration1, fn);
      % test defaultly combining all marker channels
      sts = pspm_combine_markerchannels(fn, struct('marker_chan_num', [3,6,9]));
      this.verifyTrue(sts == 1, 'the function run successfully');
      [sts_out, ~, ~, fstruct] = pspm_load_data(fn, 'none');
      this.verifyTrue(sts_out == 1, 'the processed file couldn''t be loaded');
      this.verifyTrue(fstruct.numofchan == numel(channels)+1, 'the output has a different size');
      delete(fn)
      fn = pspm_find_free_fn(this.fn2, '.mat');
      channels{1}.chantype = 'scr';
      channels{2}.chantype = 'hb';
      channels{3}.chantype = 'marker';
      channels{4}.chantype = 'marker';
      channels{5}.chantype = 'marker';
      channels{6}.chantype = 'marker';
      channels{7}.chantype = 'marker';
      channels{8}.chantype = 'marker';
      channels{9}.chantype = 'marker';
      pspm_testdata_gen(channels, this.duration1, fn);
      % test combining all marker channels and replacing the original
      sts = pspm_combine_markerchannels(fn, struct('marker_chan_num', [3,6,9], 'channel_action', 'replace'));
      this.verifyTrue(sts == 1, 'the function run successfully');
      [sts_out, ~, ~, fstruct] = pspm_load_data(fn, 'none');
      this.verifyTrue(sts_out == 1, 'the processed file couldn''t be loaded');
      this.verifyTrue(fstruct.numofchan == 7, 'the output has a different size');
      delete(fn)
    end
  end
end
