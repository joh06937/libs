# CMLib OS configurations

menu "OS"
    choice
        prompt "OS Selection"
        help
            Select the OS to use

        config OS_BAREMETAL
            bool "Baremetal"
            help
                Do not use an OS; instead target 'baremetal'

        config OS_FREERTOS
            bool "FreeRTOS"
            help
                Use FreeRTOS as this project's operating system

        config OS_HOST
            bool "Host OS"
            help
                Use the host system as this project's operating system
    endchoice

    config OS_NAME
        string
        default "Baremetal" if OS_BAREMETAL
        default "FreeRTOS" if OS_FREERTOS
        default "Host" if OS_HOST
        default "<unconfigured>"
        help
            The human-readable name of the selected OS

            This is a helper string configuration. This option should never be
            configured manually; it is automatically configured based on the
            various `OS_X` options. It can be used, however, such as in debug
            message output.
endmenu
