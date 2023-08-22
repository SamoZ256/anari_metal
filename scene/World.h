#pragma once

#include "Instance.h"
#include "light/Light.h"
#include "surface/Surface.h"
#include "volume/Volume.h"

namespace anari_mtl {

class World : public Object {
public:
    World(AnariMetalGlobalState* s);

    ~World() override;

    bool getProperty(const std::string_view &name, ANARIDataType type, void *ptr, uint32_t flags) override;

    void commit() override;

    Array* getInstances() {
        return instances;
    }

    Array* getSurfaces() {
        return surfaces;
    }

    Array* getLights() {
        return lights;
    }

private:
    Array* instances = nullptr;
    Array* surfaces = nullptr;
    Array* lights = nullptr;
    
    Bounds bounds;
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::World*, ANARI_WORLD);
