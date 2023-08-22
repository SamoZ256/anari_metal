#pragma once

#include "Group.h"

namespace anari_mtl {

class Instance : public Object {
public:
    Instance(AnariMetalGlobalState* s);

    ~Instance() override;

    void commit() override;

    void getRenderables(std::vector<Renderable>& renderables, const float4x4& parentModelMatrix) override;

    Bounds getBounds(const float4x4& parentModelMatrix) override;

private:
    Group* group;
    float4x4 modelMatrix;
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Instance*, ANARI_INSTANCE);
