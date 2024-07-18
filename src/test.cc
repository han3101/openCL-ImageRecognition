#include <gtest/gtest.h>

#include "image.h"
#include "opencl_image.h"
#include "masks.h"
#include <cstdlib>
#include <iostream>
#include <memory>

int is_image_black(const Image& img) {
    int isBlack = 1;

    #pragma omp parallel for num_threads(4) shared(isBlack)
    for (int i = 0; i < img.size; ++i) {
        if (img.data[i] > 5) {
            #pragma omp critical
            {
                isBlack = 0;
                // std::cout<<"Pixel: "<<i<<" has value "<<(int)img.data[i]<<"\n";
            }
        }
    }

    return isBlack;
}

int is_image_black_single(const Image& img) {
    for (int i = 0; i < img.size; ++i) {
        if (img.data[i] > 5) {
            {
                return 0;
            }
        }
    }

    return 1;
}

// Demonstrate some basic assertions.
TEST(HelloTest, BasicAssertions) {
  // Expect two strings not to be equal.
  EXPECT_STRNE("hello", "world");
  // Expect equality.
  EXPECT_EQ(7 * 6, 42);
}

TEST(ImageTest, BasicDiffTest) {

    Image testHD("imgs/testHD.jpeg");

    ASSERT_NE(testHD.data, nullptr) << "Failed to load image.";


    OpenCLImageProcessor processor;

    processor.diffmap(testHD, testHD);

    auto start = std::chrono::high_resolution_clock::now();

    int is_black = is_image_black(testHD);

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = end - start;
    std::cout << "Time taken for computation: " << elapsed.count() * 1000 << " ms" << std::endl;


    EXPECT_EQ(is_black, 1);
}

TEST(ImageTest, 2DDynamicGaus3) {

    Image testHD("imgs/cat.jpeg");
    Image target("imgs/tests/2Dgaus3cat.jpeg");

    ASSERT_NE(testHD.data, nullptr) << "Failed to load test image.";
    ASSERT_NE(target.data, nullptr) << "Failed to load target image.";

    Mask::GaussianDynamic2D gaussianBlur((int) 1);

    OpenCLImageProcessor processor;
    processor.std_convolve_clamp_to_border(testHD, &gaussianBlur);

    processor.diffmap(testHD, target);

    auto start = std::chrono::high_resolution_clock::now();

    int is_black = is_image_black(testHD);

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = end - start;
    std::cout << "Time taken for computation: " << elapsed.count() * 1000 << " ms" << std::endl;


    EXPECT_EQ(is_black, 1);
}

// TEST(ImageTest, 1DDynamicGaus3_cpu) {

//     Image testHD("imgs/cat.jpeg");
//     Image target("imgs/tests/2Dgaus3cat.jpeg");

//     ASSERT_NE(testHD.data, nullptr) << "Failed to load test image.";
//     ASSERT_NE(target.data, nullptr) << "Failed to load target image.";

//     Mask::GaussianDynamic1D gaussianBlur1(1, false);
//     Mask::GaussianDynamic1D gaussianBlur2(1, true);

//     auto start = std::chrono::high_resolution_clock::now();

//     testHD.std_convolve_clamp_to_border_cpu(0, &gaussianBlur1);
//     testHD.std_convolve_clamp_to_border_cpu(1, &gaussianBlur1);
//     testHD.std_convolve_clamp_to_border_cpu(2, &gaussianBlur1);

//     testHD.std_convolve_clamp_to_border_cpu(0, &gaussianBlur2);
//     testHD.std_convolve_clamp_to_border_cpu(1, &gaussianBlur2);
//     testHD.std_convolve_clamp_to_border_cpu(2, &gaussianBlur2);

//     auto end = std::chrono::high_resolution_clock::now();
//     std::chrono::duration<double> elapsed = end - start;
//     std::cout << "Time taken for computation: " << elapsed.count() * 1000 << " ms" << std::endl;

//     OpenCLImageProcessor processor;

//     processor.diffmap(testHD, target);
//     // auto start = std::chrono::high_resolution_clock::now();

//     int is_black = is_image_black(testHD);

//     // auto end = std::chrono::high_resolution_clock::now();
//     // std::chrono::duration<double> elapsed = end - start;
//     // std::cout << "Time taken for computation: " << elapsed.count() * 1000 << " ms" << std::endl;


//     EXPECT_EQ(is_black, 1);
// }

