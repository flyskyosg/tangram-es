
# set for test in other cmake files
set(PLATFORM_TIZEN ON)

# use freetype2/icu/harfbuzz system libs for alfons
set(USE_SYSTEM_FONT_LIBS ON)

# Tell SQLiteCpp to not build its own copy of SQLite, we will use the system library instead.
set(SQLITECPP_INTERNAL_SQLITE OFF)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -fPIC")

# global compile options
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -std=c++1y -fPIC")
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-omit-frame-pointer")

if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-gnu-zero-variadic-macro-arguments")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
endif()

if (CMAKE_COMPILER_IS_GNUCC)
  execute_process(COMMAND ${CMAKE_CXX_COMPILER} -dumpversion
    OUTPUT_VARIABLE GCC_VERSION)
  string(REGEX MATCHALL "[0-9]+" GCC_VERSION_COMPONENTS ${GCC_VERSION})
  list(GET GCC_VERSION_COMPONENTS 0 GCC_MAJOR)
  list(GET GCC_VERSION_COMPONENTS 1 GCC_MINOR)

  message(STATUS "Using gcc ${GCC_VERSION}")
  if (GCC_VERSION VERSION_GREATER 5.1)
    message(STATUS "USE CXX11_ABI")
    add_definitions("-D_GLIBCXX_USE_CXX11_ABI=1")
  endif()
endif()

check_unsupported_compiler_version()

# compile definitions (adds -DPLATFORM_LINUX)
set(CORE_COMPILE_DEFS PLATFORM_TIZEN PLATFORM_LINUX)

# load core library
add_subdirectory(${PROJECT_SOURCE_DIR}/core)

set(LIB_NAME tangram) # in order to have libtangram.so

add_library(${LIB_NAME} SHARED
  ${PROJECT_SOURCE_DIR}/platforms/tizen/src/platform_tizen.cpp
  ${PROJECT_SOURCE_DIR}/platforms/tizen/src/tizen_gl.cpp
  ${PROJECT_SOURCE_DIR}/platforms/common/urlClient.cpp)

include(FindPkgConfig)
pkg_check_modules(EVAS REQUIRED "evas")
pkg_check_modules(DLOG REQUIRED "dlog")
pkg_check_modules(FONTCONFIG REQUIRED "fontconfig")
pkg_check_modules(SQLITE REQUIRED "sqlite3")

# link to the core library, forcing all symbols to be added
# (whole-archive must be turned off after core so that lc++ symbols aren't duplicated)
target_link_libraries(${LIB_NAME}
  PUBLIC
  "-Wl,-whole-archive"
  ${CORE_LIBRARY}
  "-Wl,-no-whole-archive"
  PRIVATE
  ${EVAS_LDFLAGS}
  ${DLOG_LDFLAGS}
  ${SQLITE_LDFLAGS}
  ${FONTCONFIG_LDFLAGS})

target_include_directories(${LIB_NAME}
  PRIVATE
  ${PROJECT_SOURCE_DIR}/platforms/common
  ${EVAS_INCLUDE_DIRS}
  ${DLOG_INCLUDE_DIRS}
  ${SQLITE_INCLUDE_DIRS}
  ${FONTCONFIG_INCLUDE_DIRS})

target_compile_options(${LIB_NAME}
  PUBLIC
  -fPIC
  -Wl,-z,defs)


if (${ARCH} MATCHES "x86_64" OR ${ARCH} MATCHES "aarch64")
install(TARGETS ${LIB_NAME} DESTINATION lib64)
else ()
install(TARGETS ${LIB_NAME} DESTINATION lib)
endif()
