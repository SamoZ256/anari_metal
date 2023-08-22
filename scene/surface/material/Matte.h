#pragma once

#include "Material.h"

namespace anari_mtl {

class Matte : public Material {
public:
    Matte(AnariMetalGlobalState* s) : Material(s) {}

    void commit() override;

    void uploadToShader(id encoder) override;

private:
    float opacity;
    struct {
        float4 color;
        float metallic;
        float roughness;
    } uniforms;

    Sampler* colorSampler = nullptr;
};

} //namespace anari_mtl
