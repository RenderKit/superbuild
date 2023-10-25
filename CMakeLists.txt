## Copyright 2021 Intel Corporation
## SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.12)

if(NOT CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX
      "${CMAKE_BINARY_DIR}/install"
      CACHE STRING "Final install location." FORCE)
endif()

project(renderkit_superbuild)

include(CheckCXXCompilerFlag)
include(CMakeDependentOption)
include(ExternalProject)
include(GNUInstallDirs)
include(ProcessorCount)

include(macros.cmake)

# Options ##

cmake_dependent_option(
  ENABLE_GPU_SUPPORT
  "Enable RenderKit's GPU(SYCL) support"
  OFF
  "NOT APPLE"
  OFF
)

set (EMBREE_GPU_SUPPORT ${ENABLE_GPU_SUPPORT})
set (OIDN_GPU_SUPPORT ${ENABLE_GPU_SUPPORT})
set (OPENVKL_GPU_SUPPORT ${ENABLE_GPU_SUPPORT})
set (OSPRAY_GPU_SUPPORT ${ENABLE_GPU_SUPPORT})

cmake_dependent_option(
  OSPRAY_ENABLE_MODULE_MPI
  "Enable OSPRay's MPI module"
  ON
  "NOT APPLE"
  OFF
)

ProcessorCount(PROCESSOR_COUNT)
set(NUM_BUILD_JOBS ${PROCESSOR_COUNT} CACHE STRING "Number of build jobs '-j <n>'")

set(DEFAULT_BUILD_COMMAND cmake --build . --config release -j ${NUM_BUILD_JOBS})

get_filename_component(INSTALL_DIR_ABSOLUTE
  ${CMAKE_INSTALL_PREFIX} ABSOLUTE BASE_DIR ${CMAKE_CURRENT_BINARY_DIR})

if(APPLE)
  set (CMAKE_MACOSX_RPATH_STATE ON)
  set (FP_MODEL_CXX_FLAGS "")

  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${FP_MODEL_CXX_FLAGS}")

elseif(WIN32)
  set (CMAKE_MACOSX_RPATH_STATE OFF)
  set (FP_MODEL_CXX_FLAGS "/fp:precise")

  check_cxx_compiler_flag("/fp:precise" _flag_is_fp_model)
  check_cxx_compiler_flag("/ffp:precise" _flag_is_ffp_model)
  if(_flag_is_fp_model)
    set (FP_MODEL_CXX_FLAGS "/fp:precise")
  elseif(_flag_is_ffp_model)
    set (FP_MODEL_CXX_FLAGS "/ffp:precise")
  else()
    message(WARNING "Neither /fp: nor /ffp: supported by compiler; some tests may not be repeatable")
    set (FP_MODEL_CXX_FLAGS)
  endif()

  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${FP_MODEL_CXX_FLAGS}")
else()
  set (CMAKE_MACOSX_RPATH_STATE OFF)

  check_cxx_compiler_flag("-fp-model=precise" _flag_is_fp_model)
  check_cxx_compiler_flag("-ffp-model=precise" _flag_is_ffp_model)
  if(_flag_is_fp_model)
    set (FP_MODEL_CXX_FLAGS "-fp-model=precise")
  elseif(_flag_is_ffp_model)
    set (FP_MODEL_CXX_FLAGS "-ffp-model=precise")
  else()
    set (FP_MODEL_CXX_FLAGS)
  endif()

  check_cxx_compiler_flag("-fhonor-infinities" _fhonor_infinities)
  if(_fhonor_infinities)
    set(HONOR_INFINITES_CXX_FLAGS "-fhonor-infinities")
  else()
    set (HONOR_INFINITES_CXX_FLAGS)
  endif()

  check_cxx_compiler_flag("-fhonor-nans" _fhonor_nans)
  if(_fhonor_nans)
    set(HONOR_NANS_CXX_FLAGS "-fhonor-nans")
  else()
    set (HONOR_NANS_CXX_FLAGS)
  endif()

  check_cxx_compiler_flag("-static-intel" _static_intel)
  if(_static_intel)
    set(STATIC_INTEL_CXX_FLAGS "-static-intel")
  else()
    set (STATIC_INTEL_CXX_FLAGS)
  endif()

  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${FP_MODEL_CXX_FLAGS} ${HONOR_INFINITES_CXX_FLAGS} ${HONOR_NANS_CXX_FLAGS} ${STATIC_INTEL_CXX_FLAGS}")
endif()

## Build projects ##

include(get_tbb.cmake)
include(get_ispc.cmake)
include(get_glfw.cmake)

if(OSPRAY_ENABLE_MODULE_MPI)
  include(get_snappy.cmake)
endif()

set(_RKCOMMON_VERSION 1.12.0)
set(_EMBREE_VERSION 4.3.0)
set(_OPENPGL_VERSION 0.5.0)
set(_OPENVKL_VERSION 2.0.0)
set(_OIDN_VERSION 2.1.0)
set(_OSPRAY_VERSION 3.0.0)
set(_OSPRAY_STUDIO_VERSION 0.13.0)

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
    -DEMBREE_SYCL_SUPPORT=${EMBREE_GPU_SUPPORT}
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
    -DOPENVKL_ENABLE_DEVICE_GPU=${OPENVKL_GPU_SUPPORT}
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
    -DOIDN_DEVICE_SYCL=${OIDN_GPU_SUPPORT}
    -DOIDN_APPS=ON
  DEPENDS_ON ispc tbb rkcommon
)

build_subproject(
  NAME ospray
  URL "https://github.com/ospray/ospray/archive/refs/tags/v${_OSPRAY_VERSION}.zip"
  BUILD_ARGS
    -DTBB_ROOT=${TBB_PATH}
    -DISPC_EXECUTABLE=${ISPC_PATH}
    -DBUILD_GPU_SUPPORT=${OSPRAY_GPU_SUPPORT}
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

