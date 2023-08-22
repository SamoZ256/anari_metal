// Copyright 2023 The Khronos Group
// SPDX-License-Identifier: Apache-2.0

#include "AnariMetalGlobalState.h"
//#include "frame/Frame.h"

namespace anari_mtl {

AnariMetalGlobalState::AnariMetalGlobalState(ANARIDevice d)
    : helium::BaseGlobalDeviceState(d)
{}

void AnariMetalGlobalState::waitOnCurrentFrame() const
{
    //if (currentFrame)
    //  currentFrame->wait();
}

} // namespace helide