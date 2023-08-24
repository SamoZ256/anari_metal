#pragma once

#include "Pipeline.h"

namespace anari_mtl {

class HybridPipeline : public Pipeline {
public:
    HybridPipeline(id aDevice);

private:
    void createPipeline(PipelineState* renderPipelineState, const PipelineConfig& config, id colorAttachment, id depthAttachment, id albedoMetallicTexture, id normalRoughnessTexture) override;
};

} //namespace anari_mtl
