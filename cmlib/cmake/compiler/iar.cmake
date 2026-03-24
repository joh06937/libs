# IAR compiler
#
# Most (all?) of the things set in here are purely for the benefit of the CMake
# compiler engine.

###
 # Configures the IAR compiler
 #
 # Performs basic toolchain setup (see cmake-toolchain documentation) as well as
 # adding universal compiler/linker options.
 #
 # @param none
 #
 # @return none
 ##
function(cmlib_compiler_iar_configure)
    # "Generic" is always used for cross compiling
    set(CMAKE_SYSTEM_NAME               Generic         CACHE INTERNAL "")

    set(CMAKE_SYSTEM_PROCESSOR          arm)

    # This will prevent the IAR linker from being run during try_compile()
    set(CMAKE_TRY_COMPILE_TARGET_TYPE   STATIC_LIBRARY  CACHE INTERNAL "")

    # Set the C/C++ standards
    set(CMAKE_C_STANDARD                99              CACHE INTERNAL "")
    set(CMAKE_CXX_STANDARD              17              CACHE INTERNAL "")

    # Compile the paths to our compiler executables
    set(CMAKE_ASM_COMPILER              "${CONFIG_COMPILER_PATH}/arm/bin/iasmarm.exe"  CACHE INTERNAL "")
    set(CMAKE_C_COMPILER                "${CONFIG_COMPILER_PATH}/arm/bin/iccarm.exe"   CACHE INTERNAL "")
    set(CMAKE_CXX_COMPILER              "${CONFIG_COMPILER_PATH}/arm/bin/iccarm.exe"   CACHE INTERNAL "")

    # Figure out our optimization level
    if(CONFIG_OPTIMIZATION_LEVEL_OFF)
        set(optimizationLevel n)
    elseif(CONFIG_OPTIMIZATION_LEVEL_LOW)
        set(optimizationLevel l)
    elseif(CONFIG_OPTIMIZATION_LEVEL_MEDIUM)
        set(optimizationLevel m)
    elseif(CONFIG_OPTIMIZATION_LEVEL_HIGH)
        set(optimizationLevel h)
    elseif(CONFIG_OPTIMIZATION_LEVEL_HIGH_SIZE)
        set(optimizationLevel hz)
    elseif(CONFIG_OPTIMIZATION_LEVEL_HIGH_SPEED)
        set(optimizationLevel hs)
    else()
        message(FATAL_ERROR "Unknown IAR optimization level '${CONFIG_OPTIMIZATION_LEVEL}'")
    endif()

    add_compile_options(
        -r
        $<$<COMPILE_LANGUAGE:ASM>:-s+>
        $<$<COMPILE_LANGUAGE:ASM>:-w+>
        $<$<COMPILE_LANGUAGE:ASM>:-M<$<ANGLE-R>>

        $<$<COMPILE_LANGUAGE:C>:-e>

        $<$<COMPILE_LANGUAGE:C,CXX>:-O${optimizationLevel}>

        $<$<COMPILE_LANGUAGE:C,CXX>:--endian=little>
        $<$<COMPILE_LANGUAGE:C,CXX>:--warnings_are_errors>

        $<$<COMPILE_LANGUAGE:C,CXX>:--dlib_config>
        $<$<COMPILE_LANGUAGE:C,CXX>:${CONFIG_COMPILER_PATH}/arm/inc/c/DLib_Config_Full.h>

        $<$<COMPILE_LANGUAGE:C>:--use_c++_inline>

        $<$<COMPILE_LANGUAGE:CXX>:--no_exceptions>
        $<$<COMPILE_LANGUAGE:CXX>:--no_rtti>
        $<$<COMPILE_LANGUAGE:CXX>:--no_static_destruction>
    )

    add_link_options(
        --redirect __write=__write_buffered
        --entry __iar_program_start
        --vfe
        --no_exceptions
        --text_out locale
        --advanced_heap
        --no_out_extension
    )
endfunction()
