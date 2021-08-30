# Intel® oneAPI Rendering Toolkit CMake Superbuild

This CMake script will pull down Intel® oneAPI Rendering Toolkit libraries and
build them from source. The result is an install directory with everything in
it (`CMAKE_INSTALL_PREFIX`).

Requirements:
 - A C++-14-capable compiler and libstdc++.so.6.0.21 or greater.

Recommendations:
 - Python 3.7 is validated for OSPRay Studio's python bindings and supported by oneAPI 2021.4

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
