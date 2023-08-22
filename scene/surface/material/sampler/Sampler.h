#pragma once

#include "../../../../Object.h"

namespace anari_mtl {

enum Filter {
    Nearest,
    Linear
};

enum AddressMode {
    ClampToEdge,
    Repeat,
    MirrorRepeat,
    Default
};

class Sampler : public Object {
public:
    Sampler(AnariMetalGlobalState* s);

    ~Sampler() override;

    static Sampler* createInstance(std::string_view type, AnariMetalGlobalState* s);

    void commit() override;

    virtual void bindToShader(id encoder, uint8_t index);

    void initMTLSamplerState();

protected:
    Filter filter;
    AddressMode addressModeS;
    AddressMode addressModeT;
    AddressMode addressModeU;

    id mtlSamplerState = nullptr;
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Sampler*, ANARI_SAMPLER);
