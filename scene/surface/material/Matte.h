#pragma once

#include "Material.h"

namespace anari_mtl {

class Matte : public Material {
public:
    Matte(AnariMetalGlobalState* s) : Material(s) {}

    void commit() override;

    void uploadToShader(id encoder) override;

    const float4& getColor() override {
        return uniforms.color;
    }

    id getColorTexture() override {
        return (colorSampler ? colorSampler->getColorTexture() : nullptr);
    }

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
