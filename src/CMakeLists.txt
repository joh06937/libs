# Root source code CMake file

if(NOT CONFIG_IS_TEST)
    # Add source code files
    target_sources(
        ${APP_NAME}
        PRIVATE
            "${CMAKE_CURRENT_LIST_DIR}/main.cpp"
    )
endif()

# Add include paths to header files
target_include_directories(
    ${APP_NAME}
    PRIVATE
        "${CMAKE_CURRENT_LIST_DIR}"
)
