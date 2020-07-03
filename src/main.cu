#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <stdio.h>

#include "nvtx_util.cuh"

static void HandleCUDAError(const char *file, int line, cudaError_t status = cudaGetLastError()) {
	if (status != cudaSuccess || (status = cudaGetLastError()) != cudaSuccess)
	{
		if (status == cudaErrorUnknown)
		{
			printf("%s(%i) An Unknown CUDA Error Occurred :(\n", file, line);
			exit(1);
		}
		printf("%s(%i) CUDA Error Occurred;\n%s\n", file, line, cudaGetErrorString(status));
		exit(1);
	}
}

#define CUDA_CALL( err ) (HandleCUDAError(__FILE__, __LINE__ , err))
#define CUDA_CHECK() (HandleCUDAError(__FILE__, __LINE__))



__global__ void pow2Kernel(const unsigned int N, const unsigned int reps, unsigned int * in, unsigned int * out){
    unsigned int idx = threadIdx.x + blockIdx.x * blockDim.x;
    if(idx < N){
        for(unsigned int rep = 0; rep < reps; rep++){
            out[idx] = in[idx] * in[idx];
        }
    }
}

void pow2Host(const unsigned int N, const unsigned int reps, unsigned int * in, unsigned int * out){
    for(unsigned int idx = 0; idx < N; idx++){
        for(unsigned int rep = 0; rep < reps; rep++){
            out[idx] = in[idx] * in[idx];
        }
    }
}

unsigned int evaluate(const unsigned int N, unsigned int * a, unsigned int * b, const unsigned int print_count){
    NVTX_RANGE("evaluate");
    unsigned int difference_count = 0;
    for(unsigned int idx = 0; idx < N; idx++){
        bool match = a[idx] == b[idx];
        if(!match){
            difference_count++;
        }
        if(idx < print_count){
            printf("%u: %u == %u ? %d\n", idx, a[idx], b[idx], match);
        }
    }
    return difference_count;
}

bool allocate(const unsigned int N, unsigned int ** h_in, unsigned int ** h_out, unsigned int ** d_in, unsigned int ** d_out, unsigned int ** h_d_out){
    NVTX_RANGE("allocate");
    size_t size = N * sizeof(unsigned int);

    *h_in = (unsigned int*) malloc(size);
    *h_out = (unsigned int*) malloc(size);
    CUDA_CALL(cudaMalloc((void**)d_in, size));
    CUDA_CALL(cudaMalloc((void**)d_out, size));
    *h_d_out = (unsigned int*) malloc(size);

    bool success = true;
    if(*h_in == nullptr){
        success = false;
    }
    if(*h_out == nullptr){
        success = false;
    }
    if(*h_d_out == nullptr){
        success = false;
    }
    return success;
}

void initialse(const unsigned int N, unsigned int * h_in, unsigned int * h_out, unsigned int * d_in, unsigned int * d_out, unsigned int * h_d_out){
    NVTX_RANGE("initialse");

    size_t size = N * sizeof(unsigned int);

    // Set memory values to 0
    memset(h_in, 0, size);
    memset(h_out, 0, size);
    CUDA_CALL(cudaMemset(d_in, 0, size));
    CUDA_CALL(cudaMemset(d_out, 0, size));
    memset(h_d_out, 0, size);

    // Initialise the host input.
    for(unsigned int idx = 0; idx < N; idx++){
        h_in[idx] = idx;
    }
}
void executeOnDevice(const unsigned int N, const unsigned int reps, unsigned int * h_in, unsigned int * d_in, unsigned int * d_out, unsigned int * h_d_out){
    NVTX_RANGE("executeOnDevice");
    const unsigned int kernel_reps = 32;
    size_t size = N * sizeof(unsigned int);

    NVTX_PUSH("H2D");
    // Copy input to device
    CUDA_CALL(cudaMemcpy(d_in, h_in, size, cudaMemcpyHostToDevice));
    NVTX_POP();
    // Launch kernel
    int blockSize = 0;
	int minGridSize = 0;
	int gridSize = 0;
    CUDA_CALL(cudaOccupancyMaxPotentialBlockSize(&minGridSize, &blockSize, pow2Kernel, 0, N));
    gridSize = (N + blockSize - 1) / blockSize;

    NVTX_PUSH("kerenel_reps");
    for(unsigned int krep = 0; krep < kernel_reps; krep++){
        NVTX_PUSH("pow2Kernel");
        pow2Kernel << <gridSize, blockSize >> >(N, reps, d_in, d_out);
        NVTX_POP();
    }
    cudaDeviceSynchronize();
    CUDA_CHECK();
    NVTX_POP();

    
    // Copy data from device to host.
    NVTX_PUSH("D2H");
    CUDA_CALL(cudaMemcpy(h_d_out, d_out, size, cudaMemcpyDeviceToHost));
    NVTX_POP();
}

