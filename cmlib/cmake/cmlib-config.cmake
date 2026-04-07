# Root CMake file
#
# This file has a special naming scheme that allows an invocation of
# `find_package()` to find this CMake infrastructure and run it as part of
# whatever project invoked said function.
#
# That being said, we'll only keep the smallest amount of necessary code in this
# special file, and defer to our own file, which we have full naming control
# over and whatnot.

include("${CMAKE_CURRENT_LIST_DIR}/boilerplate.cmake")
cmlib_configure()
