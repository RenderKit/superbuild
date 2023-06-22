## Copyright 2021 Intel Corporation
## SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.12)

if(NOT CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX
      "${CMAKE_BINARY_DIR}/install"
      CACHE STRING "Final install location." FORCE)
endif()

project(renderkit_superbuild)

include(CMakeDependentOption)
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

cmake_dependent_option(
  EMBREE_SYCL_SUPPORT
  "Enable Embree's SYCL support"
  OFF
  "NOT APPLE"
  OFF
)

cmake_dependent_option(
  OSPRAY_ENABLE_MODULE_MPI
  "Enable OSPRay's MPI module"
  ON
  "NOT APPLE"
  OFF
)

## Build projects ##

include(get_tbb.cmake)
include(get_ispc.cmake)
include(get_glfw.cmake)

if(OSPRAY_ENABLE_MODULE_MPI)
  include(get_snappy.cmake)
endif()

set(_RKCOMMON_VERSION 1.11.0)
set(_EMBREE_VERSION 4.1.0)
set(_OPENPGL_VERSION 0.5.0)
set(_OPENVKL_VERSION 1.3.2)
set(_OIDN_VERSION 2.0.0)
set(_OSPRAY_VERSION 2.12.0)
set(_OSPRAY_STUDIO_VERSION 0.12.1)

build_subproject(
  NAME rkcommon
  URL "https://github.com/ospray/rkcommon/archive/refs/tags/v${_RKCOMMON_VERSION}.zip"
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
    -DINSTALL_DEPS=OFF
    -DBUILD_TESTING=OFF
  DEPENDS_ON tbb
)

build_subproject(
  NAME embree
  URL "https://github.com/embree/embree/archive/refs/tags/v${_EMBREE_VERSION}.zip"
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
    -DEMBREE_ISPC_SUPPORT=ON
    -DEMBREE_ISPC_EXECUTABLE=${ISPC_PATH}
    -DEMBREE_SYCL_SUPPORT=${EMBREE_SYCL_SUPPORT}
    -DEMBREE_TUTORIALS=OFF
    -DBUILD_TESTING=OFF
  DEPENDS_ON tbb ispc glfw
)

build_subproject(
  NAME openpgl
  URL "https://github.com/OpenPathGuidingLibrary/openpgl/archive/refs/tags/v${_OPENPGL_VERSION}.zip"
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
  DEPENDS_ON tbb
)

build_subproject(
  NAME openvkl
  URL "https://github.com/openvkl/openvkl/archive/refs/tags/v${_OPENVKL_VERSION}.zip"
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
  URL "https://github.com/OpenImageDenoise/oidn/releases/download/v${_OIDN_VERSION}/oidn-${_OIDN_VERSION}.src.zip"
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
    -DISPC_EXECUTABLE=${ISPC_PATH}
    -DOIDN_APPS=ON
  DEPENDS_ON ispc tbb rkcommon
)

build_subproject(
  NAME ospray
  URL "https://github.com/ospray/ospray/archive/refs/tags/v${_OSPRAY_VERSION}.zip"
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
    -DISPC_EXECUTABLE=${ISPC_PATH}
    -DFIND_LIBRARY_USE_LIB64_PATHS=TRUE
    -DOSPRAY_BUILD_ISA=ALL
    -DOSPRAY_MODULE_BILINEAR_PATCH=OFF
    -DOSPRAY_MODULE_DENOISER=ON
    -DOSPRAY_MODULE_MPI=${OSPRAY_ENABLE_MODULE_MPI}
    -DOSPRAY_ENABLE_APPS=OFF
    -DOSPRAY_STRICT_BUILD=OFF
    -DOSPRAY_INSTALL_DEPENDENCIES=OFF
  DEPENDS_ON rkcommon openvkl embree oidn glfw $<$<BOOL:${OSPRAY_ENABLE_MODULE_MPI}>:snappy>
)

build_subproject(
  NAME ospray_studio
  URL "https://github.com/ospray/ospray_studio/archive/refs/tags/v${_OSPRAY_STUDIO_VERSION}.zip"
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
    -DBUILD_APPS=ON
    -DBUILD_PLUGINS=ON
    -DBUILD_TESTING=OFF
    -DENABLE_OPENIMAGEIO=OFF  # These can be enabled if the dependency is pre-installed
    -DENABLE_EXR=OFF
    -DENABLE_OPENVDB=OFF
    -DOSPRAY_INSTALL=OFF
    -DUSE_PYSG=ON
  DEPENDS_ON ospray rkcommon openvkl embree oidn glfw
)

