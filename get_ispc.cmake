## Copyright 2021-2024 Intel Corporation
## SPDX-License-Identifier: Apache-2.0

set(ISPC_VERSION 1.23.0 CACHE STRING "")

set(SUBPROJECT_NAME ispc-v${ISPC_VERSION})

if (APPLE)
  set(ISPC_SUFFIX "macOS.universal.tar.gz")
elseif(WIN32)
  set(ISPC_SUFFIX "windows.zip")
else()
  set(ISPC_SUFFIX "linux-oneapi.tar.gz")
endif()

set(ISPC_URL "https://github.com/ispc/ispc/releases/download/v${ISPC_VERSION}/ispc-v${ISPC_VERSION}-${ISPC_SUFFIX}" CACHE STRING "")

set(_ISPC_SRC_LIB_NAME lib)
set(_ISPC_DST_LIB_NAME lib)

ExternalProject_Add(ispc
  PREFIX ${SUBPROJECT_NAME}
  STAMP_DIR ${SUBPROJECT_NAME}/stamp
  SOURCE_DIR ${SUBPROJECT_NAME}/src
  BINARY_DIR ${SUBPROJECT_NAME}
  URL ${ISPC_URL}
  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_COMMAND
    COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/bin ${INSTALL_DIR_ABSOLUTE}/bin
    COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/${_ISPC_SRC_LIB_NAME} ${INSTALL_DIR_ABSOLUTE}/${_ISPC_DST_LIB_NAME}
    COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include ${INSTALL_DIR_ABSOLUTE}/include
  BUILD_ALWAYS OFF
)

set(ISPC_PATH "${INSTALL_DIR_ABSOLUTE}/bin/ispc${CMAKE_EXECUTABLE_SUFFIX}")
append_cmake_prefix_path(${INSTALL_DIR_ABSOLUTE}/${_ISPC_DST_LIB_NAME}/cmake/ispcrt-${ISPC_VERSION})

