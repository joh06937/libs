# Testing CMake

cmake_minimum_required(VERSION 3.20)

include(ExternalProject)

###
 # Configures testing as an app project
 #
 # @param none
 #
 # @return none
 ##
function(cmlib_testing_app_configure)
    # Make a target for triggering all of the tests using a single command
    add_custom_target(run_ctest)

    # If the unit tests should be run each build, make a dependency between the
    # app and the unit tests being run
    if(CONFIG_ALWAYS_RUN_UNIT_TESTING)
        add_dependencies(
            ${APP_NAME}
                run_ctest
        )
    endif()
endfunction()

###
 # Adds a test project to the app project
 #
 # @param PROJECT_NAME
 #      A unique name to give the test project
 # @param PROJECT_DIR
 #      The directory of the test project
 #
 # @return none
 ##
function(cmlib_testing_app_add_test_project PROJECT_NAME PROJECT_DIR)
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

    # Make our ctest command being run depend on the project being built (so
    # that it has something to run on)
    add_dependencies(
        run_ctest_on_${PROJECT_NAME}
            ${PROJECT_NAME}
    )

    # Make the overall "run all tests" target depend on ctest being run on the
    # project
    add_dependencies(
        run_ctest
            run_ctest_on_${PROJECT_NAME}
    )
endfunction()

###
 # Configures testing as a test project
 #
 # Note that this is necessarily a macro and not a function, as
 # `enable_testing()` cannot be done in a function.
 #
 # @param none
 #
 # @return none
 ##
macro(cmlib_testing_tester_configure)
    # Do the magic thing that CMake always requires
    enable_testing()

    include(FetchContent)

    FetchContent_Declare(
        googletest
        GIT_REPOSITORY  "https://github.com/google/googletest.git"
        GIT_TAG         d83fee138a9ae6cb7c03688a2d08d4043a39815d
    )

    # Prevent overriding any parent project compiler or linker options
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(googletest)

    # Make sure we always build the gtest project when building our (unit test)
    # app project
    target_link_libraries(
        ${APP_NAME}
        PRIVATE
            gtest_main
    )

    include(GoogleTest)

    # Discover tests, with a timeout value
    #
    # It appears that occasionally (most of the time?) the discovery of tests is
    # taking longer than the default timeout that gtest uses. It's not quite
    # clear why...
    #
    # TODO: Figure out and, if possible, fix (or at least un-hardcode)
    gtest_discover_tests(${APP_NAME} PROPERTIES DISCOVERY_TIMEOUT 15)
endmacro()
