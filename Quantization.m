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
    pixelsSorted = sortrows(pixels); % Sort pixels
    numPixels = size(pixelsSorted, 1);
    uniqueCount = 0;
    for i = 2:numPixels
        if ~isequal(pixelsSorted(i, :), pixelsSorted(i-1, :))
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

test1();
