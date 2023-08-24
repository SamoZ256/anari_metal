#pragma once

#include "Renderer.h"
#include "HybridPipeline.h"

namespace anari_mtl {

class HybridRenderer : public Renderer {
public:
    HybridRenderer(AnariMetalGlobalState* s) : Renderer(s) {}

    ~HybridRenderer() override;

    void commit() override;

    void renderFrame(World* world, Camera* camera, id colorTexture = nullptr, id depthTexture = nullptr) override;

private:
    id albedoMetallicTexture = nullptr;
    id normalRoughnessTexture = nullptr;

    HybridPipeline* pipeline = nullptr;
    id gbufferDepthStencilState = nullptr;
    id deferredDepthStencilState = nullptr;
};

} //namespace anari_mtl
