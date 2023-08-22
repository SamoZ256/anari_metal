#pragma once

#include "Renderer.h"
#include "ForwardPipeline.h"

namespace anari_mtl {

class DefaultRenderer : public Renderer {
public:
    DefaultRenderer(AnariMetalGlobalState* s) : Renderer(s) {}

    ~DefaultRenderer() override;

    void commit() override;

    void renderFrame(World* world, Camera* camera, id colorTexture = nullptr, id depthTexture = nullptr) override;

    bool ready() override;

    void wait() override;

private:
    ForwardPipeline* pipeline = nullptr;
    id mainDepthStencilState = nullptr;
    id commandBuffer = nullptr;
};

} //namespace anari_mtl
