#include <cstdlib>
#include <ctime>
#include <iostream>
#include <omp.h>

using namespace std;

#pragma omp declare target
float dotProduct(float *A, float *B, int row, int col, int N);
#pragma omp end declare target

void matMulCPU(float *A, float *B, float *C, int N) {
  for (int i = 0; i < N; ++i) {
    for (int j = 0; j < N; ++j) {
      C[i * N + j] = dotProduct(A, B, i, j, N);
    }
  }
}

bool checkResults(float *C, float *C_GPU, int N) {
  for (int i = 0; i < N * N; ++i) {
    if (abs(C[i] - C_GPU[i]) > 1e-3) {
      std::cerr << "Result mismatch @ i = " << i << " : " << C[i]
                << " != " << C_GPU[i] << std::endl;
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

  float *A = new float[N * N];
  float *B = new float[N * N];
  float *C_GPU = new float[N * N]();
  float *C_CPU = new float[N * N]();

  // Generate random matrices A and B
  for (int i = 0; i < N * N; ++i) {
    A[i] = rand() / float(RAND_MAX);
    B[i] = rand() / float(RAND_MAX);
  }

  matMulCPU(A, B, C_CPU, N);

#pragma omp target data map(to : A[0 : N * N], B[0 : N * N]) map(from : C_GPU[0 : N * N])
  {
#pragma omp target teams distribute parallel for collapse(2)
    for (int i = 0; i < N; ++i) {
      for (int j = 0; j < N; ++j) {
        C_GPU[i * N + j] = dotProduct(A, B, i, j, N);
      }
    }
  }

  if (checkResults(C_GPU, C_CPU, N)) {
    cout << "Result is correct!" << endl;
  } else {
    cout << "Result is incorrect." << endl;
  }

  delete[] C_CPU;
  delete[] A;
  delete[] B;
  delete[] C_GPU;

  return 0;
}
