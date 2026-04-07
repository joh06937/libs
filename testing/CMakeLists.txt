# Testing setup

cmake_minimum_required(VERSION 3.20)

# If this is a project that's including unit testing, configure it to include
# all of our sub-directories as projects
if(CONFIG_UNIT_TESTING)
    include("${CMLIB_CMAKE_DIR}/testing.cmake")
    cmlib_testing_app_configure()

    cmlib_testing_app_add_test_project(example1 "${CMAKE_CURRENT_LIST_DIR}/example1")
    cmlib_testing_app_add_test_project(example2 "${CMAKE_CURRENT_LIST_DIR}/example2")
endif()
