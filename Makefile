ARCH=86
NVCC=nvcc -O3 -Xcompiler=-ffast-math
CLANG=clang++-19

all: matmul.nvcc matmul.nvcc_lto matmul.clang

#
# Basic separable compilation:
# matrix multiply kernel and dot product function are compiled separately
# The generated GPU code explicitly contains dotProduct function, which is
# called from the matrix multiply kernel
#

matmul.nvcc.o: matmul.cu
	$(NVCC) -arch=sm_$(ARCH) -rdc=true -c $< -o $@

dot_product.nvcc.o: dot_product.cu
	$(NVCC) -arch=sm_$(ARCH) -rdc=true -c $< -o $@

matmul.nvcc: matmul.nvcc.o dot_product.nvcc.o
	$(NVCC) -arch=sm_$(ARCH) $^ -o $@_check && \
	cuobjdump -sass $@_check | grep dotProduct && \
	cuobjdump -sass $@_check | grep CALL && \
	mv $@_check $@

#
# CUDA device-side LTO is enabled:
# With -dlto each object file incorporates intermediate representation of
# GPU code that can be used for LTO upon linking.
# As a result, dot product function is substituted inside the matrix multiply
# kernel.
#

matmul.nvcc_lto.o: matmul.cu
	$(NVCC) -arch=sm_$(ARCH) -dlto -rdc=true -c $< -o $@

dot_product.nvcc_lto.o: dot_product.cu
	$(NVCC) -arch=sm_$(ARCH) -dlto -rdc=true -c $< -o $@

matmul.nvcc_lto: matmul.nvcc_lto.o dot_product.nvcc_lto.o
	$(NVCC) -arch=sm_$(ARCH) -dlto $^ -o $@_check && \
	cuobjdump -sass $@_check | grep dotProduct | wc -l | awk '{exit $$1}' && \
	cuobjdump -sass $@_check | grep CALL | wc -l | awk '{exit $$1}' && \
	mv $@_check $@

#
# CUDA code compilation with Clang
#

matmul.clang.o: matmul.cu
	$(CLANG) --cuda-gpu-arch=sm_$(ARCH) -fcuda-rdc -c $< -o $@

dot_product.clang.o: dot_product.cu
	$(CLANG) --cuda-gpu-arch=sm_$(ARCH) -fcuda-rdc -c $< -o $@

matmul.clang: matmul.clang.o dot_product.clang.o
	$(CLANG) --cuda-gpu-arch=sm_$(ARCH) -fcuda-rdc $^ -o $@_check -L/usr/local/cuda/lib64 -lcudart_static -lcudadevrt && \
	cuobjdump -sass $@_check | grep dotProduct && \
	cuobjdump -sass $@_check | grep CALL && \
	mv $@_check $@

clean:
	rm -rf matmul.nvcc.o dot_product.nvcc.o matmul.nvcc_check matmul.nvcc
	rm -rf matmul.nvcc_lto.o dot_product.nvcc_lto.o matmul.nvcc_lto_check matmul.nvcc_lto
	rm -rf matmul.clang.o dot_product.clang.o matmul.clang_check matmul.clang
