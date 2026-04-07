# Host compiler
#
# Most (all?) of the things set in here are purely for the benefit of the CMake
# compiler engine.

###
 # Configures the host's compiler
 #
 # Performs basic toolchain setup (see cmake-toolchain documentation) as well as
 # adding universal compiler/linker options.
 #
 # @param none
 #
 # @return none
 ##
function(cmlib_compiler_host_configure)
    # This will prevent the IAR linker from being run during try_compile()
    set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY CACHE INTERNAL "")

    add_compile_options(
        -fdata-sections
        -ffunction-sections
    )

    add_link_options(
        -Wl,--gc-sections
    )
endfunction()
