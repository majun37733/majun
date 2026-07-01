%% 多目标物品自动计数与位置标注系统
%  功能：自动检测图像中的多个物品，计数并标注位置
%  环境：MATLAB R2020a+ (需要 Image Processing Toolbox)
%  作者：课程大作业
%  日期：2025

clear; clc; close all;

%% ==================== 参数配置 ====================
imgPath = 'data/test_image.jpg';   % 输入图像路径
gaussianKernelSize = 15;           % 高斯滤波核大小
gaussianSigma = 5.0;               % 高斯滤波标准差
minArea = 3000;                    % 最小目标面积
maxArea = 200000;                  % 最大目标面积
morphOpenIter = 2;                 % 开运算迭代次数
morphCloseIter = 3;                % 闭运算迭代次数

%% ==================== 1. 图像读取与灰度化 ====================
fprintf('=== 多目标物品自动计数与位置标注系统 ===\n\n');

imgOriginal = imread(imgPath);
[rows, cols, channels] = size(imgOriginal);

if channels == 3
    imgGray = rgb2gray(imgOriginal);
else
    imgGray = imgOriginal;
end
fprintf('[1] 图像读取完成，尺寸: %d x %d\n', rows, cols);

%% ==================== 2. 高斯滤波降噪 ====================
imgFiltered = imgaussfilt(imgGray, gaussianSigma, ...
    'FilterSize', gaussianKernelSize);
fprintf('[2] 高斯滤波完成\n');

%% ==================== 3. Otsu阈值二值化 ====================
threshold = graythresh(imgFiltered);
imgBW = imbinarize(imgFiltered, threshold);
imgBW = ~imgBW;  % 反转使目标为白色
fprintf('[3] Otsu二值化完成，阈值: %.2f\n', threshold);

%% ==================== 4. 形态学处理 ====================
se = strel('disk', 7);

% 开运算去除噪声
for i = 1:morphOpenIter
    imgBW = imopen(imgBW, se);
end

% 闭运算填充空洞
for i = 1:morphCloseIter
    imgBW = imclose(imgBW, se);
end

% 填充孔洞
imgBW = imfill(imgBW, 'holes');
fprintf('[4] 形态学处理完成\n');

%% ==================== 5. 连通域分析 ====================
[labeled, numObjects] = bwlabel(imgBW);
stats = regionprops(labeled, 'Area', 'Centroid', 'BoundingBox');

validIdx = [];
for i = 1:numObjects
    if stats(i).Area >= minArea && stats(i).Area <= maxArea
        validIdx = [validIdx, i];
    end
end
finalCount = length(validIdx);
fprintf('[5] 检测到 %d 个目标\n', finalCount);

%% ==================== 6. 结果标注与可视化 ====================
figure('Position', [100, 100, 1200, 800]);
imshow(imgOriginal);
hold on;

colors = lines(finalCount);

for k = 1:finalCount
    idx = validIdx(k);
    bb = stats(idx).BoundingBox;
    centroid = stats(idx).Centroid;
    
    % 绘制边界框
    rectangle('Position', bb, 'EdgeColor', colors(k,:), ...
        'LineWidth', 2.5);
    
    % 标注编号和坐标
    labelStr = sprintf('#%d (%.0f,%.0f)', k, centroid(1), centroid(2));
    text(bb(1), bb(2)-10, labelStr, 'Color', colors(k,:), ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0 0 0 0.6]);
    
    % 标记中心点
    plot(centroid(1), centroid(2), 'r+', 'MarkerSize', 12, ...
        'LineWidth', 2);
end

title(sprintf('检测结果: %d 个目标', finalCount), 'FontSize', 14);
hold off;
saveas(gcf, 'results/result_labeled.png');

%% ==================== 7. 处理流程对比图 ====================
figure('Position', [100, 100, 1400, 400]);

subplot(1, 4, 1);
imshow(imgOriginal);
title('原始图像');

subplot(1, 4, 2);
imshow(imgGray);
title('灰度图');

subplot(1, 4, 3);
imshow(imgBW);
title('二值化结果');

subplot(1, 4, 4);
imshow(imgOriginal);
hold on;
for k = 1:finalCount
    idx = validIdx(k);
    bb = stats(idx).BoundingBox;
    rectangle('Position', bb, 'EdgeColor', colors(k,:), 'LineWidth', 2);
end
title(sprintf('检测结果 (%d个)', finalCount));
hold off;

saveas(gcf, 'results/process_comparison.png');

%% ==================== 8. 输出检测报告 ====================
fprintf('\n=== 检测报告 ===\n');
fprintf('%-6s %-12s %-12s %-10s\n', '编号', 'X坐标', 'Y坐标', '面积');
fprintf('%s\n', repmat('-', 1, 42));

for k = 1:finalCount
    idx = validIdx(k);
    c = stats(idx).Centroid;
    fprintf('%-6d %-12.1f %-12.1f %-10d\n', ...
        k, c(1), c(2), stats(idx).Area);
end

fprintf('\n=== 处理完成，结果已保存至 results/ ===\n');
