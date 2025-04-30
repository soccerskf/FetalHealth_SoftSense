function [rms_data, magnitude] = single_coil_processing(material,turns,f_ratio,voltage,withRing)

if withRing
    filename = strcat('00',num2str(material),'_',num2str(turns),'turn_F',num2str(f_ratio),'_',num2str(voltage),'V_1Hz_ring.csv');
else
    filename = strcat('00',num2str(material),'_',num2str(turns),'turn_F',num2str(f_ratio),'_',num2str(voltage),'V_1Hz.csv');
end

    % filename = '0050_20turn_F2_5.5V_1Hz.csv';

    raw_data = readtable(filename,'Delimiter',',');

    % Take care of header chunk
    raw_time = raw_data{:,"Var1"};
    [row, ~] = find(isnan(raw_time));

    if ~isempty(row)
        % double check to make sure nan is from the header instead of data
        if (row(end) - row(1) + 1) == length(row)

            raw_data = raw_data(row(end)+1:end,:); % clip header
        end
    end
    raw_data(end,:) = [];   % get rid of last line in case of incomplete data log

    % Raw time & data
    time = raw_data{:,'Var1'}./1000; % in seconds
    data = raw_data{:,'Var2'};

    % % Show raw data plot
    % figure;
    % plot(time, data)

    time_difference = time(2:end) - time(1:end-1);
    ts = mean(time_difference);
    std_ts = std(time_difference);

    fs = 1/ts;

    rs_time = time(1):ts:time(end);

    rs_data = interp1(time,data,rs_time,'spline');

    % figure;
    % plot(rs_time,rs_data)

    % High pass to try to remove baseline

    cutoff_freq = 0.5;    % Cutoff frequency in Hz
    filter_order = 4;    % Filter order (adjust as needed)

    % lpf = designfilt('lowpassiir', ...
    %     'FilterOrder', filter_order, ...
    %     'HalfPowerFrequency', cutoff_freq, ...
    %     'SampleRate', fs, ...
    %     'DesignMethod', 'butter');

    [b, a] = butter(filter_order, cutoff_freq/(fs/2), 'high');
    hp_data= filtfilt(b, a, rs_data);

    % figure;
    % plot(rs_time, hp_data)

    %% zero passing

    % clip data

    clip_data = hp_data(ceil(5*fs):ceil(25*fs));
    clip_time = rs_time(ceil(5*fs):ceil(25*fs));

    % figure;
    % plot(clip_time, clip_data)

    max_data = max(clip_data);
    min_data = min(clip_data);

    p2p_data = max_data - min_data;

    % RMS
    shift_data = clip_data - min_data;
    rms_data = sqrt(mean(shift_data.^2));

    avg_data = clip_data - min_data - p2p_data./2;

    data_prod = avg_data(1:end-1) .* avg_data(2:end);

    zero_crossing = find(data_prod < 0);

    avg_integral = [];

    for m = 1:length(zero_crossing)-1
        time_region = clip_time(zero_crossing(m):zero_crossing(m+1));
        data_region = avg_data(zero_crossing(m):zero_crossing(m+1));
        avg_integral(m) = trapz(time_region, data_region)./(time_region(end) - time_region(1));
    end

    pos_integral = avg_integral > 0;
    neg_integral = avg_integral < 0;

    pos_mag = mean(avg_integral(pos_integral));
    neg_mag = mean(avg_integral(neg_integral));
    
    
    % figure;
    % plot(clip_time,avg_data)
    % hold on
    % plot(clip_time(zero_crossing),zeros(length(zero_crossing)),'o')
    % hold off
    magnitude = pos_mag - neg_mag;

end