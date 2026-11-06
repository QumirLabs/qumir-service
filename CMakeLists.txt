cmake_minimum_required(VERSION 3.30)
project(qumir-service VERSION 1.1.0)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(QUMIR_USE_CCACHE "Compile through ccache when it is installed" ON)
option(QUMIR_LLVM_LINK_SHARED "Link the shared libLLVM instead of static LLVM archives" OFF)
set(QUMIR_SERVICE_BUILD_NUMBER "0" CACHE STRING "Build number, becomes the Debian revision after the hyphen")
set(QUMIR_DATA_DIR "/var/lib/qumir-data" CACHE STRING "Writable data directory, created by postinst (which hardcodes the default)")

# Build number 0 means a working copy; anything else comes from CI and names a package.
string(TIMESTAMP QUMIR_SERVICE_BUILD_DATE "%Y-%m-%d" UTC)
if(QUMIR_SERVICE_BUILD_NUMBER STREQUAL "0")
    set(QUMIR_SERVICE_VERSION_STRING "dev,${QUMIR_SERVICE_BUILD_DATE}")
else()
    execute_process(
        COMMAND git rev-parse --short=7 HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE QUMIR_SERVICE_GIT_SHA
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET)
    if(QUMIR_SERVICE_GIT_SHA)
        set(QUMIR_SERVICE_VERSION_STRING "${PROJECT_VERSION}-${QUMIR_SERVICE_BUILD_NUMBER},${QUMIR_SERVICE_GIT_SHA},${QUMIR_SERVICE_BUILD_DATE}")
    else()
        set(QUMIR_SERVICE_VERSION_STRING "${PROJECT_VERSION}-${QUMIR_SERVICE_BUILD_NUMBER},${QUMIR_SERVICE_BUILD_DATE}")
    endif()
endif()
message(STATUS "Qumir service version string: ${QUMIR_SERVICE_VERSION_STRING}")

# Set before any target exists; the submodules under externals/ inherit it.
# A launcher passed on the command line (CI does) takes precedence.
if(QUMIR_USE_CCACHE AND NOT CMAKE_C_COMPILER_LAUNCHER AND NOT CMAKE_CXX_COMPILER_LAUNCHER)
    find_program(CCACHE_PROGRAM ccache)
    if(CCACHE_PROGRAM)
        set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE_PROGRAM})
        set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_PROGRAM})
        message(STATUS "ccache: using ${CCACHE_PROGRAM}")
    else()
        message(STATUS "ccache: not found, compiling directly")
    endif()
elseif(CMAKE_C_COMPILER_LAUNCHER OR CMAKE_CXX_COMPILER_LAUNCHER)
    message(STATUS "ccache: compiler launcher already set (C: '${CMAKE_C_COMPILER_LAUNCHER}', C++: '${CMAKE_CXX_COMPILER_LAUNCHER}')")
else()
    message(STATUS "ccache: disabled")
endif()

if(NOT EXISTS "${CMAKE_SOURCE_DIR}/externals/coroio/CMakeLists.txt")
    message(FATAL_ERROR "Submodule externals/coroio is not checked out: run git submodule update --init --recursive")
endif()

add_subdirectory(externals)
add_subdirectory(service)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    include(cmake/Packaging.cmake)
endif()
