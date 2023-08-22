#include "SpatialField.h"

namespace anari_mtl {

SpatialField::SpatialField(AnariMetalGlobalState* s) : Object(ANARI_VOLUME, s) {
    s->objectCounts.spatialFields++;
}

SpatialField::~SpatialField() {
    deviceState()->objectCounts.spatialFields--;
}

SpatialField* SpatialField::createInstance(std::string_view type, AnariMetalGlobalState* s) {
    return (SpatialField*)new UnknownObject(ANARI_SPATIAL_FIELD, s);
}

void SpatialField::commit() {
    //TODO
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::SpatialField*);
