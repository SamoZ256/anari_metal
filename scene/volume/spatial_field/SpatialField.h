#pragma once

#include "../../../Object.h"

namespace anari_mtl {

class SpatialField : public Object {
public:
    SpatialField(AnariMetalGlobalState* s);

    ~SpatialField() override;

    static SpatialField* createInstance(std::string_view type, AnariMetalGlobalState* s);

    void commit() override;

protected:
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::SpatialField*, ANARI_SPATIAL_FIELD);
