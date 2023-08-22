// Copyright 2022 The Khronos Group
// SPDX-License-Identifier: Apache-2.0

#pragma once

// ANARI-SDK
#ifdef __cplusplus
#include <anari/anari_cpp.hpp>
#else
#include <anari/anari.h>
#endif

//Anari metal
#include "anari_library_anari_metal_export.h"

#ifdef __cplusplus
extern "C" {
#endif

ANARI_METAL_DEVICE_INTERFACE ANARIDevice anariNewAnariMetalDevice(
    ANARIStatusCallback defaultCallback ANARI_DEFAULT_VAL(0),
    const void *userPtr ANARI_DEFAULT_VAL(0));

#ifdef __cplusplus
} // extern "C"
#endif
