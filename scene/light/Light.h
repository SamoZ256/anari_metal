#pragma once

#include "../../Object.h"

namespace anari_mtl {

class Light : public Object {
public:
    Light(AnariMetalGlobalState* s);

    ~Light() override;

    static Light* createInstance(std::string_view type, AnariMetalGlobalState* s);

    void commit() override;

    virtual void uploadToShader(id encoder) = 0;

protected:
    float3 color;
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Light*, ANARI_LIGHT);
