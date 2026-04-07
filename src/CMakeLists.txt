# Add the current directory to the list of include search paths for the
# project's sources
target_include_directories(
    ${APP_NAME}
    PRIVATE
        "${CMAKE_CURRENT_LIST_DIR}"
)
