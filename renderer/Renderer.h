#pragma once

#include "../scene/World.h"
#include "../camera/Camera.h"

namespace anari_mtl {

class Renderer : public Object {
public:
    Renderer(AnariMetalGlobalState* s);

    ~Renderer() override;

    static Renderer* createInstance(std::string_view type, AnariMetalGlobalState* s);

    void commit() override;

    virtual void renderFrame(World* world, Camera* camera, id colorTexture = nullptr, id depthTexture = nullptr) = 0;

    bool ready();

    void wait();

protected:
    float4 clearColor; //TODO: make a union from this to support other types
    id commandBuffer = nullptr;

    void cleanup();
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Renderer*, ANARI_RENDERER);
