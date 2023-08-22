#pragma once

#include "array/Array.h"

namespace anari_mtl {

class Group : public Object {
public:
    Group(AnariMetalGlobalState* s);

    ~Group() override;

    void commit() override;

    void getRenderables(std::vector<Renderable>& renderables, const float4x4& parentModelMatrix) override;

    Bounds getBounds(const float4x4& parentModelMatrix) override;

private:
    Array* handles = nullptr;
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Group*, ANARI_GROUP);
