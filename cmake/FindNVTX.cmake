# CMake module to find NVTX headers/library
# This is currently quite simple, could be expanded to support user-provided hinting?
# Usage:
#    find_package( NVTX )
#    if(NVTX_FOUND)
#        include_directories(${NVTX_INCLUDE_DIRS})
#        target_link_libraries(target ${NVTX_LIBRARIES})
#    endif()
#
# Variables:
#    NVTX_FOUND
#    NVTX_INCLUDE_DIRS
#    NVTX_LIBRARIES


# Attempt to find nvToolsExt.h
find_path(NVTX_INCLUDE_DIRS
	NAMES nvToolsExt.h
	PATHS ${CUDA_TOOLKIT_ROOT_DIR}
	PATH_SUFFIXES include
)
# Find the dynamic library
find_library(NVTX_LIBRARIES
	NAMES nvToolsExt64_1 nvToolsExt32_1
	PATHS ${CUDA_TOOLKIT_ROOT_DIR}
	PATH_SUFFIXES lib lib64 lib/Win32 lib/x64
)

include(FindPackageHandleStandardArgs)
# handle the QUIETLY and REQUIRED arguments and set NVTX_FOUND to TRUE
# if all listed variables are TRUE
find_package_handle_standard_args(NVTX DEFAULT_MSG NVTX_INCLUDE_DIRS NVTX_LIBRARIES)

#----------------------------------------------------------------------------------------#

if(NVTX_FOUND)
    add_library(nvtx INTERFACE)
    target_link_libraries(nvtx INTERFACE ${NVTX_LIBRARIES})
    target_include_directories(nvtx INTERFACE ${NVTX_INCLUDE_DIRS})
    # get_filename_component(NVTX_INCLUDE_DIRS ${NVTX_INCLUDE_DIRS} REALPATH)
    # get_filename_component(NVTX_LIBRARIES ${NVTX_LIBRARY} REALPATH)
endif()

mark_as_advanced(NVTX_INCLUDE_DIRS NVTX_LIBRARIES)
