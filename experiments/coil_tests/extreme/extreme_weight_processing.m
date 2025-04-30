filename = 'finger_press_test.csv';

raw_data = readtable(filename,'Delimiter',',');

% Take care of header chunk
raw_time = raw_data{:,1};
[row, ~] = find(isnan(raw_time));

if ~isempty(row)
    % double check to make sure nan is from the header instead of data
    if (row(end) - row(1) + 1) == length(row)

        raw_data = raw_data(row(end)+1:end,:); % clip header
    end
end
raw_data(end,:) = [];   % get rid of last line in case of incomplete data log

% Raw time & data
time = raw_data{:,1}./1000; % in seconds
data = raw_data{:,2};

figure(1);
plot(time,data)

baseline = time < 5;

data_bl = data(baseline);
time_bl = time(baseline);

mag_bl = mean(data_bl);

mag_min = min(data);

mag_diff = mag_bl - mag_min;

aft = time > 20;

data_aft = data(aft);

data_aft_abs = mean(data_aft);

data_aft = data_aft - data_aft(1);

diff_aft = data_aft(end) - data_aft(1);

time_aft = time(aft);

p = polyfit(time_aft,data_aft,1);

diff_bf_aft = data_aft_abs - mag_bl