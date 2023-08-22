#pragma once

#include "spatial_field/SpatialField.h"

namespace anari_mtl {

class Volume : public Object {
public:
    Volume(AnariMetalGlobalState* s);

    ~Volume() override;

    static Volume* createInstance(std::string_view type, AnariMetalGlobalState* s);

    void commit() override;

protected:
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Volume*, ANARI_VOLUME);
