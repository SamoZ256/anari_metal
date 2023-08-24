#pragma once

#include "Object.h"

namespace anari_mtl {

struct PipelineState {
    id mainVertexFunction;
    id mainFragmentFunction;
    id pipelineState;
};

//TODO: include data type
struct ConstantValue {
    void* data;
    uint8_t index;
};

/*
 * RULES:
 * 1. Material must always be at buffer index 2
 */

class Pipeline {
public:
    Pipeline(id aDevice, const char* shaderSource);

    ~Pipeline();

    void bind(id encoder, const PipelineConfig& config, id colorAttachment, id depthAttachment, id albedoMetallicTexture, id normalRoughnessTexture);

    void unbind() {
        isBound = false;
    }

protected:
    id device;
    id mainLibrary;
    void* mtlVertexDescriptor;
    PipelineState* renderPipelineStates[PIPELINE_CONFIG_COUNT] = {nullptr};

    bool isBound = false;
    PIPELINE_HASH_T boundHash;

    id createFunction(const std::string& name, const std::vector<ConstantValue>& constantValue);

    virtual void createPipeline(PipelineState* renderPipelineState, const PipelineConfig& config, id colorAttachment, id depthAttachment, id albedoMetallicTexture, id normalRoughnessTexture) = 0;
};

} //namespace anari_mtl
