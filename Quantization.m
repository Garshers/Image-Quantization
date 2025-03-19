function [elapsedTime, uniqueCount] = countUniqueColors(filename, pathname, mode)

    % Construct the full file path and read img
    fullFilePath = fullfile(pathname, filename);
    imageRGB = imread(fullFilePath);

    % Check if the image is RGB
    if size(imageRGB, 3) ~= 3
    error('Image must be an RGB image.');
    end
    
    % Checking mode
    if strcmp(mode, 'HSV')
        image = rgb2hsv(imageRGB);
    elseif strcmp(mode, 'RGB')
        image = imageRGB;
    else
        error('Invalid mode. Use "RGB" or "HSV".');
    end
    
    tic;% -------------------------------Start timer--------------
    uniqueCount = uniqueColorCounter(image);
    elapsedTime = toc * 1000; % ----------Stop timer-----------
    
    % Saving images
    if strcmp(mode, 'HSV')
        imageToSave = hsv2rgb(image); % Convert back to RGB
    elseif strcmp(mode, 'RGB')
        imageToSave = imageRGB; % Keep RGB
    else
        error('Invalid mode. Use "RGB" or "HSV".');
    end
    prefix = ['_', mode];
    [pathstr, name, ext] = fileparts(fullFilePath);
    saveFilename = fullfile(pathstr, [name, prefix, ext]);
    imwrite(imageToSave, saveFilename);
end

function uniqueCount = uniqueColorCounter(image)
    pixels = reshape(image, [], 3);
    pixelsSorted = sortrows(pixels); % Sort pixels red -> green -> blue
    numPixels = size(pixelsSorted, 1);
    uniqueCount = 1;
    for i = 2:numPixels
        if ~isequal(pixelsSorted(i, :), pixelsSorted(i-1, :)) % If prev is not eq curr
          uniqueCount = uniqueCount + 1;
        end
    end
end

function test1()
    timeSumRGB = 0;
    timeSumHSV = 0;
    n = 20;
    [filename, pathname] = uigetfile({'*.jpg;*.png', 'Image Files (*.jpg, *.png)'}, 'Select an RGB Image');
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
    elseif strcmp(mode, 'RGB')
        quantizedImage = quantizeRGB(image, divisions);
    else
        error('Invalid mode. Use "RGB" or "HSV".');
    end    

    % Calculate PSNR
    psnrValue = psnr(quantizedImage, image);

    % Calculate unique colors
    numUniqueColors = uniqueColorCounter(quantizedImage);

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
    % Quantize HSV image according to specified divisions
    quantizedHSV = imageHSV;

    % Quantize H, S, V channels directly using a loop
    for channel = 1:3
        levels = linspace(0, 1, divisions(channel));
        shiftedImage = imageHSV(:, :, channel) - (levels(2) - levels(1)) / 2;
        quantizedHSV(:, :, channel) = levels(imquantize(shiftedImage, levels));
    end

    % Handle achromatic colors
    achromaticIndices = find(imageHSV(:, :, 2) == 0);
    if ~isempty(achromaticIndices)
        levelsAchromatic = linspace(0, 1, 6); % 6 achromatic levels
        validIndices = achromaticIndices(achromaticIndices <= size(imageHSV, 1));
        if ~isempty(validIndices)
            quantizedHSV(validIndices, 3) = levelsAchromatic(imquantize(imageHSV(validIndices, 3), levelsAchromatic));
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

    divisionsList = {[2, 2, 2], [4, 4, 4], [4, 6, 4], [8, 8, 4]};
    for i = 1:length(divisionsList)
        quantizeImage(filename, pathname, divisionsList{i}, 'RGB');
    end

    divisionsList = {[2, 2, 2], [4, 4, 4], [4, 6, 4], [10, 5, 5]};
    for i = 1:length(divisionsList)
        quantizeImage(filename, pathname, divisionsList{i}, 'HSV');
    end
end

%test1();
testQuantization();