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

private:
    ForwardPipeline* pipeline = nullptr;
    id mainDepthStencilState = nullptr;
};

} //namespace anari_mtl
