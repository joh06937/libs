# Testing CMake

cmake_minimum_required(VERSION 3.20)

include(ExternalProject)

###
 # Adds an external unit test project
 #
 # @param PROJECT_NAME
 #      The name of the project
 # @param PROJECT_DIR
 #      The directory of the project
 #
 # @return none
 ##
function(cmlib_testing_add_test_project PROJECT_NAME PROJECT_DIR)
    # Add the project directory as an external project
    ExternalProject_Add(
        ${PROJECT_NAME}

        # It appears we must specify this here
        SOURCE_DIR
            "${PROJECT_DIR}"

        # Pass along some important things for the unit test project's
        # environment
        #
        # The C/C++ standards are to try our best to make sure the conditions
        # that the code is compiled under for unit testing most closely matches
        # that which the code will be compiled under for on-target use.
        #
        # The CMLib CMake directory is to allow the unit testing CMake code to
        # more easily find the CMLib stuff once the new project is made (since
        # it'll be done as an "external project" and won't inherit everything we
        # currently have in our environment).
        CMAKE_CACHE_ARGS
            -DCMAKE_C_STANDARD:STRING=${CMAKE_C_STANDARD}
            -DCMAKE_CXX_STANDARD:STRING=${CMAKE_CXX_STANDARD}
            -DCMLIB_CMAKE_DIR:STRING=${CMLIB_CMAKE_DIR}
            -DCMLIB_ROOT_DIR:STRING=${CMLIB_ROOT_DIR}

        # Nothing needed to install this
        INSTALL_COMMAND
            ""

        # Always try to keep the project up-to-date
        #
        # CMake doesn't default to expecting external projects to have their
        # sources changing.
        BUILD_ALWAYS
            TRUE
    )

    # Find where the unit test project's output directory will be, which is
    # where the ctest stuff will be spit out
    ExternalProject_Get_Property(
        ${PROJECT_NAME}
            BINARY_DIR
    )

    # Make a command for running the ctest output
    add_custom_target(
        run_ctest_on_${PROJECT_NAME}

        COMMAND
            ctest --test-dir "${BINARY_DIR}" --output-on-failure

        USES_TERMINAL
    )

    # Make a dependency on the build output to provide a means to hook into this
    # and run it from our uber project
    add_dependencies(
        run_ctest_on_${PROJECT_NAME}
            ${PROJECT_NAME}
    )
endfunction()

###
 # Configures a directory containing test projects
 #
 # @param ROOT_DIR
 #      The root directory containing test sub-directories
 #
 # @return none
 ##
function(cmlib_testing_add_projects ROOT_DIR)
    # Make a list of everything in the directory
    file(GLOB children "${ROOT_DIR}/*")

    # Make a list of just the sub-directories
    set(directories "")

    foreach(child ${children})
        # If this is a directory
        if(IS_DIRECTORY ${child})
            # Note this project
            list(APPEND directories ${child})
        endif()
    endforeach()

    # Make a target for triggering all of the tests using a single command
    add_custom_target(run_ctest)

    # Add each directory we found as a new test project
    foreach(directory IN LISTS directories)
        # Get its relative name, which we'll need for naming the project in
        # addition to adding its directory
        file(RELATIVE_PATH projectName "${CMAKE_CURRENT_LIST_DIR}" "${directory}")

        # Add the test project
        cmlib_testing_add_test_project("${projectName}" "${directory}")

        # Make the custom single-point target depend on the command that invokes
        # this project's tests
        add_dependencies(
            run_ctest
                run_ctest_on_${projectName}
        )
    endforeach()

    # If the unit tests should be run each build, make a dependency between the
    # app and the unit tests being run
    if(CONFIG_ALWAYS_RUN_UNIT_TESTING)
        add_dependencies(
            ${APP_NAME}
                run_ctest
        )
    endif()
endfunction()
