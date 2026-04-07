# CMake entry point
#
# This is an example root CMake file for a project. When using CMLib as a
# library (i.e. not running out of this directory as an example project), this
# file will not be run. Instead, CMLib's CMake and Kconfig framework will be
# found by the user's project's CMake, which runs the `find_package()` and
# `add_subdirectory()` on CMLib.
#
# But, when running out of this directory as an example project (or when
# copy-and-pasting this file into another project and running it from there),
# CMake will find this file and start executing from here. Note that CMake won't
# accept any of this from a sub-directory with an "example project" in there, as
# it forces at least `project()` to appear in the root-level CMake file.

cmake_minimum_required(VERSION 3.20.0)

# Set our application's name, which can be anything, as long as everything we
# use from here on out uses the `APP_NAME` variable to name things
set(APP_NAME app)

# Prior to using CMLib, for the sake of this example, manually specify the
# Kconfig declaration and selection files
set(KCONFIG_FILE "${CMAKE_CURRENT_LIST_DIR}/example_app/Kconfig")
set(PROJECT_FILES "${CMAKE_CURRENT_LIST_DIR}/example_app/prj.conf")

# Find our CMake supporting infrastructure, which will handle pulling in our
# Kconfig and selected options, which will in turn drive other things that are
# done for us, like compiler and processor selection
find_package(cmlib REQUIRED HINTS "${CMAKE_CURRENT_LIST_DIR}/cmlib")

# Declare our project
project(${APP_NAME})
add_executable(${APP_NAME})
enable_language(C CXX)

# Add our primary source code directory, which will contain its own CMake
# file(s) that add source code and whatnot
add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/example_app")

# Add our testing directory, which will (potentially) configure unit testing
add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/testing")