void executeOnHost(const unsigned int N, const unsigned int reps, unsigned int * h_in, unsigned int * h_out){
    NVTX_RANGE("executeOnHost");
    pow2Host(N, reps, h_in, h_out);
}

void deallocate(unsigned int ** h_in, unsigned int ** h_out, unsigned int ** d_in, unsigned int ** d_out, unsigned int ** h_d_out){
    NVTX_RANGE("deallocate");
    free(*h_in);
    *h_in = nullptr;
    free(*h_out);
    *h_out = nullptr;
    
    CUDA_CALL(cudaFree(*d_in));
    *d_in = nullptr;
    CUDA_CALL(cudaFree(*d_out));
    *d_out = nullptr;
    
    free(*h_d_out);
    *h_d_out = nullptr;
}

bool arbitraryCUDAStuff(){
    // Push a range marker.
    NVTX_RANGE("arbitraryCUDAStuff");

    // Set problem size
    // const unsigned int N = 1024;
    const unsigned int N = 65536;
    const unsigned int reps = 32;

    // Declare pointers
    unsigned int * h_in = nullptr;
    unsigned int * h_out = nullptr;
    unsigned int * d_in = nullptr;
    unsigned int * d_out = nullptr;
    unsigned int * h_d_out = nullptr;

    // Allocate
    bool allocated = allocate(N, &h_in, &h_out, &d_in, &d_out, &h_d_out);
    if(!allocated){
        return false;
    }

    // Initialise
    initialse(N, h_in, h_out, d_in, d_out, h_d_out);
    
    // Execute Device
    executeOnDevice(N, reps, h_in, d_in, d_out, h_d_out);

    // Execute host
    executeOnHost(N, reps, h_in, h_out);

    // Evalute
    const unsigned int print_count = 0;
    unsigned int error_count = evaluate(N, h_out, h_d_out, print_count);
    if(error_count != 0){
        printf("Incorrect: %u incorrect values\n", error_count);
    } else {
        printf("Success!\n");
    }

    // Free 
    deallocate(&h_in, &h_out, &d_in, &d_out, &h_d_out);

    return !error_count;
}

void cudaInit(){
    NVTX_RANGE("cudaInit");
    // Free the nullptr to initialise the cuda context.
    CUDA_CALL(cudaFree(0));
}

void printNVTXStatus(){
    #if defined(USE_NVTX)
        printf("NVTX is ON\n");
    #else 
        printf("NVTX is OFF\n");
    #endif
}

int main(int argc, char * argv[]){
    // Print if NVTX is enabled or not.
    printNVTXStatus();

    // Explicit full main markers.
    NVTX_PUSH("main");

    // Early initialise the cuda context to improve profiling clarity.
    cudaInit();

    // Run some stuff.
    bool success = arbitraryCUDAStuff();

    NVTX_POP();

    // Reset the device.
    cudaDeviceReset();

    return success ? EXIT_SUCCESS : EXIT_FAILURE;
}
