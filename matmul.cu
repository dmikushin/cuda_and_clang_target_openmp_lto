#include <iostream>
#include <cstdlib>
#include <ctime>

using namespace std;

__device__ float dotProduct(float *A, float *B, int row, int col, int N);

__global__ void matMulKernel(float *A, float *B, float *C, int N) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if(row < N && col < N) {
        C[row * N + col] = dotProduct(A, B, row, col, N);
    }
}

void matMulCPU(float *A, float *B, float *C, int N) {
    for(int i = 0; i < N; ++i) {
        for(int j = 0; j < N; ++j) {
            float sum = 0.0f;
            for(int k = 0; k < N; ++k) {
                sum += A[i * N + k] * B[k * N + j];
            }
            C[i * N + j] = sum;
        }
    }
}

bool checkResults(float *C, float *C_CPU, int N) {
    for(int i = 0; i < N*N; ++i) {
        if(abs(C[i] - C_CPU[i]) > 1e-3) {
            std::cerr << "Result mismatch @ i = " << i << " : " << C[i] << " != " << C_CPU[i] << std::endl;
	    return false;
        }
    }
    return true;
}

int main(int argc, char **argv) {
    int N = (argc > 1) ? atoi(argv[1]) : 1024;
    cout << "Matrix size: " << N << "x" << N << endl;

    // Initialize random seed
    srand(time(0));

    float *A = new float[N*N];
    float *B = new float[N*N];
    float *C_GPU, *C_CPU, *C;

    // Generate random matrices A and B
    for(int i = 0; i < N*N; ++i) {
        A[i] = rand() / float(RAND_MAX);
        B[i] = rand() / float(RAND_MAX);
    }

    cudaMalloc(&C_GPU, N*N*sizeof(float));
    C_CPU = new float[N*N]();
    C = new float[N*N]();

    matMulCPU(A, B, C_CPU, N);

    dim3 threadsPerBlock(16, 16);
    dim3 numBlocks((N + threadsPerBlock.x - 1) / threadsPerBlock.x,
                   (N + threadsPerBlock.y - 1) / threadsPerBlock.y);
    
    matMulKernel<<<numBlocks, threadsPerBlock>>>(A, B, C_GPU, N);

    cudaMemcpy(C, C_GPU, N*N*sizeof(float), cudaMemcpyDeviceToHost);

    if(checkResults(C, C_CPU, N)) {
        cout << "Result is correct!" << endl;
    } else {
        cout << "Result is incorrect." << endl;
    }

    cudaFree(C_GPU);
    delete[] C_CPU;
    delete[] A;
    delete[] B;
    delete[] C;

    return 0;
}
