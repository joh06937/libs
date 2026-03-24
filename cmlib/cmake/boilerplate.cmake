# Basic boilerplate setup for all types of projects
#
# This library will allow the calling context to define a few CMake variables to
# drive the CMake and Kconfig configuration process:
#
#		KCONFIG_FILE
#		PROJECT_FILES
#		IGNORE_USER_FILE
#
# Kconfig
#
#   This is a list -- comma-separated -- of the files containing the Kconfig
#   option declarations (typically named `Kconfig` or `Kconfig-foo`).
#
#   If `KCONFIG_FILE` is not specified, a default path of .`/Kconfig` will be
#   used. This file does not need to exist, but if `KCONFIG_FILE` is specified
#   prior to getting here, the file that definition points to must exist. In
#   other words, Kconfig is fully optional -- it can be omitted -- but if it's
#   used, we will check to make sure it's properly configured first.
#
# Project Files
#
#   This is a list -- comma-separated -- of the files containing the Kconfig
#   option selections (typically named `prj.conf` or `prj-foo.conf`).
#
#   If the default user Kconfig configuration file (`prj-user.conf`) is present
#   on the host file system, it will automatically be inputted to the Kconfig
#   process in addition to `PROJECT_FILES`. If `IGNORE_USER_FILE` is defined to
#   a non-false constatnt, or the user file is not pressent, it will not be
#   included.
#
#   If `PROJECT_FILES` is not specified, a default path of `./prj.conf` will be
#   used. The file -- the specified one or the default -- must exist. If the
#   default path is used, the user Kconfig configuration file will still be
#   auto-detected and included (if present).

### Get the Kconfig setup file
 #
 # @param OUTPUT_NAME
 #		The name of the variable to output the Kconfig setup file to
 #
 # @return none
 ##
function(cmlib_get_kconfig_file OUTPUT_NAME)
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
 #		The name of the variable to output the Kconfig input configuration files
 #		to
 #
 # @return none
 ##
function(cmlib_get_project_files OUTPUT_NAME)
	set(defaultProjectFile "${CMAKE_SOURCE_DIR}/prj.conf")

	# If PROJECT_FILE is not defined, use the default
	if(NOT DEFINED PROJECT_FILES)
		message(STATUS "Using default project configuration file path '${defaultProjectFile}'")

		set(PROJECT_FILES "${defaultProjectFile}")
	else()
		message(STATUS "Using overrided project configuration file path list ${PROJECT_FILES}")

		# We request that PROJECT_FILES be specified with commas separating each
		# file, but CMake prefers them to be separated by semicolons (which is
		# always fun to try and do from a command line), so convert those
		string(REPLACE "," ";" PROJECT_FILES "${PROJECT_FILES}")
	endif()

	foreach(projectFile IN LISTS PROJECT_FILES)
		# The project configuration file must exist, even if it's the default one,
		# so make sure it exists
		if(NOT EXISTS "${projectFile}")
			message(FATAL_ERROR "Project configuration file '${projectFile}' doesn't exist")
		endif()
	endforeach()

	set(projectFiles "${PROJECT_FILES}")

	set(defaultUserProjectFile "${CMAKE_SOURCE_DIR}/prj-user.conf")

	# If the default user configuration file exists, and we haven't been told to
	# ignore it, include that in the project file list
	if(NOT IGNORE_USER_FILE AND EXISTS "${defaultUserProjectFile}")
		message(STATUS "Including default user project configuration file '${defaultUserProjectFile}'")

		list(APPEND projectFiles "${defaultUserProjectFile}")
	endif()

	set(${OUTPUT_NAME} "${projectFiles}" PARENT_SCOPE)
endfunction()

################################################################
#
# Start
#
################################################################

# If the application's name hasn't been set, complain, as we'll need that for
# some of our handling of things
if(NOT APP_NAME)
    message(FATAL_ERROR "Must define 'APP_NAME' prior to using CMLib package")
endif()

# Make some helper variables for finding our various CMake helpers
set(CMLIB_CMAKE_DIR	"${CMAKE_CURRENT_LIST_DIR}")
set(CMLIB_ROOT_DIR	"${CMAKE_CURRENT_LIST_DIR}/..")

################################################################
#
# Kconfig setup
#
################################################################

# Get the Kconfig setup file
cmlib_get_kconfig_file(kconfigFile)

# Get the Kconfig input configuration files
cmlib_get_project_files(projectFiles)

# Run our Kconfig processing
include("${CMLIB_CMAKE_DIR}/kconfig.cmake")
cmlib_kconfig_setup("${kconfigFile}" "${projectFiles}")

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

################################################################
#
# Additional project boilerplate
#
################################################################

add_executable(${APP_NAME})

################################################################
#
# gtest-specific handling
#
################################################################

if(CONFIG_IS_TEST)
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

    gtest_discover_tests(${APP_NAME})

    enable_testing()
endif()
