cmake_minimum_required(VERSION 3.16.3)
project(mill)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(${CMAKE_CURRENT_BINARY_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

add_compile_options(-Wall -Wextra -pedantic -std=c++17)
find_program(CXXBRIDGE cxxbridge)

set(CXX_BRIDGE_SRC ${CMAKE_CURRENT_SOURCE_DIR}/../rust/rtl.rs)
set(CXX_BRIDGE_GEN ${CMAKE_CURRENT_BINARY_DIR}/generated.cpp)
set(CXX_BRIDGE_HDR ${CMAKE_CURRENT_BINARY_DIR}/generated.h)
add_custom_command(
  OUTPUT ${CXX_BRIDGE_GEN}
  COMMAND ${CXXBRIDGE} ${CXX_BRIDGE_SRC} -o ${CXX_BRIDGE_GEN}
  DEPENDS ${CXX_BRIDGE_SRC}
)
add_custom_command(
  OUTPUT ${CXX_BRIDGE_HDR}
  COMMAND ${CXXBRIDGE} ${CXX_BRIDGE_SRC} --header -o ${CXX_BRIDGE_HDR}
  DEPENDS ${CXX_BRIDGE_SRC}
)

find_package(verilator
  HINTS $ENV{VERILATOR_ROOT}
)

add_library(
  millrtl SHARED bridge.cpp bridge.h ${CXX_BRIDGE_GEN} ${CXX_BRIDGE_HDR}
)

verilate(
  millrtl
  SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/../rtl/top.sv
  PREFIX rtl
  TRACE_FST
  INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/../rtl
  DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/verilated
  VERILATOR_ARGS --trace-params --trace-structs --top-module top
)

install(TARGETS millrtl)
