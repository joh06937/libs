# CPU setup

###
 # Configures the CPU
 #
 # @param none
 #
 # @return none
 ##
function(cmlib_cpu_configure)
    if(CONFIG_SOC_FAMILY_STM32)
        include("${CMLIB_CMAKE_DIR}/cpu/stm32.cmake")
        cmlib_cpu_stm32_configure()
    elseif(CONFIG_SOC_HOST)
        # Nothing to do
    else()
        message(FATAL_ERROR "Unsupported CPU family '${CONFIG_SOC_FAMILY_NAME}'")
    endif()
endfunction()
