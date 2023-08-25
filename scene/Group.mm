#include "Group.h"

#include "surface/Surface.h"

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

void* Group::buildAccelerationStructures() {
    if (!builtAccelerationStructure) {
        mtlAccelerationStructures = [[NSMutableArray alloc] init];
        if (handles) {
            for (uint32_t i = 0; i < handles->getElementCount(); i++) {
                Object* object = handles->getObjectAtIndex(i);
                if (object->type() != ANARI_SURFACE) {
                    reportMessage(ANARI_SEVERITY_WARNING, "cannot build acceleration structure for non-surface object");
                    break;
                }

                //TODO: make this a virtual function
                [(NSMutableArray*)mtlAccelerationStructures addObject:((Surface*)object)->buildAccelerationStructure()];
            }
        }

        builtAccelerationStructure = true;
    }

    return mtlAccelerationStructures;
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::Group*);
