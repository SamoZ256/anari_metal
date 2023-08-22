#pragma once

#include "Light.h"

namespace anari_mtl {

class DirectionalLight : public Light {
public:
    DirectionalLight(AnariMetalGlobalState* s) : Light(s) {}

    void commit() override;

    void uploadToShader(id encoder) override;

private:
    struct {
        float3 color;
        float3 direction;
    } uniforms;
};

} //namespace anari_mtl
