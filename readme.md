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
./cuda-cmake-nvtx 
```

