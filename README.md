# Intel® oneAPI Rendering Toolkit CMake Superbuild

This CMake script will pull down Intel® oneAPI Rendering Toolkit libraries and
build them from source. The result is an install directory with everything in
it (`CMAKE_INSTALL_PREFIX`).

Run with:

```bash
git clone https://github.com/RenderKit/superbuild
cd superbuild
mkdir build
cd build
cmake ..
cmake --build .
```

By default, all projects will be installed into `build/install` (if following
the above instructions exactly), unless `CMAKE_INSTALL_PREFIX` is set to
somewhere else.
