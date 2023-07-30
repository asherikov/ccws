function(ccws_conan_install)
    set(CONAN_PROFILE "$ENV{CCWS_CONAN_HOME}/profiles/default")

    set(PACKAGES ${ARGN})

    message("CCWS: Using conan to install ${PACKAGES}")

    list(TRANSFORM PACKAGES PREPEND "--requires=")

    # https://docs.conan.io/2/examples/extensions/deployers/dev/development_deploy.html
    add_custom_target(
        ccws_conan_install_${PROJECT_NAME} ALL
        COMMAND ${CMAKE_COMMAND} -E echo "CCWS: installing dependencies using conan"
        COMMAND ${CMAKE_COMMAND} -E env CONAN_HOME="$ENV{CCWS_CONAN_HOME}" conan install
            --deployer-folder "${CMAKE_INSTALL_PREFIX}"
            --deployer full_deploy
            --generator CMakeDeps
            --output-folder "${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}/cmake"
            ${PACKAGES}
    )

    if(NOT EXISTS ${CONAN_PROFILE})
        add_custom_target(
            ccws_conan_profile_${PROJECT_NAME}
            COMMAND cmake -E echo "CCWS: initializing conan profile ${CONAN_PROFILE}"
            COMMAND ${CMAKE_COMMAND} -E env CONAN_HOME="$ENV{CCWS_CONAN_HOME}" conan profile detect
        )
        add_dependencies(ccws_conan_install_${PROJECT_NAME} ccws_conan_profile_${PROJECT_NAME})
    endif()



    include(CMakePackageConfigHelpers)
    file(WRITE
        "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        "list(APPEND CMAKE_MODULE_PATH \"\${CMAKE_CURRENT_LIST_DIR}\")\nlist(APPEND CMAKE_PREFIX_PATH \"\${CMAKE_CURRENT_LIST_DIR}\")")

    write_basic_package_version_file(
        ${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
        VERSION ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}
        COMPATIBILITY SameMajorVersion)


    install (FILES "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
                   "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
             DESTINATION "${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}/cmake")
endfunction(ccws_conan_install)
