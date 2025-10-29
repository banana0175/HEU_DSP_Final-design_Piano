% 钢琴单音频域特征提取脚本
% 功能：读取钢琴单音音频，提取时域波形、频域频谱，识别基频与泛音
% 日期：2025-10-27
clear; clc; close all;

%% 1. 读取音频文件
audio_path = 'D:\桌面\A4.mp3';                % 手动替换为你的A4.mp3音频路径
[audio_signal, fs] = audioread(audio_path);   % 读取信号和A4.mp3采样率

% 处理双声道（转为单声道，取左声道）
if size(audio_signal, 2) > 1
    audio_signal = audio_signal(:, 1);
end

% 显示音频基本信息
fprintf('音频采样率：%d Hz\n', fs);
fprintf('音频时长：%.2f 秒\n', length(audio_signal)/fs);


%% 2. 绘制原始时域波形并截取有效区间
t_full = (0:length(audio_signal)-1) / fs;  % 完整时间轴

% 绘制完整时域波形
figure('Name', '原始时域波形', 'Position', [100, 100, 1000, 400]);
plot(t_full, audio_signal, 'b');
xlabel('时间（s）');
ylabel('振幅');
title('钢琴单音原始时域波形');
grid on;
xlim([0, max(t_full)]);

% 手动截取有效区间（避开静音和起音冲击，取稳定振动段）
start_time = 0.5;    % 有效区间起始时间（秒）
end_time = 2   ;      % 有效区间结束时间（秒）
start_idx = round(start_time * fs) + 1; 
end_idx = round(end_time * fs);
signal_cut = audio_signal(start_idx:end_idx);  % 截取后的有效信号
t_cut = t_full(start_idx:end_idx);             % 对应时间轴

% 绘制截取后的时域波形
figure('Name', '截取后时域波形', 'Position', [100, 200, 1000, 400]);
plot(t_cut, signal_cut, 'r');
xlabel('时间（s）');
ylabel('振幅');
title(['截取后时域波形（', num2str(start_time), 's - ', num2str(end_time), 's）']);
grid on;
xlim([start_time, end_time]);


%% 3. 傅里叶变换（FFT）转换至频域
N = length(signal_cut);  % 截取后信号长度
f_fft = (0:N-1) * (fs / N);  % 完整频率轴（0~fs）

% 计算FFT并归一化振幅
fft_result = fft(signal_cut) / N;  % 除以N使振幅与原始信号量级一致
amplitude = abs(fft_result);       % 取模得到振幅

% 取单侧边谱（0~fs/2，避免镜像对称）
half_N = floor(N/2) + 1;
f = f_fft(1:half_N);       % 有效频率轴（0~fs/2）
amp = amplitude(1:half_N);  % 对应振幅


%% 4. 峰值检测（提取基频与泛音）
% 设置峰值检测参数（根据信号调整，确保检测到泛音）
threshold = max(amp) * 0.05;  % 阈值设为最大振幅的5%（过滤噪声）
min_distance = round(0.5 * N / fs);  % 峰值最小频率间隔（避免相邻噪声峰）

% 检测频域峰值
[peaks_amp, peaks_idx] = findpeaks(amp, ...
    'MinPeakHeight', threshold, ...
    'MinPeakDistance', min_distance);
peaks_freq = f(peaks_idx);  % 峰值对应的频率

% 按频率排序（确保基频在最前）
[peaks_freq, sort_idx] = sort(peaks_freq);
peaks_amp = peaks_amp(sort_idx);

% 过滤超高频（钢琴泛音通常在10kHz以内）
max_interest_freq = 10000;  % 最大关注频率（Hz）
valid_mask = peaks_freq <= max_interest_freq;
peaks_freq = peaks_freq(valid_mask);
peaks_amp = peaks_amp(valid_mask);


%% 5. 频域结果可视化
% 绘制频域频谱并标记峰值
figure('Name', '钢琴单音频域频谱', 'Position', [100, 300, 1200, 500]);
plot(f, amp, 'b', 'LineWidth', 1.2);
hold on;
plot(peaks_freq, peaks_amp, 'ro', 'MarkerSize', 8, 'LineWidth', 2);  % 标记基频和泛音
xlabel('频率（Hz）', 'FontSize', 12);
ylabel('振幅', 'FontSize', 12);
title('钢琴单音频域频谱（基频与泛音标记）', 'FontSize', 14);
grid on;
xlim([0, max_interest_freq]);  % 聚焦0~10kHz
ylim([0, max(amp)*1.1]);       % 调整振幅范围

% 标注基频和前6次泛音（若存在）
if ~isempty(peaks_freq)
    % 标注基频
    text(peaks_freq(1), peaks_amp(1), ...
        [' 基频: ', num2str(round(peaks_freq(1))), 'Hz'], ...
        'Color', 'darkred', 'FontSize', 10);
    
    % 标注前6次泛音
    max_harmonics = min(9, length(peaks_freq));  % 最多标注6次泛音
    for i = 2:max_harmonics
        text(peaks_freq(i), peaks_amp(i), ...
            [' 泛音', num2str(i-1), ': ', num2str(round(peaks_freq(i))), 'Hz'], ...
            'Color', 'darkgreen', 'FontSize', 10);
    end
end


%% 6. 输出结果并保存数据
fprintf('\n提取结果：\n');
fprintf('基频：%.1f Hz（振幅：%.4f）\n', peaks_freq(1), peaks_amp(1));

% 显示前5次泛音
if length(peaks_freq) >= 2
    fprintf('泛音列表（前5次）：\n');
    for i = 2:min(6, length(peaks_freq))
        fprintf('  第%d次泛音：%.1f Hz（振幅：%.4f，基频倍数：%.2f）\n', ...
            i-1, peaks_freq(i), peaks_amp(i), peaks_freq(i)/peaks_freq(1));
    end
end
