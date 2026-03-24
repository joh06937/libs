# CMake entry point
#
# This is the root CMake file for a project. When running out of this directory,
# CMake will find this file and start executing from here.

cmake_minimum_required(VERSION 3.20.0)

# Set our application's name, which can be anything, as long as everything we
# use from here on out uses the `APP_NAME` variable to name things
set(APP_NAME app)

# Find our CMake supporting infrastructure, which will handle pulling in our
# Kconfig and selected options, which will in turn drive other things that are
# done for us, like compiler and processor selection
find_package(cmlib REQUIRED HINTS "${CMAKE_CURRENT_LIST_DIR}/cmlib")

# Declare our project
project(${APP_NAME})
enable_language(C CXX ASM)

# Add our primary source code directory, which will contain its own CMake
# file(s) that add source code and whatnot
add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/src")

# Add our testing directory, which will (potentially) configure unit testing
add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/testing")
