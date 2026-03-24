# Kconfig

find_package(Python REQUIRED COMPONENTS Interpreter)

###
 # Gets the configuration lines from the project's Kconfig file
 #
 # @param OUTPUT_NAME
 #		The name of the output variable for the configuration lines
 # @param FILE
 #		The name of the file whose configurations to get
 #
 # @return none
 ##
function(cmlib_kconfig_get_configs OUTPUT_NAME FILE)
	# Get the Kconfig contents
	file(READ "${FILE}" configs)

	# Translate the file into something CMake can iterate over
	string(REPLACE "\n" ";" configs "${configs}")

	# Clear out comments and empty lines
	foreach(config IN LISTS configs)
		# If this line is empty or it's a comment, skip it
		if("${config}" STREQUAL "" OR "${config}" MATCHES "[ ]*#.*")
			continue()
		endif()

		# Got a valid configuration, so append it to the list
		list(APPEND cleanedConfigs "${config}")
	endforeach()

	message(VERBOSE "Got configs '${cleanedConfigs}'")

	# Set their output variable
	set(${OUTPUT_NAME} "${cleanedConfigs}" PARENT_SCOPE)
endfunction()

###
 # Parses a Kconfig line into its name and value
 #
 # @param CONFIG
 #		The Kconfig line to parse
 # @param NAME_OUTPUT_NAME
 #		The name of the output variable for the configuration's name
 # @param VALUE_OUTPUT_NAME
 #		The name of the output variable for the configuration's value
 #
 # @return none
 ##
function(cmlib_kconfig_parse_config CONFIG NAME_OUTPUT_NAME VALUE_OUTPUT_NAME)
	string(REGEX REPLACE "(.*)=.*" "\\1" configName "${CONFIG}")
	string(REGEX REPLACE ".*=(.*)" "\\1" configValue "${CONFIG}")

	# Strip quotation marks from values
	string(REGEX REPLACE "\"(.*)\"" "\\1" configValue "${configValue}")

	#message(VERBOSE "Parsed '${CONFIG}' into '${configName}' and '${configValue}'")

	set(${NAME_OUTPUT_NAME} "${configName}" PARENT_SCOPE)
	set(${VALUE_OUTPUT_NAME} "${configValue}" PARENT_SCOPE)
endfunction()

###
 # Checks if the Kconfig output file needs to be reinitialized
 #
 # @param OUTPUT_NAME
 #		The name of the output variable for the reinitialization boolean
 # @param PROJECT_FILES
 #		The project configuration file(s) to use
 # @param MASTER_CONFIG
 #		The master configuration file that get initialized
 # @param DUMMY_CONFIG
 #		The dummy config file that is used to check for file changes
 #
 # @return none
 ##
function(cmlib_kconfig_check_needs_reinitialization OUTPUT_NAME PROJECT_FILES MASTER_CONFIG_FILE DUMMY_CONFIG_FILE)
	# If we haven't put down our dummy tracker for monitoring the project file's
	# modification timestamp, reinitialize the master configuration file
	if(NOT EXISTS "${DUMMY_CONFIG_FILE}" OR NOT EXISTS "${MASTER_CONFIG_FILE}")
		message(STATUS "No Kconfig generated yet, initializing")

		set(${OUTPUT_NAME} TRUE PARENT_SCOPE)

		return()
	endif()

	# If any of the project files have been modified since we last put down the
	# dummy tracker, then we need to reinitialize the master configuration file
	foreach(projectFile IN LISTS PROJECT_FILES)
		if("${projectFile}" IS_NEWER_THAN "${DUMMY_CONFIG_FILE}")
			message(STATUS "Project file '${projectFile}' has been modified, initializing")

			set(${OUTPUT_NAME} TRUE PARENT_SCOPE)

			return()
		endif()
	endforeach()

	# Make sure the project file hasn't changed to a completely different
	# file
	file(READ "${DUMMY_CONFIG_FILE}" dummyConfigFileContents)

	if(NOT "${dummyConfigFileContents}" STREQUAL "${PROJECT_FILES}")
		message(STATUS "Project file(s) have changed location(s), initializing")

		set(${OUTPUT_NAME} TRUE PARENT_SCOPE)

		return()
	endif()

	message(STATUS "Project file not out of date, leaving alone")

	set(${OUTPUT_NAME} FALSE PARENT_SCOPE)
