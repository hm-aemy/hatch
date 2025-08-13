# Software

## Structure

- This folder: base files for the build infrastructure
- `sdk`: common files for the builds
- `hello`: example application
- `smoketest`: smoke test application using all peripherals

## Building

Go to the application that you want to build and run the following commands:

```bash
mkdir build
cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../../riscv32.cmake
make 
```