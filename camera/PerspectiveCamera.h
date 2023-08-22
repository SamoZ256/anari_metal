#pragma once

#include "Camera.h"

namespace anari_mtl {
    
class PerspectiveCamera : public Camera {
private:

public:
    PerspectiveCamera(AnariMetalGlobalState* s) : Camera(s) {}

    void commit() override;
};

} //namespace anari_mtl