endfunction()

###
 # Gets the value of configurations and puts them into the parent scope
 #
 # @param CONFIG_NAME
 #		The configuration whose value to get; can be a regular expression
 # @param FILE
 #		Optionally, the name of the file whose configurations to get
 #
 # @return none
 ##
function(cmlib_kconfig_pull CONFIG_NAME FILE)
	# If they didn't specify the file, default it to the full output
	if("${FILE}" STREQUAL "")
		set(FILE "${CMAKE_CURRENT_BINARY_DIR}/.config")

		message(VERBOSE "Finding configuration in default output file '${FILE}'")
	endif()

	message(VERBOSE "Looking for configuration '${CONFIG_NAME}' in '${FILE}'")

	# Get the configurations
	cmlib_kconfig_get_configs(configs "${FILE}")

	# Find the lines with the configurations
	foreach(config IN LISTS configs)
		message(VERBOSE "Checking '${config}'")

		# Parse this configuration
		cmlib_kconfig_parse_config("${config}" configName configValue)

		# If this isn't what they want, skip it
		if(NOT "${configName}" MATCHES "${CONFIG_NAME}")
			continue()
		endif()

		message(VERBOSE "Configuration matched")

		# If this configuration already exists, don't override it
		if(${configName})
			# If the values don't match, warn about it
			if(NOT "${${configName}}" STREQUAL "${configValue}")
				message(WARNING "Kconfig configuration '${configName}' ('${configValue}') already set ('${${configName}}'), skipping it")
			endif()

			continue()
		endif()

		# Got it, so raise it
		set(${configName} "${configValue}" PARENT_SCOPE)
	endforeach()
endfunction()

###
 # Configures Kconfig
 #
 # This function will produce configurations that directly impact the configure
 # step of CMake. That is, we pipe the output of the Kconfig process into the
 # CMake environment and allow CMake to do things like:
 #
 #		if(CONFIG_THING)
 #			add_subdirectory(...)
 #		endif()
 #
 # There isn't a good way to tell CMake about the dependency on CONFIG_THING
 # without including some kind of configuration file. If that file has all of
 # the configurations, then it's basically a wash: all CMakes that use a
 # configuration will become out of date because of their dependent file
 # changing, and we'll likely have a massive reconfigure and build anyway.
 # Alternatively, each configuration could be in its own file, thus keeping the
 # dependencies down further and limiting the rebuilds, but that can escalate
 # pretty quickly. Given how seldom Kconfig sources and project configurations
 # change, it's just easier to rerun CMake configuration when a Kconfig changes.
 #
 # As such, invoking this function means we're running CMake configuration and
 # thus we should regenerate Kconfig. As part of this process, we'll also mark
 # all of the Kconfig sources files as top-level triggers to rerun CMake
 # configuration using CMAKE_CONFIGURE_DEPENDS.
 #
 # @param KCONFIG_FILE
 #		The project root Kconfig file
 # @param PROJECT_FILES
 #		The project configuration file(s) to use
 #
 # @return none
 ##
