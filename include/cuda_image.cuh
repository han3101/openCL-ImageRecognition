#pragma once

#include "image.h"
// #include "cuda_kernels.cuh"
#include <cuda_runtime.h>
#include <stdint.h>

class CUDAImageProcessor
{
public:
    CUDAImageProcessor();
    ~CUDAImageProcessor();

    void grayscale_avg(Image &image);
    void grayscale_lum(Image &image);

    void flipX(Image &image);
    void flipY(Image &image);
    void flipYvector(Image &image);

    void resizeBilinear(Image& image, int nw, int nh);

    void std_convolve_clamp_to_0(Image &image, const Mask::BaseMask *mask);
    void std_convolve_clamp_to_border(Image &image, const Mask::BaseMask *mask);

    void integralImage(Image& image, std::unique_ptr<u_int32_t[]>& integralImage, std::unique_ptr<u_int32_t[]>& integralImageSquare, std::unique_ptr<u_int32_t[]>& integralImageTilt);
    void evalStages(Image& image, std::vector<double>& haar, std::vector<int>& results, std::unique_ptr<u_int32_t[]>& integralImage, std::unique_ptr<u_int32_t[]>& integralImageSquare, std::unique_ptr<u_int32_t[]>& integralImageTilt, int blockWidth, int blockHeight, float scale, float inverseArea, int step);

private:
    int THREADS = 32;

    void checkCudaError(cudaError_t err, const char *msg) {
        if (err != cudaSuccess) {
            std::cerr << msg << " Error: " << cudaGetErrorString(err) << std::endl;
            exit(EXIT_FAILURE);
        }
    }
};


__global__ void grayscale_avg_cu(const unsigned char *data, unsigned char *output, int channels);

__global__ void grayscale_lum_cu(const unsigned char *data, unsigned char *output, int channels);

__global__ void flipX_cu(unsigned char *data, int w, int h, int channels);

__global__ void flipY_cu(unsigned char *data, int w, int h, int channels);

__global__ void flipYvector_cu(uchar3 *data, int w, int h);

__global__ void resize_bilinear_cu(unsigned char *data, unsigned char *output, int nw, int nh, int w, int h, int channels, float scaleX, float scaleY);

// Only can handle 3x3 or 5x5 filter masks
// __constant__ double mask3[3 * 3];
// __constant__ double mask5[5 * 5];
__global__ void convolve_0_cu(unsigned char *data, unsigned char *result, int w, int h, int channels, int mask_dim, int mask_offset, const int TILE_SIZE, double *mask);

__global__ void integralImage_cu(unsigned char *data, u_int32_t *integralImage, u_int32_t *integralImageSquare, u_int32_t *integralImageTilt, int width, int height);

__global__ void evalStages_cu(double* haar, int* result, u_int32_t *integralImage, u_int32_t *integralImageSquare, u_int32_t *integralImageTilt, int haar_size, int width, int height, int block_w, int block_h, float scale, float inverseArea, int step);

