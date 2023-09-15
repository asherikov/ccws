function(ccws_vcpkg_install)
    set(PACKAGES ${ARGN})
    set(VCPKG_TRIPLET x64-linux-release)

    message("CCWS: Using vcpkg to install ${PACKAGES}")

    if(IS_DIRECTORY "${PROJECT_SOURCE_DIR}/vcpkg_overlays/")
        set(OVERLAY --overlay-ports=${PROJECT_SOURCE_DIR}/vcpkg_overlays/)
    endif()

    add_custom_target(
        ccws_vcpkg_install_${PROJECT_NAME} ALL
        COMMAND ${CMAKE_COMMAND} -E echo "CCWS: installing dependencies using vcpkg"
        COMMAND ${CMAKE_COMMAND} -E env --unset=MAKELEVEL --unset=MAKEFLAGS --unset=MFLAGS "$ENV{CCWS_VCPKG_ROOT}/vcpkg" install
            --x-install-root=${CMAKE_INSTALL_PREFIX}
            --triplet=${VCPKG_TRIPLET}
            ${OVERLAY}
            ${PACKAGES}
    )


    include(CMakePackageConfigHelpers)
    file(WRITE
        "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        "list(APPEND CMAKE_MODULE_PATH \"\${CMAKE_CURRENT_LIST_DIR}\")\nlist(APPEND CMAKE_PREFIX_PATH \"\${CMAKE_INSTALL_PREFIX}/${VCPKG_TRIPLET}\")")

    write_basic_package_version_file(
        ${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
        VERSION ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}
        COMPATIBILITY SameMajorVersion)


    install (FILES "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
                   "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
             DESTINATION "${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}/cmake")
endfunction(ccws_vcpkg_install)
