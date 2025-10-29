clear; clc; close all;

%% 基础参数设置
fs = 44100;          % 采样率（Hz）
duration = 4;        % 音频时长（秒）
t = 0:1/fs:duration; % 时间轴（0.1秒）

%% 1. 合成纯音(正弦波，440Hz-A4-la标准音）
f1 = 440;                   % A4音对应频率(Hz)
pure_tone = sin(2*pi*f1*t); % 生成正弦波

% 导出纯音
audiowrite('pure_tone_A4.wav', pure_tone, fs);
fprintf('纯音已导出：pure_tone_A4.wav\n');

%% 2. 合成带泛音的钢琴音色(依旧以A4为例，基频440Hz)
f0 = 440;  % A4基频（Hz）

% 泛音频率(基频的2-6倍)
harmonics_freq = f0 * [2, 3, 4, 5, 6];

% 泛音振幅(通过piano_anas.m当中几个显著泛音的相对响应强度得到)
harmonics_amp = [0.62, 0.18, 0.1, 0.09, 0.05];

% 叠加基频和泛音
piano_tone = sin(2*pi*f0*t);                                                    % 叠加基频
for i = 1:length(harmonics_freq)
    piano_tone = piano_tone + harmonics_amp(i) * sin(2*pi*harmonics_freq(i)*t); % 依次叠加泛音
end

% 归一化振幅（避免过载失真）
piano_tone = piano_tone / max(abs(piano_tone));

% 导出钢琴音色
audiowrite('piano_tone_A4.wav', piano_tone, fs);
fprintf('钢琴音色已导出：piano_tone_A4.wav\n');


%% 3. 合成A4音对应的大三和弦A4（根音）、C♯5（三音）、E5（五音）
f_c = 440;     % A4
f_e = 554.37;  % C♯5
f_g = 659.25;  % E5

% 合成和弦（叠加三个音）
chord = 0.5*sin(2*pi*f_c*t) + 0.3*sin(2*pi*f_e*t) + 0.2*sin(2*pi*f_g*t);
chord = chord / max(abs(chord));  % 归一化

% 导出和弦
audiowrite('major_chord_A4.wav', chord, fs);
fprintf('大三和弦已导出：major_chord_A4.wav\n');


%% 4. 合成带ADSR包络的钢琴音（复刻真实音色）
% ADSR包络参数（起音-衰减-持续-释音）
attack = 0.05;   % 起音时间（秒）
decay = 0.2;     % 衰减时间（秒）
sustain_level = 0.6;  % 持续段振幅比例
release = 1.0;   % 释音时间（秒）

% 生成ADSR包络
envelope = zeros(size(t));

% 1.起音阶段（0到attack）
attack_idx = t <= attack;
envelope(attack_idx) = t(attack_idx) / attack;

% 2.衰减阶段（attack到attack+decay）
decay_idx = t > attack & t <= (attack+decay);
envelope(decay_idx) = 1 - (1 - sustain_level) * (t(decay_idx)-attack)/decay;

% 3.持续阶段（attack+decay到duration-release）
sustain_idx = t > (attack+decay) & t <= (duration-release);
envelope(sustain_idx) = sustain_level;

% 4.释音阶段（duration-release到duration）
release_idx = t > (duration-release) & t <= duration;
envelope(release_idx) = sustain_level * (1 - (t(release_idx)-(duration-release))/release);

% 用包络调制钢琴音色
piano_adsr = piano_tone .* envelope;
piano_adsr = piano_adsr / max(abs(piano_adsr));

% 导出带包络的钢琴音
audiowrite('piano_adsr_A4.wav', piano_adsr, fs);
fprintf('带ADSR包络的钢琴音已导出：piano_adsr_A4.wav\n');


%% 可视化波形（四张分立波形图）
figure;
subplot(2,2,1); plot(t, pure_tone); title('纯音波形（A4）'); xlabel('时间（s）');
subplot(2,2,2); plot(t, piano_tone); title('钢琴音色波形（A4）'); xlabel('时间（s）');
subplot(2,2,3); plot(t, chord); title('A4大三和弦波形'); xlabel('时间（s）');
subplot(2,2,4); plot(t, piano_adsr); title('带ADSR包络的钢琴音'); xlabel('时间（s）');

%{
%% 生成四张独立的波形图（替代子图）
% 1. 纯音波形（A4）
figure('Name', '纯音波形（A4）', 'Position', [100, 100, 800, 500]);
plot(t, pure_tone, 'b');
title('纯音波形（A4）', 'FontSize', 14); xlabel('时间（s）', 'FontSize', 12); ylabel('振幅', 'FontSize', 12); grid on;
xlim([0, duration]);  % 限制时间范围与音频时长一致

% 2. 钢琴音色波形（A4）
figure('Name', '钢琴音色波形（A4）', 'Position', [200, 200, 800, 500]);
plot(t, piano_tone, 'r');
title('钢琴音色波形（A4）', 'FontSize', 14); xlabel('时间（s）', 'FontSize', 12); ylabel('振幅', 'FontSize', 12); grid on;
xlim([0, duration]);

% 3. A4大三和弦波形
figure('Name', 'A4大三和弦波形', 'Position', [300, 300, 800, 500]);
plot(t, chord, 'g');
title('A4大三和弦波形', 'FontSize', 14); xlabel('时间（s）', 'FontSize', 12); ylabel('振幅', 'FontSize', 12); grid on;
xlim([0, duration]);

% 4. 带ADSR包络的钢琴音波形
figure('Name', '带ADSR包络的钢琴音', 'Position', [400, 400, 800, 500]); 
plot(t, piano_adsr, 'm'); title('带ADSR包络的钢琴音', 'FontSize', 14); xlabel('时间（s）', 'FontSize', 12); ylabel('振幅', 'FontSize', 12); grid on;
xlim([0, duration]);
%}


