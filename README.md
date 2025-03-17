# Image Color Analysis and Quantization

This MATLAB script provides functionalities to analyze and quantize image colors in both RGB and HSV color spaces.

## Functions

### `countUniqueColors(filename, pathname, mode)`

Counts the number of unique colors in an image and measures the elapsed time for the counting process.

### `uniqueColorCounter(image)`

A helper function that counts the unique colors within an image matrix.

### `quantizeImage(filename, pathname, divisions, mode)`

Quantizes an image based on specified divisions in either RGB or HSV color space and calculates the Peak Signal-to-Noise Ratio (PSNR).

### `quantizeRGB(imageRGB, divisions)`

Quantizes an RGB image according to the specified divisions for each color channel.

### `quantizeHSV(imageHSV, divisions)`

Quantizes an HSV image based on the provided divisions for each channel.

### `test1()`

Tests the `countUniqueColors` function and calculates the average elapsed time for both RGB and HSV modes. It also tests the conversion between RGB and HSV to verify conversion accuracy using PSNR and Structural Similarity Index Measure (SSIM).

### `testQuantization()`

Tests the `quantizeImage` function with various division configurations for both RGB and HSV color spaces.

## Usage

1.  Place the MATLAB script in your desired directory.
2.  Run the script in MATLAB.
3.  The `test1()` and `testQuantization()` functions will automatically execute, prompting you to select an image file.
4.  The results will be displayed in the MATLAB command window, and quantized images will be saved in the same directory as the original image.
