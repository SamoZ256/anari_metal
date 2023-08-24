#pragma once

#include "Pipeline.h"

namespace anari_mtl {

class ForwardPipeline : public Pipeline {
public:
    ForwardPipeline(id aDevice);

private:
    void createPipeline(PipelineState* renderPipelineState, const PipelineConfig& config, id colorAttachment, id depthAttachment) override;
};

} //namespace anari_mtl
