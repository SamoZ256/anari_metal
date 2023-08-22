#pragma once

#include "Material.h"

namespace anari_mtl {

class PBM : public Material {
public:
    PBM(AnariMetalGlobalState* s) : Material(s) {}

    void commit() override;

    void uploadToShader(id encoder) override;

private:
    float opacity;
    struct {
        float4 albedo;
        float metallic;
        float roughness;
    } uniforms;

    Sampler* albedoSampler = nullptr;
};

} //namespace anari_mtl
