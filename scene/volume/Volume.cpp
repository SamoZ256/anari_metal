#include "Volume.h"

namespace anari_mtl {

Volume::Volume(AnariMetalGlobalState* s) : Object(ANARI_VOLUME, s) {
    s->objectCounts.volumes++;
}

Volume::~Volume() {
    deviceState()->objectCounts.volumes--;
}

Volume* Volume::createInstance(std::string_view type, AnariMetalGlobalState* s) {
    return (Volume*)new UnknownObject(ANARI_VOLUME, s);
}

void Volume::commit() {
    //TODO
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::Volume*);
