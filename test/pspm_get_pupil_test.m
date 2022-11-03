classdef pspm_get_pupil_test < matlab.unittest.TestCase
  % ● Description
  % unittest class for the pspm_get_pupil function
  % PsPM TestEnvironment
  % ● Authorship
  % (C) 2013 Linus Rüttimann (University of Zurich)
  methods (Test)
    function test(this)
      import.sr = 100;
      import.data = ones(1,1000);
      import.units = 'unit';
      [sts, data] = pspm_get_pupil(import);
      this.verifyEqual(sts, 1);
      this.verifyEqual(data.data, import.data(:));
      this.verifyTrue(strcmpi(data.header.channeltype, 'pupil'));
      this.verifyEqual(data.header.units, import.units);
      this.verifyEqual(data.header.sr, import.sr);
    end
  end
end