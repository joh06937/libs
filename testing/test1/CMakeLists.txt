# Test1 testing project

cmake_minimum_required(VERSION 3.20.0)

set(APP_NAME test1)
find_package(cmlib REQUIRED HINTS "${CMLIB_ROOT_DIR}")

project(${APP_NAME})

# Add our root source code directory, which will pull in source code to build
# for our use in this unit test project
#
# Note that we need to specify both a source directory and a binary directory,
# as we're pulling in code from outside our CMake project directory (thanks,
# CMake).
add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/../../src" "${CMAKE_BINARY_DIR}/test1")

# Add in our own source code with additional tests
target_sources(
    ${APP_NAME}
    PRIVATE
        "${CMAKE_CURRENT_LIST_DIR}/test1.cpp"
)
