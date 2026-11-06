set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_NAME "qumir-service")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_CONTACT "Alexey Ozeritskiy <aozeritsky@gmail.com>")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://qumir.dev")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Qumir playground web service")
set(CPACK_STRIP_FILES ON)

set(CPACK_DEB_COMPONENT_INSTALL ON)
set(CPACK_DEBIAN_FILE_NAME "DEB-DEFAULT")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
# Yields 1.1.0-42; the hyphen is the Debian revision separator.
set(CPACK_DEBIAN_PACKAGE_RELEASE "${QUMIR_SERVICE_BUILD_NUMBER}")

set(CPACK_COMPONENTS_ALL service)

set(CPACK_DEBIAN_SERVICE_PACKAGE_NAME "qumir-service")
set(CPACK_DEBIAN_SERVICE_PACKAGE_SECTION "web")
# qumirc and the JS runtime (share/qumir/js) come from the qumir package; qumir 1.1.0 is
# the first release without its own copy of the service.
set(CPACK_DEBIAN_SERVICE_PACKAGE_DEPENDS "qumir (>= 1.1.0), adduser")
# Creates the qumir system account the unit runs as.
set(CPACK_DEBIAN_SERVICE_PACKAGE_CONTROL_EXTRA "${CMAKE_SOURCE_DIR}/service/postinst")
set(CPACK_COMPONENT_SERVICE_DESCRIPTION
    "Qumir playground web service.\n HTTP server backing the browser playground: editor, examples\n and the robot/turtle executors.")

include(CPack)
