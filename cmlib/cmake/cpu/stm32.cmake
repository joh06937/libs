# STM32-specific

###
 # Configures the STM32 CPU
 #
 # @param none
 #
 # @return none
 ##
function(cmlib_cpu_stm32_configure)
    # STM32s are ARMs
    set(CMAKE_SYSTEM_PROCESSOR arm CACHE INTERNAL "")

    if(CONFIG_CPU_CORTEX_M7)
        if(CONFIG_COMPILER_IAR)
            add_compile_options(
                --cpu Cortex-M7
                --fpu VFPv5_d16
            )
        else()
            message(FATAL_ERROR "Unsupported STM32 compiler '${CONFIG_COMPILER_NAME}'")
        endif()

    else()
        message(FATAL_ERROR "Unsupported STM32 CPU '${CONFIG_SOC_NAME}'")
    endif()
endfunction()
