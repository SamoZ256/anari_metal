cmake_minimum_required(VERSION 3.11)

if (${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_LIST_DIR})
  set(STANDALONE_SOURCE_TREE TRUE)
else()
  set(STANDALONE_SOURCE_TREE FALSE)
endif()

if (STANDALONE_SOURCE_TREE)
  message(STATUS "CMake version: ${CMAKE_VERSION}")
endif()

## Language setup ##

set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_BUILD_TYPE_INIT Release)

set(CMAKE_INSTALL_RPATH "$ORIGIN")
set(CMAKE_INSTALL_MESSAGE LAZY)

## Establish project ##

project(anari_library_anari_metal LANGUAGES CXX)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

include(GNUInstallDirs)

## Dependencies ##

find_package(anari REQUIRED)

## Code generation ##

anari_generate_queries(
  NAME anari-metal
  PREFIX AnariMetalDevice
  CPP_NAMESPACE anari_mtl
  JSON_DEFINITIONS_FILE ${CMAKE_CURRENT_SOURCE_DIR}/anari_metal_device.json
)

## Core device target ##

add_library(anari_library_anari_metal SHARED
  AnariMetalDevice.mm
  AnariMetalDeviceQueries.cpp
  AnariMetalGlobalState.mm
  AnariMetalLibrary.cpp
  Object.cpp
  metal_helper/MetalHelper.mm
  camera/Camera.cpp
  camera/PerspectiveCamera.cpp
  array/Array.cpp
  scene/World.cpp
  scene/Instance.cpp
  scene/Group.cpp
  scene/surface/Surface.cpp
  scene/surface/geometry/Geometry.mm
  scene/surface/geometry/TriangleGeometry.mm
  scene/surface/material/Material.mm
  scene/surface/material/Matte.mm
  scene/surface/material/PBM.mm
  scene/surface/material/sampler/Sampler.mm
  scene/surface/material/sampler/ImageSampler.mm
  scene/light/Light.mm
  scene/light/DirectionalLight.mm
  scene/volume/Volume.cpp
  scene/volume/spatial_field/SpatialField.cpp
  frame/Frame.mm
  renderer/Renderer.mm
  renderer/DefaultRenderer.mm
  renderer/Pipeline.mm
  renderer/ForwardPipeline.mm
)

include(GenerateExportHeader)
generate_export_header(${PROJECT_NAME}
  EXPORT_MACRO_NAME "ANARI_METAL_DEVICE_INTERFACE"
)

target_include_directories(anari_library_anari_metal PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
)

#TODO: use find_library for frameworks
target_link_libraries(anari_library_anari_metal PUBLIC anari::helium PRIVATE "-framework Foundation -framework QuartzCore -framework Metal")

## Installation ##

install(TARGETS ${PROJECT_NAME}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(
FILES
  ${PROJECT_BINARY_DIR}/${PROJECT_NAME}_export.h
  ${CMAKE_CURRENT_LIST_DIR}/include/anari/ext/anari_metal/anariNewAnariMetalDevice.h
DESTINATION
  ${CMAKE_INSTALL_INCLUDEDIR}/anari/ext/anari_metal
)
