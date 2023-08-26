#pragma once

#include "Pipeline.h"

namespace anari_mtl {

class HybridPipeline : public Pipeline {
public:
    HybridPipeline(id aDevice);

    ~HybridPipeline() override;

    void bindDeferred(id encoder, id colorAttachment, id depthAttachment, id albedoMetallicAttachment, id normalRoughnessAttachment, id depthAsColorAttachment);

private:
    id deferredLibrary;
    PipelineState* deferredPipelineState = nullptr;

    void createPipeline(PipelineState* renderPipelineState, const PipelineConfig& config, id colorAttachment, id depthAttachment, id albedoMetallicAttachment, id normalRoughnessAttachment, id depthAsColorAttachment) override;
};

} //namespace anari_mtl