TEST(ImageTest, 1DDynamicGaus3Clamp0) {

    Image testHD("imgs/cat.jpeg");
    Image target("imgs/tests/2Dgaus3cat0.jpeg");

    ASSERT_NE(testHD.data, nullptr) << "Failed to load test image.";
    ASSERT_NE(target.data, nullptr) << "Failed to load target image.";

    Mask::GaussianDynamic1D gaussianBlur1(1, false);
    Mask::GaussianDynamic1D gaussianBlur2(1, true);

    OpenCLImageProcessor processor;

    processor.std_convolve_clamp_to_0(testHD, &gaussianBlur1);
    processor.std_convolve_clamp_to_0(testHD, &gaussianBlur2);
    processor.diffmap(testHD, target);
    // auto start = std::chrono::high_resolution_clock::now();

    int is_black = is_image_black(testHD);

    // auto end = std::chrono::high_resolution_clock::now();
    // std::chrono::duration<double> elapsed = end - start;
    // std::cout << "Time taken for computation: " << elapsed.count() * 1000 << " ms" << std::endl;


    EXPECT_EQ(is_black, 1);
}

TEST(ImageTest, 1DDynamicGaus3Clampborder) {

    Image testHD("imgs/cat.jpeg");
    Image target("imgs/tests/2Dgaus3cat.jpeg");

    ASSERT_NE(testHD.data, nullptr) << "Failed to load test image.";
    ASSERT_NE(target.data, nullptr) << "Failed to load target image.";

    Mask::GaussianDynamic1D gaussianBlur1(1, false);
    Mask::GaussianDynamic1D gaussianBlur2(1, true);

    OpenCLImageProcessor processor;

    processor.std_convolve_clamp_to_border(testHD, &gaussianBlur1);
    processor.std_convolve_clamp_to_border(testHD, &gaussianBlur2);
    processor.diffmap(testHD, target);
    // auto start = std::chrono::high_resolution_clock::now();

    int is_black = is_image_black(testHD);

    // auto end = std::chrono::high_resolution_clock::now();
    // std::chrono::duration<double> elapsed = end - start;
    // std::cout << "Time taken for computation: " << elapsed.count() * 1000 << " ms" << std::endl;


    EXPECT_EQ(is_black, 1);
}

TEST(ImageTest, local_binary_pattern) {

    Image testHD("imgs/cat.jpeg");

    ASSERT_NE(testHD.data, nullptr) << "Failed to load test image.";

    Image cpu = testHD;

    testHD.local_binary_pattern_cpu();

    OpenCLImageProcessor processor;

    processor.local_binary_pattern(cpu);
    processor.diffmap(testHD, cpu);
    // auto start = std::chrono::high_resolution_clock::now();

    int is_black = is_image_black(testHD);

    // auto end = std::chrono::high_resolution_clock::now();
    // std::chrono::duration<double> elapsed = end - start;
    // std::cout << "Time taken for computation: " << elapsed.count() * 1000 << " ms" << std::endl;


    EXPECT_EQ(is_black, 1);
}

TEST(ImageTest, simpleIntegralcpu) {

    // Create a simple 3x3 test image
    std::vector<int> pixels = {
        1, 2, 3,
        4, 5, 6,
        7, 8, 9
    };

    std::vector<int> rotated_pixels = {
        1, 2, 3,
        7, 11, 11,
        21, 29, 23
    };

    Image test(3, 3, 1);

    for (int i=0; i < 9; i++) {
        test.data[i] = pixels[i];
    }

    ASSERT_NE(test.data, nullptr) << "Failed to load test image.";

    std::unique_ptr<u_int32_t[]> integralImage(new uint32_t[3 * 3]);
    std::fill(integralImage.get(), integralImage.get() + 3 * 3, 0);
    std::unique_ptr<uint32_t[]> integralImageSobel = nullptr;
    std::unique_ptr<uint32_t[]> integralImageSquare = nullptr;
    std::unique_ptr<uint32_t[]> integralImageTilt(new uint32_t[3 * 3]);
    std::fill(integralImageTilt.get(), integralImageTilt.get() + 3 * 3, 0);

    test.integralImage_cpu(integralImage, integralImageSobel, integralImageSquare, integralImageTilt);


    EXPECT_EQ(integralImage[8], 45);

    for (int i = 0; i < 9; ++i) {
        // std::cout<<i * 3 + j<<i<<j<<"\n";
        EXPECT_EQ(integralImageTilt[i], rotated_pixels[i]);
        
    }



    std::vector<int> pixels2 = {
        1,  4,  7,  4, 1,
        4, 16, 26, 16, 4,
        7, 26, 41, 26, 7,
        4, 16, 26, 16, 4,
        1,  4,  7,  4, 1
    };

    Image test2(5, 5, 1);

    for (int i=0; i < 25; i++) {
        test2.data[i] = pixels2[i];
    }

    std::unique_ptr<u_int32_t[]> integralImage2(new uint32_t[5 * 5]);
    std::fill(integralImage2.get(), integralImage2.get() + 5 * 5, 0);
    integralImageSobel = nullptr;
    integralImageSquare = nullptr;
    integralImageTilt = nullptr;

    test2.integralImage_cpu(integralImage2, integralImageSobel, integralImageSquare, integralImageTilt);


    EXPECT_EQ(integralImage2[24], 273);
}