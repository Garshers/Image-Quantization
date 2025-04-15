function [elapsedTime, uniqueCount] = countUniqueColors(filename, pathname, mode)

    % Construct the full file path and read img
    fullFilePath = fullfile(pathname, filename);
    imageRGB = imread(fullFilePath);

    % Check if the image is RGB
    if size(imageRGB, 3) ~= 3
        error('Image must be an RGB image.');
    end

    %checking mode, conuting colors
    if strcmp(mode, 'HSV')
        image = rgb2hsv(imageRGB);
        tic;% -------------------------------Start timer--------------
        uniqueCount = uniqueColorCounterHSV(image);
        elapsedTime = toc * 1000; % ----------Stop timer-----------
        imageToSave = hsv2rgb(image); % Convert back to RGB
        
    elseif strcmp(mode, 'RGB')
        image = imageRGB;
        tic;% -------------------------------Start timer--------------
        uniqueCount = uniqueColorCounterRGB(image);
        elapsedTime = toc * 1000; % ----------Stop timer-----------
        imageToSave = imageRGB; % Keep RGB
    else
        error('Invalid mode. Use "RGB" or "HSV".');
    end

    prefix = ['_', mode];
    [pathstr, name, ext] = fileparts(fullFilePath);
    saveFilename = fullfile(pathstr, [name, prefix, ext]);
    imwrite(imageToSave, saveFilename);
end

function uniqueCount = uniqueColorCounterRGB(image)
    % Reshape the image into a list of pixels (each row is [R G B])
    pixels = reshape(image, [], 3);
    numPixels = size(pixels, 1);

    maxColorValue = 256;
    colorSpaceSize = (maxColorValue)^3;% Total size of the RGB color space
    seenColors = false(colorSpaceSize, 1); % Create a boolean array to keep track of seen colors
    
    uniqueCount = 0; % Unique color count
    
    % Iterate through each pixel
    for i = 1:numPixels
        r = pixels(i, 1);
        g = pixels(i, 2);
        b = pixels(i, 3);
        
        % Calculate a unique index for the RGB color
        colorIndex = uint32(r) * maxColorValue^2 + uint32(g) * maxColorValue + uint32(b) + 1;
        
        % If color has not been seen before
        if ~seenColors(colorIndex)
            % Mark this color as seen
            seenColors(colorIndex) = true;
            uniqueCount = uniqueCount + 1;
        end
    end
end

function uniqueCount = uniqueColorCounterHSV(image)
    % Reshape the image into a list of pixels (each row is [H S V])
    pixels = reshape(image, [], 3);
    numPixels = size(pixels, 1);
    
    % Create a map to store seen HSV colors (key: string representation, value: logical true)
    seenColorsHSV = containers.Map('KeyType', 'char', ...
                                    'ValueType', 'logical');

    uniqueCount = 0; % Unique color count
    
    % Iterate through each pixel in the HSV image
    for i = 1:numPixels
        H = pixels(i, 1);
        S = pixels(i, 2);
        V = pixels(i, 3);
        
        % Round the HSV values to a .6 precision and convert them to strings
        hueKey = sprintf('%.6f', H);
        saturationKey = sprintf('%.6f', S);
        valueKey = sprintf('%.6f', V);
        
        % Create a unique key string by concatenating the rounded HSV values
        colorKey = [hueKey, '-', saturationKey, '-', valueKey];
        
        % If color has not been seen before
        if ~isKey(seenColorsHSV, colorKey)
            % Mark this color as seen
            seenColorsHSV(colorKey) = true;
            uniqueCount = uniqueCount + 1;
        end
    end
end

