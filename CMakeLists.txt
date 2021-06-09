## Copyright 2021 Intel Corporation
## SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.12)

if(NOT CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX
      "${CMAKE_BINARY_DIR}/install"
      CACHE STRING "Final install location." FORCE)
endif()

project(renderkit_superbuild)

include(ExternalProject)
include(GNUInstallDirs)
include(ProcessorCount)

include(macros.cmake)

# Options ##

ProcessorCount(PROCESSOR_COUNT)
set(NUM_BUILD_JOBS ${PROCESSOR_COUNT} CACHE STRING "Number of build jobs '-j <n>'")

set(DEFAULT_BUILD_COMMAND cmake --build . --config release -j ${NUM_BUILD_JOBS})

get_filename_component(INSTALL_DIR_ABSOLUTE
  ${CMAKE_INSTALL_PREFIX} ABSOLUTE BASE_DIR ${CMAKE_CURRENT_BINARY_DIR})

if(WIN32 OR LINUX)
  set(OSPRAY_MODULE_MPI_FLAG "-DOSPRAY_MODULE_MPI=ON")
endif()

## Build projects ##

include(get_tbb.cmake)
include(get_ispc.cmake)
include(get_glfw.cmake)

build_subproject(
  NAME rkcommon
  URL "https://github.com/ospray/rkcommon/archive/v1.6.1.zip"
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
    -DINSTALL_DEPS=OFF
    -DBUILD_TESTING=OFF
  DEPENDS_ON tbb ispc
)

build_subproject(
  NAME embree
  URL "https://github.com/embree/embree/archive/v3.13.0.zip"
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
    -DISPC_EXECUTABLE=${ISPC_PATH}
    -DEMBREE_TUTORIALS=OFF
    -DBUILD_TESTING=OFF
  DEPENDS_ON rkcommon
)

build_subproject(
  NAME openvkl
  URL "https://github.com/openvkl/openvkl/archive/v0.13.0.zip"
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
    -DISPC_EXECUTABLE=${ISPC_PATH}
    -DBUILD_BENCHMARKS=OFF
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTING=OFF
  DEPENDS_ON rkcommon embree
)

build_subproject(
  NAME oidn
  URL "https://github.com/OpenImageDenoise/oidn/releases/download/v1.4.0/oidn-1.4.0.src.zip"
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
    -DISPC_EXECUTABLE=${ISPC_PATH}
    -DOIDN_APPS=ON
  DEPENDS_ON rkcommon
)

build_subproject(
  NAME ospray
  URL "https://github.com/ospray/ospray/archive/v2.6.0.zip"
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
    -DISPC_EXECUTABLE=${ISPC_PATH}
    -DOSPRAY_BUILD_ISA=ALL
    -DOSPRAY_MODULE_BILINEAR_PATCH=OFF
    -DOSPRAY_MODULE_DENOISER=ON
    ${OSPRAY_MODULE_MPI_FLAG}
    -DOSPRAY_ENABLE_APPS=OFF
    -DOSPRAY_STRICT_BUILD=OFF
    -DOSPRAY_INSTALL_DEPENDENCIES=OFF
  DEPENDS_ON rkcommon openvkl embree oidn glfw
)

if(WIN32)
  set(patch_command C:\Program Files\Git\usr\bin\patch.exe cmake/pybind11.cmake ${CMAKE_SOURCE_DIR}/pybind11.cmake.patch)
else()
  set(patch_command patch cmake/pybind11.cmake ${CMAKE_SOURCE_DIR}/pybind11.cmake.patch)
endif()

build_subproject(
  NAME ospray_studio
  URL "https://github.com/ospray/ospray_studio/archive/v0.7.0.zip"
  PATCH_COMMAND ${patch_command}
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
    -DBUILD_APPS=ON
    -DBUILD_PLUGINS=ON
    -DENABLE_OPENIMAGEIO=OFF  # These can be enabled if the dependency is pre-installed
    -DENABLE_EXR=OFF
    -DENABLE_OPENVDB=OFF
  DEPENDS_ON ospray rkcommon openvkl embree oidn glfw
)

