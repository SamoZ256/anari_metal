#pragma once

#include "Sampler.h"

#include "../../../../array/Array.h"

namespace anari_mtl {

enum class ImageType {
    _1D,
    _2D,
    _3D
};

class ImageSampler : public Sampler {
public:
    ImageSampler(AnariMetalGlobalState* s, ImageType aImageType) : Sampler(s), imageType(aImageType) {}

    ~ImageSampler() override;

    void commit() override;

    void bindToShader(id encoder, uint8_t index) override;

    void initMTLTexture();

private:
    ImageType imageType;
    id mtlTexture = nullptr;

    Array* array;
};

} //namespace anari_mtl
