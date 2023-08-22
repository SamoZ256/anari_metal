#include "World.h"

namespace anari_mtl {

World::World(AnariMetalGlobalState* s) : Object(ANARI_WORLD, s) {
    s->objectCounts.worlds++;

    //TODO: initialize
}

World::~World() {
    //TODO: do cleanup
    deviceState()->objectCounts.worlds--;
}

bool World::getProperty(const std::string_view &name, ANARIDataType type, void *ptr, uint32_t flags) {
    if (name == "bounds" && type == ANARI_FLOAT32_BOX3) {
        if (flags & ANARI_WAIT) {
            deviceState()->waitOnCurrentFrame();
            deviceState()->commitBuffer.flush();
        }
        memcpy(ptr, &bounds, sizeof(bounds));
        
        return true;
    }

  return Object::getProperty(name, type, ptr, flags);
}

void World::commit() {
    instances = getParamObject<Array>("instance");
    surfaces = getParamObject<Array>("surface");
    lights = getParamObject<Array>("light");

    //Get the bounds
    if (instances) {
        for (uint32_t i = 0; i < instances->getElementCount(); i++) {
            Bounds crntBounds = instances->getObjectAtIndex(i)->getBounds(identity);
            bounds.min = min(bounds.min, crntBounds.min);
            bounds.max = max(bounds.max, crntBounds.max);
        }
    }
    if (surfaces) {
        for (uint32_t i = 0; i < surfaces->getElementCount(); i++) {
            Bounds crntBounds = surfaces->getObjectAtIndex(i)->getBounds(identity);
            bounds.min = min(bounds.min, crntBounds.min);
            bounds.max = max(bounds.max, crntBounds.max);
        }
    }
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::World*);
