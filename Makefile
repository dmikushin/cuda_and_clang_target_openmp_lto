ARCH=86
NVCC=nvcc -O3 -Xcompiler=-ffast-math

all: matmul.nvcc

matmul.nvcc.o: matmul.cu
	$(NVCC) -arch=sm_$(ARCH) -rdc=true -c $< -o $@

dot_product.nvcc.o: dot_product.cu
	$(NVCC) -arch=sm_$(ARCH) -rdc=true -c $< -o $@

matmul.nvcc: matmul.nvcc.o dot_product.nvcc.o
	$(NVCC) -arch=sm_$(ARCH) $^ -o $@_check && \
	cuobjdump -sass $@_check | grep dotProduct && \
	mv $@_check $@

clean:
	rm -rf matmul.nvcc.o dot_product.nvcc.o matmul.nvcc_check matmul.nvcc
