// Copyright 2023 The Khronos Group
// SPDX-License-Identifier: Apache-2.0

#include "AnariMetalDevice.h"
#include "anari/backend/LibraryImpl.h"
#include "anari_library_anari_metal_export.h"

namespace anari_mtl {

const char **query_extensions();

struct AnariMetalLibrary : public anari::LibraryImpl
{
  AnariMetalLibrary(void *lib, ANARIStatusCallback defaultStatusCB, const void *statusCBPtr);

  ANARIDevice newDevice(const char *subtype) override;
  const char **getDeviceExtensions(const char *deviceType) override;
};

// Definitions ////////////////////////////////////////////////////////////////

AnariMetalLibrary::AnariMetalLibrary(
    void *lib, ANARIStatusCallback defaultStatusCB, const void *statusCBPtr)
    : anari::LibraryImpl(lib, defaultStatusCB, statusCBPtr)
{}

ANARIDevice AnariMetalLibrary::newDevice(const char * /*subtype*/)
{
  return (ANARIDevice) new AnariMetalDevice(this_library());
}

const char **AnariMetalLibrary::getDeviceExtensions(const char * /*deviceType*/)
{
  return query_extensions();
}

} //namespace anari_mtl

// Define library entrypoint //////////////////////////////////////////////////

extern "C" ANARI_METAL_DEVICE_INTERFACE ANARI_DEFINE_LIBRARY_ENTRYPOINT(
    anari_metal, handle, scb, scbPtr)
{
  return (ANARILibrary) new anari_mtl::AnariMetalLibrary(handle, scb, scbPtr);
}

extern "C" ANARI_METAL_DEVICE_INTERFACE ANARIDevice anariNewAnariMetalDevice(
    ANARIStatusCallback defaultCallback, const void *userPtr)
{
  return (ANARIDevice) new anari_mtl::AnariMetalDevice(defaultCallback, userPtr);
}
