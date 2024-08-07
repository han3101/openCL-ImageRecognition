#pragma once
#include <stdint.h>
#include <cstdio>
#include <complex>
#include <iostream>
#include <vector>
#include <memory>
#include <omp.h>
#include "masks.h"


//legacy feature of C
#undef __STRICT_ANSI__
#define _USE_MATH_DEFINES 
#include <cmath>
#ifndef M_PI
	#define M_PI (3.14159265358979323846)
#endif

enum ImageType {
	PNG, JPG, BMP, JPEG
};


class Image {

public:
	uint8_t* data = NULL;
	size_t size = 0;
	int w;
	int h;
	int channels;

	// For obj detection
	std::unique_ptr<uint32_t[]> integralImage = nullptr;
	std::unique_ptr<uint32_t[]> integralImageSquare = nullptr;
	std::unique_ptr<uint32_t[]> integralImageSobel = nullptr;
	std::unique_ptr<uint32_t[]> integralImageTilt = nullptr;

	Image(const char* filename, int channel_force = 0);
	Image(int w, int h, int channels = 3);
	Image(const Image& img);
	~Image();

	bool write(const char* filename);

private:

	bool read(const char* filename, int channel_force = 0);

	void mask_calc(double* mask, double filter_factor, int w, int h) {
		for (int i = 0; i < w*h; ++i) {
			mask[i] = mask[i] / filter_factor;
		}
	}

	uint8_t computeLBP(int col, int row) {
		int centerIndex = row * w + col;
		uint8_t center = data[centerIndex];
		uint8_t lbp = 0;
		lbp |= (data[(row-1) * w + (col-1)] >= center) << 7;
		lbp |= (data[(row-1) * w + (col)] >= center) << 6;
		lbp |= (data[(row-1) * w + (col+1)] >= center) << 5;
		lbp |= (data[(row) * w + (col+1)] >= center) << 4;
		lbp |= (data[(row+1) * w + (col+1)] >= center) << 3;
		lbp |= (data[(row+1) * w + (col)] >= center) << 2;
		lbp |= (data[(row+1) * w + (col-1)] >= center) << 1;
		lbp |= (data[(row) * w + (col-1)] >= center) << 0;
		return lbp;
	}
	

public:
	ImageType get_file_type(const char* filename);

	Image& grayscale_avg_cpu();
	Image& grayscale_cpu();
	Image& grayscale_lum_cpu();

	Image& diffmap_cpu(Image& img);
	Image& diffmap_scale_cpu(Image& img, uint8_t scl = 0);

	Image& flipX_cpu();
	Image& flipY_cpu();

	Image& std_convolve_clamp_to_0_cpu(uint8_t channel, const Mask::BaseMask* mask);
	Image& std_convolve_clamp_to_border_cpu(uint8_t channel, const Mask::BaseMask* mask);
	
	Image& crop(uint16_t cx, uint16_t cy, uint16_t cw, uint16_t ch);
	Image& resizeNN(uint16_t nw, uint16_t nh);
	Image& resizeBilinear_cpu(uint16_t nw, uint16_t nh);

	Image& local_binary_pattern_cpu();

	void integralImage_cpu(std::unique_ptr<u_int32_t[]>& integralImage, std::unique_ptr<u_int32_t[]>& integralImageSobel, std::unique_ptr<u_int32_t[]>& integralImageSquare, std::unique_ptr<u_int32_t[]>& integralImageTilt);

	void integralImage_cpu() {
		if (integralImage == nullptr) {
			integralImage = std::make_unique<uint32_t[]>(w * h);
			integralImageSquare = std::make_unique<uint32_t[]>(w * h);
			integralImageTilt = std::make_unique<uint32_t[]>(w * h);
		}
		this->integralImage_cpu(integralImage, integralImageSobel, integralImageSquare, integralImageTilt);
	}

	void integralImage_mp(std::unique_ptr<u_int32_t[]>& integralImage, std::unique_ptr<u_int32_t[]>& integralImageSobel, std::unique_ptr<u_int32_t[]>& integralImageSquare, std::unique_ptr<u_int32_t[]>& integralImageTilt);
	void integralImage_mp() {
		if (integralImage == nullptr) {
			integralImage = std::make_unique<uint32_t[]>(w * h);
			integralImageSquare = std::make_unique<uint32_t[]>(w * h);
			integralImageTilt = std::make_unique<uint32_t[]>(w * h);
		}
		this->integralImage_mp(integralImage, integralImageSobel, integralImageSquare, integralImageTilt);
	}

};
