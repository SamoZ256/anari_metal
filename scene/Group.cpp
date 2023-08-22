#include "Group.h"

namespace anari_mtl {

Group::Group(AnariMetalGlobalState* s) : Object(ANARI_GROUP, s) {
    s->objectCounts.groups++;
}

Group::~Group() {
    deviceState()->objectCounts.groups--;
}

void Group::commit() {
    if (Array* surfaces = getParamObject<Array>("surface"))
        handles = surfaces;
    else if (Array* volumes = getParamObject<Array>("volume"))
        handles = volumes;
    else if (Array* lights = getParamObject<Array>("light"))
        handles = lights;
}

void Group::getRenderables(std::vector<Renderable>& renderables, const float4x4& parentModelMatrix) {
    if (handles) {
        for (uint32_t i = 0; i < handles->getElementCount(); i++) {
            Object* object = handles->getObjectAtIndex(i);
            object->getRenderables(renderables, parentModelMatrix);
        }
    }
}

Bounds Group::getBounds(const float4x4& parentModelMatrix) {
    Bounds bounds;
    if (handles) {
        for (uint32_t i = 0; i < handles->getElementCount(); i++) {
            Object* object = handles->getObjectAtIndex(i);
            Bounds crntBounds = object->getBounds(parentModelMatrix);
            bounds.min = min(bounds.min, crntBounds.min);
            bounds.max = max(bounds.max, crntBounds.max);
        }
    }

    return bounds;
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::Group*);
