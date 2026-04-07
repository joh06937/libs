### Get the Kconfig setup file
 #
 # @param OUTPUT_NAME
 #      The name of the variable to output the Kconfig setup file to
 #
 # @return none
 ##
function(_cmlib_get_kconfig_file OUTPUT_NAME)
    set(defaultKconfigSetupFile "${CMAKE_SOURCE_DIR}/Kconfig")

    # If the user hasn't overridden their Kconfig file, use the default
    #
    # The Kconfig file is allowed to not exist (though we'll still sanity check
    # if the user overrides its location, since why would they do that if it
    # didn't exist?), so we won't check that the default file exists
    if(NOT DEFINED KCONFIG_FILE)
        message(STATUS "Using default Kconfig file path '${defaultKconfigSetupFile}'")

        set(${OUTPUT_NAME} "${defaultKconfigSetupFile}" PARENT_SCOPE)

        return()
    endif()

    message(STATUS "Using overridden Kconfig file path '${KCONFIG_FILE}'")

    # Make sure the user didn't goof their file's location
    if(NOT EXISTS "${KCONFIG_FILE}")
        message(FATAL_ERROR "Project Kconfig file '${KCONFIG_FILE}' doesn't exist")
    endif()

    set(${OUTPUT_NAME} "${KCONFIG_FILE}" PARENT_SCOPE)
endfunction()

###
 # Gets the list of Kconfig input configuration files
 #
 # @param OUTPUT_NAME
 #      The name of the variable to output the Kconfig input configuration files
 #      to
 #
 # @return none
 ##
function(_cmlib_get_project_files OUTPUT_NAME)
    set(defaultProjectFile "${CMAKE_SOURCE_DIR}/prj.conf")
    set(defaultUserProjectFile "${CMAKE_SOURCE_DIR}/prj-user.conf")

    # Store things in a new variable so we don't manage to muck up (or fail to
    # muck up) the global one
    set(projectFiles "${PROJECT_FILES}")

    # If PROJECT_FILES wasn't defined, use the default
    if(NOT projectFiles)
        message(STATUS "Using default project configuration file path '${defaultProjectFile}'")

        set(projectFiles "${defaultProjectFile}")
    else()
        message(STATUS "Using overrided project configuration file path list ${projectFiles}")

        # We request that PROJECT_FILES be specified with commas separating each
        # file, but CMake prefers them to be separated by semicolons (which is
        # always fun to try and do from a command line), so convert those
        string(REPLACE "," ";" projectFiles "${projectFiles}")
    endif()

    # The project configuration file(s) must exist, even if it's the default
    # one, so make sure they exist
    foreach(projectFile IN LISTS projectFiles)
        if(NOT EXISTS "${projectFile}")
            message(FATAL_ERROR "Project configuration file '${projectFile}' doesn't exist")
        endif()
    endforeach()

    # If the default user configuration file also exists, see if we should add
    # it
    #
    # Note that we'll do this handling regardless of whether or not we used the
    # default project file or were manually given project files. This is because
    # specifying different project file(s) is also a nice mechanism to use to
    # control how to build a given project (i.e. multiple project files to
    # choose from, one for each configuration). We want to be able to provide
    # that means of building a project while also allowing a developer to build
    # said projects with their own configurations layered on top.
    #
    # If something formal needs to build without any external influence, such as
    # CI/CD, then the ignore flag can be used to ensure this handling doesn't
    # include an additional uncontrolled file.
    if(EXISTS "${defaultUserProjectFile}")
        # If we haven't been told to ignore it, include that in the project file
        # list
        if(NOT IGNORE_USER_FILE)
            message(STATUS "Including default user project configuration file '${defaultUserProjectFile}'")

            list(APPEND projectFiles "${defaultUserProjectFile}")
        else()
            message(STATUS "Ignoring default user project configuration file '${defaultUserProjectFile}' (told to)")
        endif()
    endif()

    # Pass the list along to our caller
    set(${OUTPUT_NAME} "${projectFiles}" PARENT_SCOPE)
endfunction()

###
 # Configures CMLib
 #
 # @param none
 #
 # @return none
 ##
function(cmlib_configure)
    ################################################################
    #
    # Start
    #
    ################################################################

    # If the application's name hasn't been set, complain, as we'll need that
    # for some of our handling of things
    if(NOT APP_NAME)
        message(FATAL_ERROR "Must define 'APP_NAME' prior to using CMLib package")
    endif()

    # Make some helper variables for finding our various CMake helpers
    set(CMLIB_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}"     CACHE INTERNAL "")
    set(CMLIB_ROOT_DIR  "${CMAKE_CURRENT_LIST_DIR}/.."  CACHE INTERNAL "")

    ################################################################
    #
    # Kconfig setup
    #
    ################################################################

    # Get the Kconfig setup file
    _cmlib_get_kconfig_file(kconfigFile)

    # Get the Kconfig input configuration files
    _cmlib_get_project_files(projectFiles)

    # Run our Kconfig processing
    include("${CMLIB_CMAKE_DIR}/kconfig.cmake")
    cmlib_kconfig_configure("${kconfigFile}" "${projectFiles}")

    ################################################################
    #
    # Compiler setup
    #
    ################################################################

    # Set up some compiler stuff
    include("${CMLIB_CMAKE_DIR}/compiler/compiler.cmake")
    cmlib_compiler_configure()

    ################################################################
    #
    # CPU setup
    #
    ################################################################

    # Set up our specific CPU
    include("${CMLIB_CMAKE_DIR}/cpu/cpu.cmake")
    cmlib_cpu_configure()
endfunction()
