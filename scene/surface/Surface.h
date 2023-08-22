#pragma once

#include "geometry/Geometry.h"
#include "material/Material.h"

namespace anari_mtl {

class Surface : public Object {
private:
    Geometry* geometry;
    Material* material;

public:
    Surface(AnariMetalGlobalState* s);

    ~Surface() override;

    void commit() override;

    void render(id encoder, const float4x4& modelMatrix) override;

    void getRenderables(std::vector<Renderable>& renderables, const float4x4& parentModelMatrix) override;

    Bounds getBounds(const float4x4& parentModelMatrix) override;
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Surface*, ANARI_SURFACE);