function(cmlib_kconfig_setup KCONFIG_FILE PROJECT_FILES)
	set(autoconfFile		"${CMAKE_CURRENT_BINARY_DIR}/include/generated/autoconf.h")
	set(masterConfigFile	"${CMAKE_CURRENT_BINARY_DIR}/.config")
	set(dummyConfigFile		"${CMAKE_CURRENT_BINARY_DIR}/kconfig-dummy.txt")
	set(kconfigTrackFile	"${CMAKE_CURRENT_BINARY_DIR}/kconfig-files.txt")

	# Set the Kconfig path for the Kconfig command-line tools
	#
	# Note that we have to set the KCONFIG_CONFIG environment variable for the
	# command-line Kconfig tools, as they don't have flags for it (for some damn
	# reason) and otherwise defaults to a .config file in the current directory.
	set(ENV{KCONFIG_CONFIG} "${masterConfigFile}")

	# Make a simple target for running menuconfig
	add_custom_target(
		menuconfig

		COMMAND
			${Python_EXECUTABLE} -m menuconfig
				"${KCONFIG_FILE}"

		USES_TERMINAL
	)

	# Also make one for guiconfig
	add_custom_target(
		guiconfig

		COMMAND
			${Python_EXECUTABLE} -m guiconfig
				"${KCONFIG_FILE}"
	)

	# Allow sources to include the generated Kconfig output
	include_directories("${CMAKE_CURRENT_BINARY_DIR}/include/generated")

	# Make the directories for our outputs
	file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include/generated")

	# Check if we should reinitialize
	cmlib_kconfig_check_needs_reinitialization(reinitialize "${PROJECT_FILES}" "${masterConfigFile}" "${dummyConfigFile}")

	# If we need to reinitialize the master configuration file, do so
	if(${reinitialize})
		message(STATUS "Initializing Kconfig with project files '${PROJECT_FILES}'")

		# Make the master configuration file
		#
		# Note that the "WRITE" option will always overwrite an existing file
		# ("APPEND" appends).
		file(WRITE "${masterConfigFile}" "")

		# Copy over the contents of each project file to the master
		# configuration file
		foreach(projectFile IN LISTS PROJECT_FILES)
			file(READ "${projectFile}" projectFileContents)

			file(APPEND "${masterConfigFile}" "${projectFileContents}")
		endforeach()

		# Initialize our project configuration file tracker with the project
		# configuration file's name
		#
		# Note that the "WRITE" option will always overwrite an existing file
		# ("APPEND" appends).
		file(WRITE "${dummyConfigFile}" "${PROJECT_FILES}")
	endif()

	message(STATUS "Running Kconfig...")

	# Do a one-time manual generation of Kconfig
	#
	# Note that we're outputting the list of Kconfig files used during the
	# generation of the output, which we'll use next.
	execute_process(
		COMMAND
			${Python_EXECUTABLE} -m genconfig
				--header-path "${autoconfFile}"
				--config-out "${masterConfigFile}"
				--file-list "${kconfigTrackFile}"
				"${KCONFIG_FILE}"
		RESULT_VARIABLE
			result
	)

	if(NOT ${result} EQUAL 0)
		message(FATAL_ERROR "Kconfig failed (${result})")
	endif()

	message(STATUS "Kconfig generated include-able file '${autoconfFile}'")
	message(STATUS "    and user-friendly file '${masterConfigFile}")

	# Get the Kconfig file list file contents
	file(READ "${kconfigTrackFile}" files)

	# Translate the file into something CMake can iterate over
	string(REPLACE "\n" ";" files "${files}")

	# Append our input configuration files to the dependency file list
	foreach(file IN LISTS PROJECT_FILES)
		list(APPEND files "${file}")
	endforeach()

	list(APPEND files "${masterConfigFile}")

	# Make a top-level full CMake reconfigure dependency on our Kconfig files
	# used during generation so that we're rerun any time one of them changes
	foreach(file IN LISTS files)
		message(VERBOSE "Adding CMake reconfigure dependency for Kconfig file '${file}'")

		set_property(
			DIRECTORY
			APPEND
			PROPERTY
				CMAKE_CONFIGURE_DEPENDS
			${file}
		)
	endforeach()

	message(STATUS "Pulling Kconfig configurations into CMake's context")

	# Get the Kconfigs
	cmlib_kconfig_get_configs(masterConfigs "${masterConfigFile}")

	foreach(masterConfig IN LISTS masterConfigs)
		# Get the configuration's name and value
		cmlib_kconfig_parse_config("${masterConfig}" masterConfigName masterConfigValue)

		# If the configuration's value isn't set, skip it
		if("${masterConfigValue}" STREQUAL "n")
			message(VERBOSE "Kconfig configuration '${masterConfigName}' not set in master file, skipping it")

			continue()
		endif()

		# Keep track of this specific configuration name using something more
		# unique to just us
		#
		# We want to be able to come back on a partial rebuild -- triggered off
		# of our dependencies above -- and update any configuration variable
		# changes we can find (since what we set above is cached). Potentially
		# we'll need to unset some configuration variables, but we can't depend
		# on a list of all configurations that weren't set during the Kconfig
		# run; we can only really depend on the ones set (some do show up as 'X
		# unset', but others might not be included like that if their Kconfig
		# dependencies weren't met and they weren't available for use in the
		# first place). We could be a brute and unset *everything* with our
		# 'CONFIG_' prefix, but that could lead to some bad things, so instead
		# we'll make a more unique name and set the global variables again with
		# those names. Then we can come back on a rebuid and unset all the
		# variables we can find in that list, avoiding any other systems'
		# 'CONFIG_' variables.
		#
		# We will want to be a little more efficient about unsetting them to
		# optimize what gets rebuilt, so for now only put this in a list of
		# variables we'll want to set.
		list(APPEND newInternalConfigs "KCONFIG_${masterConfigName}=${masterConfigValue}")
	endforeach()

	# Get all of our previously-set configurations
	get_cmake_property(allVariables VARIABLES)

	# Find our configurations from last time
	#
	# Note that we'll clean up the list, since it'll get a leading semicolon and
	# then double semicolons between each item due to how we're doing the
	# matching. We could filter empty list items out in our iterations, or we
	# could just do a quick regex replacement.
	string(REGEX MATCHALL "(^|;)KCONFIG_CONFIG_[A-Za-z0-9_]*" previousInternalConfigs "${allVariables}")
	string(REGEX REPLACE ";(KCONFIG_CONFIG_[A-Za-z0-9_]*)" "\\1" previousInternalConfigs "${previousInternalConfigs}")

	message(VERBOSE "Found previous Kconfig configurations '${previousInternalConfigs}'")
	message(VERBOSE "Have new Kconfig configurations '${newInternalConfigs}'")

	# Go through all of our previous configurations and unset any whose value
	# has changed
	foreach(previousInternalConfig IN LISTS previousInternalConfigs)
		message(VERBOSE "Checking if previous Kconfig '${previousInternalConfig}' still set")

		# Guilty until proven innocent
		set(found FALSE)

		# See if this previous configuration is in our new list of
		# configurations
		foreach(newInternalConfig IN LISTS newInternalConfigs)
			cmlib_kconfig_parse_config("${newInternalConfig}" newInternalConfigName newInternalConfigValue)

			#message(VERBOSE "Checking against '${newInternalConfig}'...")

			# If this isn't the configuration, keep looking
			if(NOT "${newInternalConfigName}" STREQUAL "${previousInternalConfig}")
				continue()
			endif()

			message(VERBOSE "Configuration still set")

			# We found the old configuration in the list of new ones
			set(found TRUE)

			break()
		endforeach()

		# If we found this, nothing to unset
		#
		# We'll override the value if we need to in the next step.
		if(${found})
			continue()
		endif()

		message(VERBOSE "Configuration not set anymore, removing it")

		# Get the non-unique name for this
		string(REGEX REPLACE "KCONFIG_(.*)" "\\1" previousConfig "${previousInternalConfig}")

		message(VERBOSE "Removing configuration '${previousInternalConfig}' (and '${previousConfig}')")

		# Remove the uniquely- and non-uniquely-named variables we had set last
		# time
		unset(${previousInternalConfig} CACHE)
		unset(${previousConfig} CACHE)
	endforeach()

	foreach(newInternalConfig IN LISTS newInternalConfigs)
		cmlib_kconfig_parse_config("${newInternalConfig}" newInternalConfigName newInternalConfigValue)

		# Get the non-unique name for this
		string(REGEX REPLACE "KCONFIG_(.*)" "\\1" newConfigName "${newInternalConfigName}")

		# If the configuration already exists and its value is correct, skip
		# setting it again
		if(${newInternalConfigName} AND ${newConfigName})
			if("${${newInternalConfigName}}" STREQUAL "${newInternalConfigValue}" AND
			   "${${newConfigName}}" STREQUAL "${newInternalConfigValue}")
				message(VERBOSE "Configuration '${newInternalConfigName}' (and '${newConfigName}') already set to correct value '${newInternalConfigValue}'")

				continue()
			endif()

			message(VERBOSE "Setting Kconfig configuration '${newInternalConfigName}' (and '${newConfigName}') to '${newInternalConfigValue}' (from '${${newInternalConfigName}}')")
		else()
			message(VERBOSE "Setting Kconfig configuration '${newInternalConfigName}' (and '${newConfigName}') to '${newInternalConfigValue}'")
		endif()

		set(${newInternalConfigName} "${newInternalConfigValue}" CACHE INTERNAL "")
		set(${newConfigName} "${newInternalConfigValue}" CACHE INTERNAL "")
	endforeach()
endfunction()
