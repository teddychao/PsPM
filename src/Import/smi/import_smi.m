function [data] = import_smi(varargin)
    % import_smi is the function for importing SMI data generated by an iView eyetracker.
    % The function changes the importing method depending on input the arguments. If an
    % event file has been generated by the eyetracker software and is
    % passed as an argument, import_SMI will also import the events and store
    % them in the ouput struct, otherwise no information about blinks and saccades are
    % generated. Gaze values during blinks/saccades are set to NaN.
    %
    % FORMAT: [data] = import_smi(sample_file)
    %         [data] = import_smi(sample_file, event_file)
    %             sample_file: path to the file which contains the recorded SMI Data File
    %                          in ASCII file format
    %             event_file:  path to the file which contains the computed events of the
    %                          recorded SMI Data File in ASCII file format
    %
    %             data: Output cell array of structures. Each entry in the cell array
    %                   corresponds to one recording session in the datafile.
    %                   Each of these structures have the following entries:
    %
    %                       raw: Matrix containing raw data columns.
    %                       raw_columns: Column headers of each raw data column.
    %                       channels: Matrix (timestep x n_cols) of relevant PsPM columns.
    %                       channels_columns: Column headers of each channels column.
    %                       units: Units of each channels column.
    %                       eyesObserved: One of L, R or LR, denoting observed eyes in datafile.
    %                       head_distance: Viewing distance.
    %                       head_distance_unit: Viewing distance units.
    %                       stimulus_dimension: Dimensions of the stimulus window.
    %                       stimulus_dimension_unit: Units of stimulus_dimension values.
    %                       sampleRate: Sampling rate of the recorded data.
    %                       gaze_coords: Structure with fields
    %                           - xmin: x coordinate of top left corner of screen in pixels.
    %                           - ymin: y coordinate of top left corner of screen in pixels.
    %                           - xmax: x coordinate of bottom right corner of screen in pixels.
    %                           - ymax: y coordinate of bottom right corner of screen in pixels.
    %                       markers: Times of markers.
    %                       markerinfos: Structure with fields
    %                           - names: Cell array of marker names.
    %                       record_date: Recording date
    %                       record_time: Recording time
    %
    %__________________________________________________________________________
    %
    % (C) 2019 Laure Ciernik
    % Updated 2021 Teddy Chao
    
    if isempty(varargin)
        error('ID:invalid_input', 'import_SMI.m needs at least one input sample_file.');
    end

    event_ex =false;
    if numel(varargin)==1
        sample_file = varargin{1};
        % check for the existence of sample_file
        if ~exist(sample_file,'file')
            error('ID:invalid_input', 'Passed sample_file does not exist.');
        end
    elseif numel(varargin)==2
        sample_file = varargin{1};
        events_file = varargin{2};
        event_ex=true;
        % check for the existence of sample_file and event_file
        if ~exist(sample_file,'file')
            error('ID:invalid_input', 'Passed sample_file does not exist.');
        elseif ~exist(events_file,'file')
            warning('ID:invalid_input', ['Passed event_file does not exist. ',...
                'Result will not include event information.']);
            event_ex = false;
        end
    else
        error('ID:invalid_input', 'import SMI has too many input arguments.');
    end
    %% open sample_file
    all_text = fileread(sample_file);
    backn = sprintf('\n');
    backr = sprintf('\r');
    tab = sprintf('\t');
    has_backr = ~isempty(find(all_text == backr, 1, 'first'));
    if has_backr
        back_off = 3;
    else
        back_off = 2;
    end
    line_begs = strfind(all_text, backn);
    line_begs = [1, line_begs + 1];

    header_sample = {};
    line_ctr = 1;
    curr_line = all_text(line_begs(line_ctr) : line_begs(line_ctr + 1) - back_off);
    while contains(curr_line, '##')
        header_sample{end + 1} = curr_line;
        line_ctr = line_ctr + 1;
        curr_line = all_text(line_begs(line_ctr) : line_begs(line_ctr + 1) - back_off);
    end
    header_sample = transpose(header_sample);
    line_begs = line_begs(line_ctr + 1 : end);
    all_text = all_text(line_begs(1) : end);
    line_begs = line_begs - line_begs(1) + 1;
    %% check columns of data
    % last line of the header descibes the columns contained in the importfile
    % (can be variable depending recodrings)
    columns = strsplit(curr_line, tab);
    POR_available = any(contains(columns,'POR'));

    %% process header informations
    % record time
    datePos = strncmpi(header_sample, '## Date', 7);
    dateFields = regexp(header_sample{datePos}, '\s+', 'split');
    % sample rate
    sr_pos = strncmpi(header_sample, '## Sample Rate',14);
    sr_field = regexp(header_sample{sr_pos}, '\s+', 'split');
    sr = str2double(sr_field{4});
    % gaze information
    % calibration area
    cal_a_pos = strncmpi(header_sample, '## Calibration Area',19);
    if~isempty(cal_a_pos)
        cal_field = regexp(header_sample{cal_a_pos}, '\s+', 'split');
        xmax = str2double(cal_field{4});
        ymax = str2double(cal_field{5});
    else
        xmax=[];
        ymax=[];
    end
    % calibration points
    cal_p_pos = strncmpi(header_sample, '## Calibration Point',20);
    if~isempty(cal_p_pos)
        CP = header_sample(cal_p_pos);
        CP_open = cell2mat(cellfun(@(x)regexpi(x,'('),CP,'uniformoutput',0));
        CP_close = cell2mat(cellfun(@(x)regexpi(x,')'),CP,'uniformoutput',0));
        for i=1:length(CP)
            CP_inf{i}=CP{i}(CP_open(i)+1:CP_close(i)-1);
        end
        CP_inf = cellfun(@(x) strsplit(x,';'),CP_inf,'uniformoutput',0);
        CP_inf = cellfun(@(x) cellfun(@(y) str2double(y),x,'uniformoutput',0),CP_inf,'uniformoutput',0);
        CP_inf = cellfun(@(x) x',CP_inf,'uniformoutput',0);
        calibration_points = cell2mat([CP_inf{:}]');
    else
        calibration_points=[];
    end

    % eyes observed
    format_pos = strncmpi(header_sample, '## Format',9);
    comma_pos = regexp(header_sample{format_pos}, ',');
    temp = header_sample{format_pos};
    temp(comma_pos)=[];
    format_fields = regexp(temp, '\s+', 'split');
    l_eye = any(cell2mat(cellfun(@(x)strcmpi(x,'LEFT'),format_fields,'UniformOutput',0)));
    r_eye = any(cell2mat(cellfun(@(x)strcmpi(x,'RIGHT'),format_fields,'UniformOutput',0)));
    if l_eye && r_eye
        eyesObserved = 'LR';
    elseif l_eye
        eyesObserved = 'L';
    else
        eyesObserved = 'R';
    end
    % Stimulus dimension
    sd_pos = strncmpi(header_sample, '## Stimulus Dimension',21);
    sd_field = regexp(header_sample{sd_pos}, '\s+', 'split');
    stimulus_dimension = [str2double(sd_field{5}),str2double(sd_field{6})];
    stimulus_dimension_unit = sd_field{4}(2:3);

    % Head distance
    hd_pos = strncmpi(header_sample, '## Head Distance',16);
    hd_field = regexp(header_sample{hd_pos}, '\s+', 'split');
    head_distance = str2double(hd_field{5});
    head_distance_unit = hd_field{4}(2:3);

    %% get data part of sample file
    msg_field_indices = strfind(all_text, sprintf('\tMSG\t'));
    comment_indices = [];
    msg_lines = {};
    for i = 1:numel(msg_field_indices)
        b = msg_field_indices(i);
        while all_text(b) ~= backn
            b = b - 1;
        end
        e = msg_field_indices(i);
        while all_text(e) ~= backn
            e = e + 1;
        end
        comment_indices(end + 1 : end + 2) = [b + 1, b + 2];
        msg_lines{end + 1} = all_text(b + 1 : e - back_off + 1);
    end
    all_text(comment_indices) = '/';

    formatSpec = ['%f%*s', repmat('%f', 1, numel(columns) - 2)];
    C = textscan(all_text, formatSpec, 'Delimiter', '\t', 'CollectOutput', 1, 'TreatAsEmpty', '.', 'CommentStyle', '//');
    datanum = C{1};
    clear C;
    clear all_text;
    datanum = [datanum(:, 1), ones(size(datanum, 1), 1), datanum(:, 2:end)];

    %% open events_file, get events, and events header
    if event_ex
        % get events from event file
        eventsRaw = read_smi_events(events_file);
        % subtract experiment begin offset
        for name = {'blink_l', 'blink_r', 'sacc_l', 'sacc_r'}
            keyname = name{1};
            eventsRaw.(keyname).start = eventsRaw.(keyname).start;
            eventsRaw.(keyname).end = eventsRaw.(keyname).end;
        end
        eventsRaw.marker.start = eventsRaw.marker.start;
    end

    [pupil_channels, pupil_units] = get_pupil_channels(columns);
    %% get all messages - if Event file is given take messages of event file otherwise read from file

    messageCols = {'Time','Trial','Text'};
    if event_ex
        nr_events = numel(eventsRaw.marker.msg);
        msgs = cell(3, nr_events);
        for i=1:nr_events
            msgs{1, i} = eventsRaw.marker.start(i);
            msgs{2, i} = eventsRaw.marker.trial(i);
            msgs{3, i} = eventsRaw.marker.msg{i};
        end
    else
        nr_events = numel(msg_lines);
        msgs = cell(3, nr_events);
        for i=1:nr_events
            C = textscan(msg_lines{i}, '%f%*s%f%s', 'Delimiter', '\t');
            msgs{1, i} = C{1};
            msgs{2, i} = C{2};
            msgs{3, i} = C{3}{1};
        end
    end

    %% find number of recordings / sessions and split
    idx_of_trials = strcmpi(columns,'Trial');
    trials = datanum(:, idx_of_trials);
    trial_changepoints = find(diff(trials));
    n_sessions = 1 + numel(trial_changepoints);
    if isempty(trial_changepoints)
        sess_beg_end = [0 numel(datanum(:, 1))];
    else
        sess_beg_end = [0 trial_changepoints' numel(datanum(:, 1))];
    end
    data = cell(n_sessions, 1);
    %% convert data, compute blink, saccade and messages

    bsearch_path = pspm_path('ext', 'bsearch');
    addpath(bsearch_path);
    for sn = 1:n_sessions
        data{sn} = struct();
        sn_datanum = datanum(sess_beg_end(sn) + 1:sess_beg_end(sn + 1), :);

        data{sn}.record_date  = dateFields{3};
        data{sn}.record_time  = dateFields{4};
        data{sn}.sampleRate   = sr;
        data{sn}.eyesObserved = eyesObserved;
        data{sn}.stimulus_dimension = stimulus_dimension;
        data{sn}.stimulus_dimension_unit = stimulus_dimension_unit;
        data{sn}.head_distance = head_distance;
        data{sn}.head_distance_unit = head_distance_unit;

        % only usefull information when POR data is available
        data{sn}.gaze_coords.xmin = 0;
        data{sn}.gaze_coords.xmax = xmax;
        data{sn}.gaze_coords.ymin = 0;
        data{sn}.gaze_coords.ymax = ymax;
        data{sn}.calibration_points=calibration_points;

        times = sn_datanum(:, 1);
        %% if even_file is given, include blinkes and saccades
        if event_ex
            blink_l_trial_sess = eventsRaw.blink_l.trial == sn;
            blink_r_trial_sess = eventsRaw.blink_r.trial == sn;
            sacc_l_trial_sess = eventsRaw.sacc_l.trial == sn;
            sacc_r_trial_sess = eventsRaw.sacc_r.trial == sn;

            % store the indicies in right format
            % ignore_str_pos = { {start_blink_l,end_blink_l,start_blink_r,end_blink_r},
            %                    {start_saccade_l,end_saccade_l,start_saccade_r,end_saccade_r} }
            ignore_str_pos = cell(2,1);
            ignore_str_pos{1}=cell(4,1);
            ignore_str_pos{2}=cell(4,1);

            if strcmpi(eyesObserved,'LR')
                % alwas add the time of the beginning of the current trial
                % since the measured start and end times are relative to the
                % time of the beginning ot the current trial

                start_blink_l = eventsRaw.blink_l.start(blink_l_trial_sess);%+time;
                end_blink_l = eventsRaw.blink_l.end(blink_l_trial_sess);%+time;
                [ignore_str_pos{1}{1},ignore_str_pos{1}{2}]=get_idx(times,start_blink_l,end_blink_l);

                start_blink_r = eventsRaw.blink_r.start(blink_r_trial_sess);%+time;
                end_blink_r = eventsRaw.blink_r.end(blink_r_trial_sess);%+time;
                [ignore_str_pos{1}{3},ignore_str_pos{1}{4}]=get_idx(times,start_blink_r,end_blink_r);

                start_saccade_l = eventsRaw.sacc_l.start(sacc_l_trial_sess);%+time;
                end_saccade_l = eventsRaw.sacc_l.end(sacc_l_trial_sess);%+time;
                [ignore_str_pos{2}{1},ignore_str_pos{2}{2}]=get_idx(times,start_saccade_l,end_saccade_l);

                start_saccade_r = eventsRaw.sacc_r.start(sacc_r_trial_sess);%+time;
                end_saccade_r = eventsRaw.sacc_r.end(sacc_r_trial_sess);%+time;
                [ignore_str_pos{2}{3},ignore_str_pos{2}{4}]=get_idx(times,start_saccade_r,end_saccade_r);


            elseif strcmpi(eyesObserved, 'L')
                start_blink = eventsRaw.blink_l.start(blink_l_trial_sess);%+time;
                end_blink = eventsRaw.blink_l.end(blink_l_trial_sess)+time;
                start_saccade = eventsRaw.sacc_l.start(sacc_l_trial_sess);%+time;
                end_saccade = eventsRaw.sacc_l.end(sacc_l_trial_sess);%+time;
                [ignore_str_pos{1}{1},ignore_str_pos{1}{2}]=get_idx(times,start_blink,end_blink);
                [ignore_str_pos{2}{1},ignore_str_pos{2}{2}]=get_idx(times,start_saccade,end_saccade);
            else
                start_blink = eventsRaw.blink_r.start(blink_r_trial_sess);%+time;
                end_blink = eventsRaw.blink_r.end(blink_r_trial_sess)+time;
                start_saccade = eventsRaw.sacc_r.start(sacc_r_trial_sess);%+time;
                end_saccade = eventsRaw.sacc_r.end(sacc_r_trial_sess);%+time;
                [ignore_str_pos{1}{3},ignore_str_pos{1}{4}]=get_idx(times,start_blink,end_blink);
                [ignore_str_pos{2}{3},ignore_str_pos{2}{4}]=get_idx(times,start_saccade,end_saccade);
            end

            % add blinks and saccades to datanum
            ignore_names = {'Blink', 'Saccade'};
            for j = 1:numel(ignore_str_pos)
                for i=1:numel(data{sn}.eyesObserved)
                    if strcmpi(data{sn}.eyesObserved(i), 'L')
                        ep_start = 1;
                        ep_stop = 2;
                    else
                        ep_start = 3;
                        ep_stop = 4;
                    end
                    idx = size(sn_datanum, 2) + 1;
                    for k = 1:length(ignore_str_pos{j}{ep_start})
                        start_pos = max(1, ignore_str_pos{j}{ep_start}(k));
                        stop_pos = min(size(sn_datanum, 1), ignore_str_pos{j}{ep_stop}(k));
                        sn_datanum(start_pos : stop_pos, idx) = 1;
                    end
                    columns{idx} = [upper(data{sn}.eyesObserved(i)), ' ', ignore_names{j}];
                end
            end
        end

        %% messages
        data{sn}.markers = [];
        data{sn}.markerinfos.value = [];
        data{sn}.markerinfos.name = {};
        val_msg_idx = cell2mat(msgs(2, :)) == sn;
        if ~isempty(val_msg_idx)
            msg_times_in_sn = cell2mat(msgs(1, :));
            msg_times_in_sn = msg_times_in_sn(val_msg_idx);
            data{sn}.markers = msg_times_in_sn;

            msg_str =  msgs(3, val_msg_idx);
            msg_str_idx = cell2mat(cellfun(@(x) find(x==':',1,'first'),msg_str,'UniformOutput',0));
            for u=1:length(msg_str_idx)
                msg_str{u} = msg_str{u}(msg_str_idx(u)+2:end);
            end
            data{sn}.markerinfos.name = msg_str;

            messages = unique(msg_str);
            msg_indices_in_uniq = [];
            for i = 1:numel(msg_str)
                msg_indices_in_uniq(end + 1) = find(strcmpi(msg_str{i}, messages));
            end
            data{sn}.markerinfos.value = msg_indices_in_uniq;
        end

        %% remove lines containing NaN (i.e. pure text lines) so that lines have a time interpretation
        data{sn}.raw = sn_datanum;
        data{sn}.raw(isnan(sn_datanum(:,4)),:) = [];
        % save column heder of raw data
        raw_columns = columns;
        data{sn}.raw_columns = raw_columns;

        if strcmpi(data{sn}.eyesObserved, 'LR')
            % pupilL, pupilR, xL, yL, xR, yR, blinkL, blinkR, saccadeL,
            % saccadeR
            % get idx of different channel
            if POR_available
                POR_xL = find(contains(data{sn}.raw_columns,'L POR X'), 1);
                POR_yL = find(contains(data{sn}.raw_columns,'L POR Y'), 1);
                POR_xR = find(contains(data{sn}.raw_columns,'R POR X'), 1);
                POR_yR = find(contains(data{sn}.raw_columns,'R POR Y'), 1);
            end
            xL = find(contains(data{sn}.raw_columns,'L Raw X'), 1);
            yL = find(contains(data{sn}.raw_columns,'L Raw Y'), 1);
            xR = find(contains(data{sn}.raw_columns,'R Raw X'), 1);
            yR = find(contains(data{sn}.raw_columns,'R Raw Y'), 1);


            if event_ex
                blinkL = size(data{sn}.raw,2)-3;
                blinkR = size(data{sn}.raw,2)-2;
                saccadeL = size(data{sn}.raw,2)-1;
                saccadeR = size(data{sn}.raw,2);

                if POR_available
                    channel_indices = [pupil_channels,xL,yL,xR,yR,POR_xL,POR_yL,POR_xR,POR_yR,blinkL,blinkR,saccadeL,saccadeR];
                    data{sn}.units = {pupil_units{:}, 'pixel', 'pixel', 'pixel', 'pixel','pixel','pixel','pixel','pixel','blink', 'blink', 'saccade', 'saccade'};
                else
                    channel_indices = [pupil_channels,xL,yL,xR,yR,blinkL,blinkR,saccadeL,saccadeR];
                    data{sn}.units = {pupil_units{:}, 'pixel', 'pixel', 'pixel', 'pixel', 'blink', 'blink', 'saccade', 'saccade'};
                end
                data{sn}.chans = data{sn}.raw(:, channel_indices);
                data{sn}.chans_columns = data{sn}.raw_columns(channel_indices);

            else
                if POR_available
                    channel_indices = [pupil_channels,xL,yL,xR,yR,POR_xL,POR_yL,POR_xR,POR_yR];
                    data{sn}.units = {pupil_units{:}, 'pixel', 'pixel', 'pixel', 'pixel', 'pixel', 'pixel', 'pixel', 'pixel'};
                    data{sn}.chans = data{sn}.raw(:, channel_indices);
                    data{sn}.chans_columns = data{sn}.raw_columns(channel_indices);
                else
                    channel_indices = [pupil_channels,xL,yL,xR,yR];
                    data{sn}.units = {pupil_units{:}, 'pixel', 'pixel', 'pixel', 'pixel'};
                    data{sn}.chans = data{sn}.raw(:, channel_indices);
                    data{sn}.chans_columns = data{sn}.raw_columns(channel_indices);
                end
            end
        else
            % get idx of channels
            if POR_available
                POR_x = find(contains(data{sn}.raw_columns,'POR X'), 1);
                POR_y = find(contains(data{sn}.raw_columns,'POR Y'), 1);
            end
            x = find(contains(data{sn}.raw_columns,'Raw X'), 1);
            y = find(contains(data{sn}.raw_columns,'Raw Y'), 1);

            if event_ex
                %distinguish eyes
                blink = size(data{sn}.raw, 2)-1;
                saccade = size(data{sn}.raw, 2);
                if POR_available
                    channel_indices = [pupil_channels,x,y,POR_x,POR_y,blink,saccade];
                    data{sn}.units = {pupil_units{:}, 'pixel', 'pixel', 'pixel', 'pixel', 'blink', 'saccade'};
                    data{sn}.chans = data{sn}.raw(:, channel_indices);
                    data{sn}.chans_columns = data{sn}.raw_columns(channel_indices);
                else
                    channel_indices = [pupil_channels,x,y,blink,saccade];
                    data{sn}.units = {pupil_units{:}, 'pixel', 'pixel', 'blink', 'saccade'};
                    data{sn}.chans = data{sn}.raw(:, channel_indices);
                    data{sn}.chans_columns = data{sn}.raw_columns(channel_indices);
                end
            else
                if POR_available
                    channel_indices = [pupil_channels,x,y,POR_x,POR_y];
                    data{sn}.chans = data{sn}.raw(:, channel_indices);
                    data{sn}.chans_columns = data{sn}.raw_columns(channel_indices);
                    data{sn}.units = {pupil_units{:}, 'pixel', 'pixel', 'pixel', 'pixel'};
                else
                    channel_indices = [pupil_channels,x,y];
                    data{sn}.chans = data{sn}.raw(:, channel_indices);
                    data{sn}.chans_columns = data{sn}.raw_columns(channel_indices);
                    data{sn}.units = {pupil_units{:}, 'pixel', 'pixel'};
                end
            end
        end
    end
    rmpath(bsearch_path);
end

function [s_idx,end_idx]=get_idx(time_vec,s_vec,end_vec)
    % function to find the idx of start and end
    s_idx = bsearch(time_vec, s_vec);
    end_idx = bsearch(time_vec, end_vec) + 1;
    if isempty(s_idx)
        error('ID:invalid_input', ['All values in the vector have ',...
            'starting times outside of the recording time. '],...
            'Please check your event file.');
    elseif isempty(end_idx)
        error('ID:invalid_input', ['All values in the vector have ',...
            'ending times outside of the recording time. '],...
            'Please check your event file.');
    end
    if numel(s_idx)>numel(end_idx)
        diff = numel(s_idx)-numel(end_idx);
        end_idx(end+1:end+diff)={[]};
    end
    for i=1:numel(s_idx)
        if end_idx(i)+1>length(time_vec)
            end_idx(i)=length(time_vec);
        elseif s_idx(i)-1 <1
            s_idx(i)=1;
        elseif s_idx(i)-1 >length(time_vec)
            s_idx(i)=length(time_vec);
        else
            s_idx(i)=s_idx(i)-1;
            end_idx(i)=end_idx(i)+1;
        end
    end
end

function [pupil_channels, pupil_units] = get_pupil_channels(columns)
    header_names_units = {...
        {'L Dia X [px]', 'diameter pixel'},...
        {'L Dia X [mm]', 'diameter mm'},...
        {'L Dia Y [px]', 'diameter pixel'},...
        {'L Dia Y [mm]', 'diameter mm'},...
        {'L Dia [px]', 'diameter pixel'},...
        {'L Dia [mm]', 'diameter mm'},...
        {'L Area [px', 'area pixel2'},...
        {'L Area [mm', 'area mm2'},...
        {'L Mapped Diameter [mm]', 'diameter mm'},...
        {'R Dia X [px]', 'diameter pixel'},...
        {'R Dia X [mm]', 'diameter mm'},...
        {'R Dia Y [px]', 'diameter pixel'},...
        {'R Dia Y [mm]', 'diameter mm'},...
        {'R Dia [px]', 'diameter pixel'},...
        {'R Dia [mm]', 'diameter mm'},...
        {'R Area [px', 'area pixel2'},...
        {'R Area [mm', 'area mm2'},...
        {'R Mapped Diameter [mm]', 'diameter mm'}...
    };
    pupil_channels = [];
    pupil_units = {};
    for i = 1:numel(header_names_units)
        idx = find(contains(columns, header_names_units{i}{1}));
        if ~isempty(idx)
            pupil_channels(end + 1) = idx;
            pupil_units{end + 1} = header_names_units{i}{2};
        end
    end
end
