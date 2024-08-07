// #include "cuda_image.cuh"
#include "cuda_image.cuh"

/*
* For optimization use with cudaMemcpyToSymbol
* Constant image size might need to be bigger
*/
// __constant__ unsigned char image_data[1024 * 1024];

template <typename T>
__device__ T clamp(T x, T a, T b) {
    return max(a, min(x, b));
}

__global__ void grayscale_avg_cu(const unsigned char *data, unsigned char *output, int channels) {

    int id = blockIdx.x * blockDim.x + threadIdx.x;

    int pixelIndex = id * channels;

    unsigned char r = data[pixelIndex];
    unsigned char g = data[pixelIndex + 1];
    unsigned char b = data[pixelIndex + 2];

    unsigned char gray = (r + g + b) / 3;

    output[id] = gray;

} 

__global__ void grayscale_lum_cu(const unsigned char *data, unsigned char *output, int channels) {

    int id = blockIdx.x * blockDim.x + threadIdx.x;

    int pixelIndex = id * channels;

    unsigned char r = data[pixelIndex];
    unsigned char g = data[pixelIndex + 1];
    unsigned char b = data[pixelIndex + 2];

    unsigned char gray = (r * 0.299 + g * 0.5870 + 0.1140 * b);

    output[id] = gray;
} 


__global__ void flipX_cu(unsigned char *data, int w, int h, int channels) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < w / 2 && y < h) {
        int left = (x + y*w) * channels;
        int right = ((w - 1- x) + y*w) * channels;

        for (int c=0; c < channels; ++c) {
            unsigned char tmp = data[left + c];
            data[left + c] = data[right + c];
            data[right + c] = tmp;
        }
    }
}

__global__ void flipY_cu(unsigned char *data, int w, int h, int channels) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < w && y < h / 2) {
        int left = (x + y*w) * channels;
        int right = (x + (h - y + 1)*w) * channels;

        for (int c=0; c < channels; ++c) {
            unsigned char tmp = data[left + c];
            data[left + c] = data[right + c];
            data[right + c] = tmp;
        }
    }
}


__global__ void flipYvector_cu(uchar3 *data, int w, int h) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < w && y < h / 2) {
        int left = x + y * w;
        int right = (x + (h - y + 1) * w);

        uchar3 tmp = data[left];
        data[left] = data[right];
        data[right] = tmp;
    }
}

__global__ void resize_bilinear_cu(unsigned char *data, unsigned char *output, int nw, int nh, int w, int h, int channels, float scaleX, float scaleY) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    if (row < nh && col < nw) {
        float float_pos_x, float_pos_y, offset_x, offset_y;
        ushort low_x, low_y, high_x, high_y; 

        float_pos_x = col * scaleX;
        float_pos_y = row * scaleY;

        low_x = (ushort)floor(float_pos_x);
        low_y = (ushort)floor(float_pos_y);
        high_x = low_x + 1;
        high_y = low_y + 1;

        if (high_x >= w) {
            high_x = low_x;
        }
        if (high_y >= h) {
            high_y = low_y;
        }

        offset_x = float_pos_x - low_x;
        offset_y = float_pos_y - low_y;

        for (int c = 0; c < channels; ++c) {
            
            float value = (1-offset_x) * (1-offset_y) * data[(low_x + low_y * w) * channels + c] +
                        offset_x * (1-offset_y) * data[(high_x + low_y * w) * channels + c] +
                        (1-offset_x) * offset_y * data[(low_x + high_y * w) * channels + c] +
                        offset_x * offset_y * data[(high_x + high_y * w) * channels + c];

            output[(col + row * nw) * channels + c] = clamp(value, 0.0f, 255.0f);
        }


    }
}

__global__ void convolve_0_cu(unsigned char *data, unsigned char *result, int w, int h, int channels, int mask_dim, int mask_offset, const int TILE_SIZE, double *mask) {

    // __shared__ unsigned char tile[TILE_SIZE + mask_dim - 1][TILE_SIZE + mask_dim - 1];

    // const double* mask = (mask_dim == 3) ? mask3 : mask5;

    // int row = blockIdx.y * TILE_SIZE + threadIdx.y;
    // int col = blockIdx.x * TILE_SIZE + threadIdx.x;

    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    // printf("row: %f, col: %f\n", mask3[0],  mask3[1]);

    for (int ch = 0; ch < channels; ch++) {
        int start_r = row - mask_offset;
        int start_c = col - mask_offset;

        // Load the data into shared memory with boundary check
        // if (start_r >= 0 && start_r < w*h && start_c >= 0 && start_c < w*h) {
        //     tile[threadIdx.y][threadIdx.x] = data[start_r * w*h + start_c];
        // } else {
        //     tile[threadIdx.y][threadIdx.x] = 0;
        // }

        float temp = 0;

        for (int i = 0; i < mask_dim; i++) {
            for (int j = 0; j < mask_dim; ++j) {
                if ((start_r + i) >= 0 && (start_r + i) < h) {
                    if ((start_c + j) >= 0 && (start_c + j) < w) {
                        // Accumulate results
                        
                        temp += static_cast<double>(data[((start_r + i) * w + (start_c + j)) * channels + ch]) * mask[i * mask_dim + j];
                    }
                }
            }
        }
        // Write back the result
        result[(row * w + col) * channels + ch] = (unsigned char) clamp(static_cast<int>(temp), 0, 255);
    }

    
}


