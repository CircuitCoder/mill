Mill
=======================

> \[verb\] (transitive) To grind or otherwise process in a mill or other machine.

## What's in the box?
- A test framework, which test the CPU against:
  - riscv/riscv-tests
- A educational 5-stage(?) RV32I implementation with SystemVerilog
- Documentation (in zh-CN), including
  - The usage of the test framework
  - The design of the CPU implementation
  - The timeline of the development

## CPU interface

See `rtl/top.sv`

## Run unit test

To run the unit test included in this repository, you will need to install the following dependencies first:

- verilator, tested on 4.0.36
- GCC (g++) 10, tested on 10.2.0. clang won't work (for now) because the lack of standard concept library.
- rust (rustc, cargo), tested on 1.48.0-nightly
- cxxbridge, tested on 0.4.7. This binary is provided in the `cxxbridge-cmd` rust crate.
- cmake, tested on 3.18.3. You may want to change the minimal version specified in the bridge/CMakeLists.txt to match your cmake version.
- ninja or makefile, tested on ninja 1.10.1. Ninja is recommended for better build dependency handling.

Then, just simple invoke `cargo run -- -h` and you will get the help for the test runner.

A full run-through on a freshly installed ArchLinux:

```bash
pacman -Syy
pacman -S base-devel verilator rustup ninja cmake git
rustup install nightly
cargo install cxxbridge-cmd

git clone https://github.com/CircuitCoder/mill.git
cd mill
cargo run -- -h
```

## License
All source code and related materials in this repository is distributed under the MIT license. You may get a copy of the license text in the LICENSE file located in the root of this repository.
