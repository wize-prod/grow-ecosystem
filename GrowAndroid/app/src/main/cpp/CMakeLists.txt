cmake_minimum_required(VERSION 3.22.1)

project("growcore_jni")

# Include Shared Core C++ Engine from Shared/GrowCore
set(GROW_CORE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../../Shared/GrowCore/Sources/GrowCoreCPP")

include_directories(
    ${GROW_CORE_DIR}/include
)

add_library(
    growcore_jni
    SHARED
    native-bridge.cpp
    ${GROW_CORE_DIR}/GrowCoreEngine.cpp
)

find_library(
    log-lib
    log
)

target_link_libraries(
    growcore_jni
    ${log-lib}
)
