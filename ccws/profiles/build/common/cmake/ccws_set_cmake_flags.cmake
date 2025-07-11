if (CCWS_CLANG_TIDY)
    set (CMAKE_CXX_CLANG_TIDY "${CCWS_CLANG_TIDY}")
endif()

if (CCWS_CXX_FLAGS)
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CCWS_CXX_FLAGS}")
    set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CCWS_LINKER_FLAGS}")
endif()

# duplicates CMAKE_CXX_FLAGS, which should be gradually deprecated
set(CMAKE_CXX_STANDARD "$ENV{CCWS_CXX_STANDARD}")
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_definitions(-DCCWS_DEBUG=${CCWS_DEBUG})

message("CCWS compilation flags set.")
