function display = pspm_cfg_display

% $Id$
% $Rev$


%% Data file
datafile         = cfg_files;
datafile.name    = 'Data File';
datafile.tag     = 'datafile';
datafile.num     = [1 1];
datafile.filter  = '.*\.(mat|MAT|txt|TXT)$';
datafile.help    = {'Specify data file to display.'};

%% Executable branch
display      = cfg_exbranch;
display.name = 'Display Data';
display.tag  = 'display';
display.val  = {datafile};
display.prog = @pspm_cfg_run_display;
display.help = {'Display PsPM data file in a new figure.'};