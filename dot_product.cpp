#pragma omp declare target
float dotProduct(float *A, float *B, int row, int col, int N) {
  float sum = 0.0f;
  for (int k = 0; k < N; ++k) {
    sum += A[row * N + k] * B[k * N + col];
  }
  return sum;
}
#pragma omp end declare target
