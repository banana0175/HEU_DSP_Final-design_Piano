clear; clc; close all;

%% 合成带泛音的钢琴音色
fs = 44100;          % 采样率（Hz）
duration = 3;        % 总时长（秒，包含完整衰减过程）
t = 0:1/fs:duration; % 时间轴

f0 = 440;  % A4基频（Hz）
harmonics_freq = f0 * [2, 3, 4, 5, 6];
harmonics_amp = [0.62, 0.18, 0.1, 0.09, 0.05];


piano_tone = sin(2*pi*f0*t);  
for i = 1:length(harmonics_freq)
    piano_tone = piano_tone + harmonics_amp(i) * sin(2*pi*harmonics_freq(i)*t);
end

%% 添加钢琴真实响度衰减包络
% 衰减参数
attack = 0.02;                         % 起音时间（20ms，琴槌击弦瞬间快速达到峰值）
decay = 0.2;                           % 衰减时间（200ms，从峰值快速降至持续响度）
sustain_level = 0.35;                  % 持续段响度（峰值的35%，A4音区典型值）
release = duration - attack - decay;   % 释放时间（剩余时长，确保总时长不变）

% 生成衰减包络
envelope = zeros(size(t));

% 起音阶段：快速上升至峰值（模拟击弦瞬间）
attack_idx = t <= attack;
envelope(attack_idx) = t(attack_idx) / attack;  % 线性上升

% 衰减阶段：从峰值降至持续响度（能量快速耗散）
decay_idx = t > attack & t <= (attack + decay);
envelope(decay_idx) = 1 - (1 - sustain_level) * (t(decay_idx) - attack) / decay;

% 释放阶段：持续衰减至0（模拟琴弦余振消失）
release_idx = t > (attack + decay);

% 用指数衰减模拟琴弦振动的能量耗散（更自然）
envelope(release_idx) = sustain_level * exp(-3*(t(release_idx) - (attack + decay))/release);

%% 应用衰减包络并归一化
piano_tone_decay = piano_tone .* envelope;  % 用包络调制响度
piano_tone_decay = piano_tone_decay / max(abs(piano_tone_decay));  % 避免失真

audiowrite('Real_A4_By_Piano_.wav', piano_tone_decay, fs);
fprintf('带真实衰减的钢琴音色已导出：piano_tone_A4_with_decay.wav\n');

% 可视化：对比原音色与带衰减的音色
figure('Position', [100, 100, 1200, 600]);
subplot(2,1,1);
plot(t, piano_tone);
title('原钢琴音色（无衰减）', 'FontSize', 12);
xlabel('时间（s）'); ylabel('振幅'); grid on;
xlim([0, duration]);

subplot(2,1,2);
plot(t, piano_tone_decay);
title('带真实衰减的钢琴音色', 'FontSize', 12);
xlabel('时间（s）'); ylabel('振幅'); grid on;
xlim([0, duration]);
