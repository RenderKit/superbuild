# Intel® Rendering Toolkit CMake Superbuild

This CMake script will pull down Intel® Rendering Toolkit libraries and
build them from source. The result is an install directory with everything in
it (`CMAKE_INSTALL_PREFIX`).

Requirements:
- A C++-14-capable compiler and libstdc++.so.6.0.21 or greater.
- CMake 3.12 or greater
- Python 3.6 or greater (including development tools) with the following packages
  - numpy
  - Note: Python 3.9 is validated for Intel® OSPRay Studio's python bindings and supported by Intel® 2022
- Linux system requirements:
  - depending on your linux system, you may need to install X11 and GL development libraries
- For other dependencies, see latest release notes of Intel® Rendering Toolkit components
  - https://github.com/ospray/rkcommon
  - https://github.com/embree/embree
  - https://github.com/OpenImageDenoise/oidn
  - https://github.com/openvkl/openvkl
  - https://github.com/ospray/ospray
  - https://github.com/ospray/ospray_studio
  - https://github.com/OpenPathGuidingLibrary/openpgl
  - https://github.com/ispc/ispc

Run with:

```bash
git clone https://github.com/RenderKit/superbuild
cd superbuild
mkdir build
cd build
cmake ..
cmake --build .
```

To validate OSPRay Studio's python bindings:

```bash
export LD_LIBRARY_PATH=<install_path>/lib
export PYTHONPATH=<install_path>/lib
python3 <build_path>/ospray_studio/source/pysg/tutorial/sgTutorial.py
```

By default, all projects will be installed into `build/install` (if following
the above instructions exactly), unless `CMAKE_INSTALL_PREFIX` is set to
somewhere else.
