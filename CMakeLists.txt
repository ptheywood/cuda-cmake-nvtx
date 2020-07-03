# Cmake for simple cuda project which uses NVTX markers as an optional thing.

# Set the minimum cmake version to that which supports cuda natively.
cmake_minimum_required(VERSION VERSION 3.10 FATAL_ERROR)

# look for modules to enabel find_nvtx
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/modules ${CMAKE_MODULE_PATH})

# Name the project and set languages
project(cuda-cmake-NVTX CUDA CXX)


# Option to enable/disable NVTX markers for improved profiling
option(USE_NVTX "Enable NVTX markers for improved profiling (if aviailable)" OFF)


# Set a default build type if not passed (https://blog.kitware.com/cmake-and-the-default-build-type/)
set(default_build_type "Release")
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
  set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Release")
endif()

if(CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_CONFIGURATION_TYPES Debug Release)
  set(CMAKE_CONFIGURATION_TYPES "${CMAKE_CONFIGURATION_TYPES}" CACHE STRING
    "Reset the configurations to what we need"
    FORCE)
endif()


# Update the documentation string of CMAKE_BUILD_TYPE for GUIs
SET(CMAKE_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING
    "Choose the type of build, options are: None Debug Release."
    FORCE)


# Require a minimum cuda version
if(CMAKE_CUDA_COMPILER_VERSION VERSION_LESS 7.0)
    message(FATAL_ERROR "CUDA version must be at least 7.0")
endif()

# Specify some additional compiler flags
# Lineinfo for non -G release
set(CMAKE_CUDA_FLAGS_RELEASE "${CMAKE_CUDA_FLAGS_RELEASE} -lineinfo")

# CUDA debug symbols
set(CMAKE_CUDA_FLAGS_DEBUG "${CMAKE_CUDA_FLAGS_DEBUG} -G -D_DEBUG -DDEBUG")


# All warnings for all modes.
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcompiler -Wall")

# Specify using C++11 standard
if(NOT DEFINED CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED true)
endif()

# Tell CUDA to use C++11 standard
if(NOT DEFINED CMAKE_CUDA_STANDARD)
    set(CMAKE_CUDA_STANDARD 11)
    set(CMAKE_CUDA_STANDARD_REQUIRED True)
endif()

# Define output location of binary files
# SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${cuda-cmake-NVTX_SOURCE_DIR}/bin/${CMAKE_BUILD_TYPE}/)

# Define which source files are required for the target executable
add_executable(cuda-cmake-NVTX src/main.cu)
set_property(TARGET cuda-cmake-NVTX PROPERTY CUDA_SEPARABLE_COMPILATION ON)

# Include dirs
# ../include required for cmake > 3.12 which ignores this otheriwse.
target_include_directories(cuda-cmake-NVTX SYSTEM PRIVATE "${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}/../include")
message( ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_include_directories(cuda-cmake-NVTX PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)


# Define link libraries for the target
if(USE_NVTX)
    # Find the nvtx library using custom cmake module
    find_package(NVTX)
    # If found, apply 
    if(NVTX_FOUND)
        set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -DUSE_NVTX=${NVTX_VERSION}")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSE_NVTX=${NVTX_VERSION}")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSE_NVTX=${NVTX_VERSION}")
        set(FLAMEGPU_DEPENDENCY_INCLUDE_DIRECTORIES ${FLAMEGPU_DEPENDENCY_INCLUDE_DIRECTORIES} "${NVTX_INCLUDE_DIRS}")
        if(NVTX_VERSION VERSION_LESS "3")
            set(FLAMEGPU_DEPENDENCY_LINK_LIBRARIES ${FLAMEGPU_DEPENDENCY_LINK_LIBRARIES} ${NVTX_LIBRARIES})
        endif()
    else()
        # If not found, disable.
        message("-- NVTX not available")
        SET(USE_NVTX "OFF" PARENT_SCOPE)    
    endif()
endif()

message("Generated with CMAKE_BUILD_TYPE types: ${CMAKE_BUILD_TYPE}")
message("Generated with config types: ${CMAKE_CONFIGURATION_TYPES}")