function test1()
    timeSumRGB = 0;
    timeSumHSV = 0;
    n = 1;
    [filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files (*.jpg, *.png)'}, 'Select an RGB Image');
    if isequal(filename, 0)
        disp('User canceled file selection.');
        return;
    end
    for i = 1:n
        [elapsedTime1, uniqueCount1] = countUniqueColors(filename, pathname, 'RGB');
        timeSumRGB = timeSumRGB + elapsedTime1;
        [elapsedTime2, uniqueCount2] = countUniqueColors(filename, pathname, 'HSV');
        timeSumHSV = timeSumHSV + elapsedTime2;
    end
    avgTimeRGB = timeSumRGB / n;
    avgTimeHSV = timeSumHSV / n;
    
    fprintf('Number of unique colors for "%s" (RGB): %d\n', filename, uniqueCount1);
    fprintf('Elapsed time (RGB): %.6f ms\n', avgTimeRGB);
    fprintf('Number of unique colors for "%s" (HSV): %d\n', filename, uniqueCount2);
    fprintf('Elapsed time (HSV): %.6f ms\n', avgTimeHSV);

    % Conversion test for O1
    image = imread(fullfile(pathname, filename));
    O1RGB = hsv2rgb(rgb2hsv(image));
    O1 = image;

    % Convert both images to double for PSNR calculation
    O1RGB = double(O1RGB);
    O1 = double(O1);

    % Display difference between O1RGB and O1
    if isequal(O1RGB, O1)
        disp('O1RGB and O1RGB are identical.');
    else
        psnrValue = psnr(O1, O1RGB);
        ssimValue = ssim(O1RGB, O1);
        fprintf('PSNR between O1RGB and O1: %.2f dB\n', psnrValue);
        fprintf('SSIM between O1RGB and O1: %.4f\n', ssimValue);
    end
end

function quantizeImage(filename, pathname, divisions, mode)
    % Load the image
    fullFilePath = fullfile(pathname, filename);
    image = imread(fullFilePath);

    if strcmp(mode, 'HSV')
        imageHSV = rgb2hsv(image);
        quantizedHSV = quantizeHSV(imageHSV, divisions);
        quantizedImage = hsv2rgb(quantizedHSV);
        quantizedImage = uint8(round(quantizedImage * 255));
        numUniqueColors = uniqueColorCounterHSV(quantizedImage);
    elseif strcmp(mode, 'RGB')
        quantizedImage = quantizeRGB(image, divisions);
        numUniqueColors = uniqueColorCounterRGB(quantizedImage);
    else
        error('Invalid mode. Use "RGB" or "HSV".');
    end    

    % Calculate PSNR
    psnrValue = psnr(quantizedImage, image);

    % Display results
    fprintf('\nDivisions: %dx%dx%d\n', divisions(1), divisions(2), divisions(3));
    fprintf('PSNR: %.2f dB\n', psnrValue);
    fprintf('Number of unique colors: %d\n', numUniqueColors);

    % Save the quantized image
    [pathstr, name, ext] = fileparts(fullFilePath);
    saveFilename = fullfile(pathstr, [name, '_', mode, '_quantized_', num2str(divisions(1)), 'x', num2str(divisions(2)), 'x', num2str(divisions(3)), ext]);
    imwrite(quantizedImage, saveFilename);
end

function quantizedImage = quantizeRGB(imageRGB, divisions)
    quantizedImage = imageRGB;

    for channel = 1:3
        % Calculate quantization levels
        levels = round(linspace(0, 255, divisions(channel)));
        
        % Shifting to round to the nearest
        shiftedImage = imageRGB(:, :, channel) - (levels(2) - levels(1)) / 2;
        
        % Quantize the channel and convert indices to color values directly
        % (:, :, channel) means "take all rows, all columns, and only the specified channel." 
        quantizedImage(:, :, channel) = levels(imquantize(shiftedImage, levels));
    end
end

function quantizedHSV = quantizeHSV(imageHSV, divisions)
    quantizedHSV = imageHSV;
    height = size(imageHSV, 1);
    width = size(imageHSV, 2);

    for i = 1:height
        for j = 1:width
            % Quantize Hue (cyclic)
            hueLevels = linspace(0, 1, divisions(1) + 1); % divisions + 1 levels to create 'divisions' bins
            [~, h_idx] = min(abs(imageHSV(i, j, 1) - hueLevels(1:end-1)));
            quantizedHSV(i, j, 1) = hueLevels(h_idx);

            % Quantize Saturation
            satLevels = linspace(0, 1, divisions(2));
            [~, s_idx] = min(abs(imageHSV(i, j, 2) - satLevels));
            quantizedHSV(i, j, 2) = satLevels(s_idx);

            % Quantize Value
            valLevels = linspace(0, 1, divisions(3));
            [~, v_idx] = min(abs(imageHSV(i, j, 3) - valLevels));
            quantizedHSV(i, j, 3) = valLevels(v_idx);

            % Handle achromatic colors: force Saturation to 0
            if imageHSV(i, j, 2) == 0
                quantizedHSV(i, j, 2) = 0;
            end
        end
    end
end

function testQuantization()
    % Test the quantization functions
    [filename, pathname] = uigetfile({'*.jpg;*.png', 'Image Files (*.jpg, *.png)'}, 'Select an RGB Image');
    if isequal(filename, 0)
        disp('User canceled file selection.');
        return;
    end

    divisionsList = {[2, 2, 2], [4, 4, 4], [4, 8, 4], [8, 8, 4]};
    for i = 1:length(divisionsList)
        quantizeImage(filename, pathname, divisionsList{i}, 'RGB');
    end

    divisionsList = {[2, 2, 2], [4, 4, 4], [4, 8, 4], [10, 5, 5]};
    for i = 1:length(divisionsList)
        quantizeImage(filename, pathname, divisionsList{i}, 'HSV');
    end
end

test1();
%testQuantization();