#if 0
// Will not work:
//
// nvlink error   : Undefined reference to '_Z10dotProductPfS_iii' in 'matmul.nvcc.o' 
inline __attribute__((always_inline))
#endif
__device__ float dotProduct(float *A, float *B, int row, int col, int N) {
    float sum = 0.0f;
    for(int k = 0; k < N; ++k) {
        sum += A[row * N + k] * B[k * N + col];
    }
    return sum;
}

