# Testing setup

cmake_minimum_required(VERSION 3.20)

# If this is a project that's including unit testing, configure it to include
# all of our sub-directories as projects
if(CONFIG_UNIT_TESTING)
    include("${CMLIB_CMAKE_DIR}/testing.cmake")
    cmlib_testing_add_projects("${CMAKE_CURRENT_LIST_DIR}")
endif()
