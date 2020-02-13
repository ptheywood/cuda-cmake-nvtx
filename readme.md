# CUDA Cmake NVTX

Test Cmake use of NVTX markers



## Building

With NVTX: 

```
mkdir -p build
cd build
cmake -DNVTX=ON ..
make
```

Without NVTX: 

```
mkdir -p build
cd build
cmake -DNVTX=OFF ..
make
```

## Running

```
cd build/
./cuda-cmake-nvtx 
```

### Caputring timeline with nvvp

```
cd build/
nvprof -o timeline.nvvp -f ./cuda-cmake-NVTX 
```

### Capturing timeline with nsight

```
cd build
nsys profile -o timeline -f ./cuda-cmake-NVTX 
```
