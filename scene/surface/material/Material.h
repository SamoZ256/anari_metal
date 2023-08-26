#pragma once

#include "sampler/Sampler.h"

namespace anari_mtl {

enum class AlphaMode {
    Opaque,
    Mask,
    Blend
};

class Material : public Object {
public:
    Material(AnariMetalGlobalState* s);

    ~Material() override;

    static Material* createInstance(std::string_view type, AnariMetalGlobalState* s);

    void commit() override;

    virtual void uploadToShader(id encoder);

    virtual const float4& getColor() = 0;

    virtual id getColorTexture() = 0;

protected:
    AlphaMode alphaMode;
    float alphaCutoff;
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Material*, ANARI_MATERIAL);
