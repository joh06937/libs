# Compiler setup

###
 # Configures the toolchain
 #
 # @param none
 #
 # @return none
 ##
function(cmlib_compiler_configure)
    # Generate compile_commands.json, which is useful for debugging or auditing
    # the final build
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

    # Set the magic CMake variable for the toolchain
    set(TOOLCHAIN_PATH "${CONFIG_COMPILER_PATH}")

    # If a compiler path was specified
    #
    # Also, just in case any of the executables are specified, put together a
    # qualified path to the executables' directory.
    if(NOT "${TOOLCHAIN_PATH}" STREQUAL "")
        # If the toolchain isn't an absolute path, assume it's relative to the
        # top-level CMake project file
        if(NOT IS_ABSOLUTE "${TOOLCHAIN_PATH}")
            message(STATUS "Compiler path '${TOOLCHAIN_PATH}' not absolute, assuming relative to '${CMAKE_SOURCE_DIR}'")

            set(TOOLCHAIN_PATH "${CMAKE_SOURCE_DIR}/${TOOLCHAIN_PATH}")
        endif()

        if(NOT EXISTS "${TOOLCHAIN_PATH}")
            message(FATAL_ERROR "Compiler path '${CONFIG_COMPILER_PATH}' not found")
        endif()

        set(toolchainPathPrefix "${TOOLCHAIN_PATH}/")
    else()
        set(toolchainPathPrefix "")
    endif()

    # If any of the assembler, C, or C++ compiler executables are specified,
    # handle setting them for CMake
    if(NOT "${CONFIG_COMPILER_ASM_EXE}" STREQUAL "")
        set(CMAKE_ASM_COMPILER  "${toolchainPathPrefix}${CONFIG_COMPILER_ASM_EXE}" CACHE INTERNAL "")
    endif()
    if(NOT "${CONFIG_COMPILER_C_EXE}" STREQUAL "")
        set(CMAKE_C_COMPILER    "${toolchainPathPrefix}${CONFIG_COMPILER_C_EXE}"   CACHE INTERNAL "")
    endif()
    if(NOT "${CONFIG_COMPILER_CPP_EXE}" STREQUAL "")
        set(CMAKE_CXX_COMPILER  "${toolchainPathPrefix}${CONFIG_COMPILER_CPP_EXE}" CACHE INTERNAL "")
    endif()

    # Set the C/C++ standards
    set(CMAKE_C_STANDARD    ${CONFIG_COMPILER_C_STANDARD}   CACHE INTERNAL "")
    set(CMAKE_CXX_STANDARD  ${CONFIG_COMPILER_CPP_STANDARD} CACHE INTERNAL "")

    # "Generic" is always used for cross compiling
    set(CMAKE_SYSTEM_NAME Generic CACHE INTERNAL "")

    # Handle the specific toolchain we're using
    if(CONFIG_COMPILER_IAR)
        include("${CMLIB_CMAKE_DIR}/compiler/iar.cmake")
        cmlib_compiler_iar_configure()
    elseif(CONFIG_COMPILER_HOST)
        include("${CMLIB_CMAKE_DIR}/compiler/host.cmake")
        cmlib_compiler_host_configure()
    else()
        message(FATAL_ERROR "Unknown compiler '${CONFIG_COMPILER_NAME}'")
    endif()
endfunction()

###
 # Adds compiler options for a specific target
 #
 # @param TARGET
 #      The target to add compile options for
 # @param SOURCES_PATH
 #      The path to the location of sources
 # @param SOURCES_TO_EDIT
 #      The list of sources to add compiler options for
 # @param OPTIONS
 #      The list of compiler options to add
 #
 # @return none
 ##
function(cmlib_compiler_add_compile_options TARGET SOURCES_PATH SOURCES_TO_EDIT OPTIONS)
    if(CONFIG_COMPILER_IAR AND NOT OPTIONS)
        return()
    endif()

    foreach(SOURCE_FILE ${SOURCES_PATH})
        cmake_path(GET SOURCE_FILE FILENAME SOURCE_FILENAME)

        if(NOT SOURCE_FILENAME IN_LIST SOURCES_TO_EDIT)
            continue()
        endif()

        get_source_file_property(
            COMPILE_OPTIONS ${SOURCE_FILE}
            TARGET_DIRECTORY ${APP_NAME}
            COMPILE_OPTIONS
        )

        if(NOT COMPILE_OPTIONS)
            set(COMPILE_OPTIONS "")
        endif()

        list(APPEND COMPILE_OPTIONS ${OPTIONS})

        set_source_files_properties(
            ${SOURCE_FILE}
            TARGET_DIRECTORY ${APP_NAME}
            PROPERTIES COMPILE_OPTIONS "${COMPILE_OPTIONS}"
        )
    endforeach()
endfunction()
