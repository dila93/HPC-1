#include <cuda.h>
#include <ctime>
#include <iostream>

#define TILE_WIDTH 32
#define endl '\n'

__global__
void multKernelTiled(float *d_M, float *d_N, float *d_R, int width_M, int height, int width_N) {

}

__global__
void multKernel(float *d_M, float *d_N, float *d_R, int width_M, int height, int width_N) {
  int i = blockIdx.y * blockDim.y + threadIdx.y;
  int j = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < height and j < width_N) {
    int Pvalue = 0;
    for (int k = 0; k < width_M; k++) {
      Pvalue += d_M[i * width_M + k] * d_N[k * width_N + j];
    }
    d_R[i * width_N + j] = Pvalue;
  }
}

void mult(float *A, float *B, float *C, int width_A, int height_A, int width_B) {
  int aux = 0;
  for (int i = 0; i < height_A; i++) {
    for (int j = 0; j < width_B; j++) {
      aux = 0;
      for (int k = 0; k < width_A; k++)
        aux += A[i * width_A + k] * B[k * width_B + j];
      C[i * width_B + j] = aux;
    }
  }
}

void initValues(float *m, int width, int height) {
  int values = 1;
  for (int i = 0; i < height; i++) {
    for (int j = 0; j < width; j++) {
      m[i * width + j] = values++;
    }
  }
}

void print(float *m, int width, int height) {
  for (int i = 0; i < height; i++) {
    for (int j = 0; j < width; j++) {
      if (j) std::cout << " ";
      std::cout << m[i * width + j];
    }
    std::cout << endl;
  }
}

int main() {
  int height = 3;
  int width_A = 3;
  int width_B = 2;

  float *A = new float[height * width_A];
  float *B = new float[height * width_B];
  float *C = new float[height * width_B];
  float *D = new float[height * width_B];

  initValues(A, width_A, height);
  initValues(B,width_B, height);

  float *d_A, *d_B, *d_D;
  int blocksize = 32;

  dim3 dimBlock(blocksize, blocksize, 1);
  dim3 dimGrid(ceil(width_B / float(blocksize)), ceil(height / float(blocksize)), 1);

  cudaMalloc((void**)&d_A, sizeof(float) * height * width_A);
  cudaMalloc((void**)&d_B, sizeof(float) * height * width_B);
  cudaMalloc((void**)&d_D, sizeof(float) * height * width_B);
  std::cout << std::fixed;

  {
    clock_t start = clock();
    mult(A, B, C, width_A, height, width_B);
    clock_t end = clock();
    double cpu_time_used = double(end - start) / CLOCKS_PER_SEC;
    std::cout << "Tiempo invertido CPU = " << cpu_time_used << "s\n";
    print(C, width_B, height);

  }

  // Mult without tiles
  {
    clock_t start = clock();

    cudaMemcpy(d_A, A, sizeof(float) * height * width_A, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, B, sizeof(float) * height * width_B, cudaMemcpyHostToDevice);

    multKernel<<<dimGrid, dimBlock>>>(d_A, d_B, d_D, width_A, height, width_B);
    cudaMemcpy(D, d_D, sizeof(float) * height * width_B, cudaMemcpyDeviceToHost);

    clock_t end = clock();
    double cpu_time_used = double(end - start) / CLOCKS_PER_SEC;
    std::cout << "Tiempo invertido GPU = " << cpu_time_used << "s\n";
    print(D, width_B, height);
  }

  // Mult with tiles
  {
    clock_t start = clock();

    cudaMemcpy(d_A, A, sizeof(float) * height * width_A, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, B, sizeof(float) * height * width_B, cudaMemcpyHostToDevice);

    multKernelTiled<<<dimGrid, dimBlock>>>(d_A, d_B, d_D, width_A, height, width_B);
    cudaMemcpy(D, d_D, sizeof(float) * height * width_B, cudaMemcpyDeviceToHost);

    clock_t end = clock();
    double cpu_time_used = double(end - start) / CLOCKS_PER_SEC;
    std::cout << "Tiempo invertido GPU = " << cpu_time_used << "s\n";
    print(D, width_B, height);
  }

  delete A;
  delete B;
  delete C;
  delete D;

  cudaFree(d_A);
  cudaFree(d_B);
  cudaFree(d_D);

  return 0;
}