__global__ void integralImage_cu(unsigned char *data, u_int32_t *integralImage, u_int32_t *integralImageSquare, u_int32_t *integralImageTilt, int width, int height) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    if (row >= height || col >= width) {
        return;
    }

    // Load initial data into integral images
    integralImage[row * width + col] = static_cast<uint32_t>(data[row * width + col]);
    if (integralImageSquare) {
			integralImageSquare[row * width + col] = static_cast<uint32_t>(data[row * width + col] * data[row * width + col]);
		}
    if (integralImageTilt) {
        integralImageTilt[row * width + col] = static_cast<uint32_t>(data[row * width + col]);
    }

    __syncthreads();

    // Row prefix
    if (col == 0) {
        for (int i = 1; i < width; i++) {
            integralImage[row * width + i] += integralImage[row * width + (i-1)];
            if (integralImageSquare) {
                integralImageSquare[row * width + i] += integralImageSquare[row * width + (i-1)];
            }
            // RSAT
            if (integralImageTilt && row > 0) {
                integralImageTilt[row * width + i] += integralImageTilt[(row-1) * width + (i-1)];
            }
        }
    }
    

    __syncthreads();

    // Col prefix sum
    if (row == 0) {
        for (int j=1; j < height; j++) {
            integralImage[j * width + col] += integralImage[(j-1) * width + col];
            if (integralImageSquare) {
                integralImageSquare[j * width + col] += integralImageSquare[(j-1) * width + col];
            }

            if (integralImageTilt) {
				integralImageTilt[j * width + col] += integralImageTilt[(j - 1) * width + col];
				if (col > 0) {
					integralImageTilt[j * width + col] += integralImageTilt[(j - 1) * width + (col - 1)];
				}
				if (col < width - 1) {
					integralImageTilt[j * width + col] += integralImageTilt[(j - 1) * width + (col + 1)];
				}
				if (j > 1) {
					integralImageTilt[j * width + col] -= integralImageTilt[(j - 2) * width + col];
				}
			}
        }
    }

}

__global__ void evalStages_cu(double* haar, int* result, u_int32_t *integralImage, u_int32_t *integralImageSquare, u_int32_t *integralImageTilt, int haar_size, int width, int height, int block_w, int block_h, float scale, float inverseArea, int step) {

    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    if (row >= (height - block_h) || col >= (width - block_w)) {
        return;
    }

    int wba = row * width + col;
    int wbb = wba + block_w;
    int wbd = wba + block_h * width;
    int wbc = wbd + block_w;

    float mean = (integralImage[wba] - integralImage[wbb] - integralImage[wbd] + integralImage[wbc]) * inverseArea;
    float variance = (integralImageSquare[wba] - integralImageSquare[wbb] - integralImageSquare[wbd] + integralImageSquare[wbc]) * inverseArea - mean * mean;

    float standardDeviation = 1;
    if (variance > 0) {
        standardDeviation = sqrt(variance);
    }

    int pass = 1;

    for (int w = 2; w < haar_size; ) {
        double stageSum = 0.0f;
        double stageThreshold = haar[w++];
        double nodeLength = haar[w++];

        while (nodeLength--) {
            float rectsSum = 0.0f;
            double tilted = haar[w++];
            double rectsLength = haar[w++];

            for (int r = 0; r < rectsLength; r++) {
                int rectLeft = (int) (col + haar[w++] * scale + 0.5);
                int rectTop = (int) (row + haar[w++] * scale + 0.5); 
                int rectWidth = (int) (haar[w++] * scale + 0.5);
                int rectHeight = (int) (haar[w++] * scale + 0.5);

                double rectWeight = haar[w++];
                int w1, w2, w3, w4;

                if (tilted) {
                    // Use Rotated sum area table
                    w1 = (rectLeft - rectHeight + rectWidth) + (rectTop + rectWidth + rectHeight - 1) * width;
                    w2 = rectLeft + (rectTop - 1) * width;
                    w3 = (rectLeft - rectHeight) + (rectTop + rectHeight - 1) * width;
                    w4 = (rectLeft + rectWidth) + (rectTop + rectWidth - 1) * width;
                    rectsSum += (integralImageTilt[w1] + integralImageTilt[w2] - integralImageTilt[w3] - integralImageTilt[w4]) * rectWeight;
                } else {
                    // Sum area table
                    w1 = rectTop * width + rectLeft;
                    w2 = w1 + rectWidth;
                    w3 = w1 + rectHeight * width;
                    w4 = w3 + rectWidth;
                    rectsSum += (integralImage[w1] - integralImage[w2] - integralImage[w3] + integralImage[w4]) * rectWeight;
                }

            }

            double nodeThreshold = haar[w++];
            double nodeLeft = haar[w++];
            double nodeRight = haar[w++];

            if (rectsSum * inverseArea < nodeThreshold * standardDeviation) {
                stageSum += nodeLeft;
            } else {
                stageSum += nodeRight;
            }
        }

        if (stageSum < stageThreshold) {
            pass = 0;
            break;
        }
    }

    result[row * width + col] = pass ? 1: 0;
}